#!/usr/bin/env bash
# setup-otel-cluster.sh — Create and configure a kind cluster for OTel maturity evaluation.
#
# Usage:
#   ./scripts/setup-otel-cluster.sh <project-name>
#
# Example:
#   ./scripts/setup-otel-cluster.sh jaeger
#
# Prerequisites: kind, kubectl, helm, docker (running)

set -euo pipefail

# ── Arguments ────────────────────────────────────────────────────────────────

PROJECT_NAME="${1:?Error: project-name argument is required. Usage: $0 <project-name>}"

# ── Paths ────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/resources"
WORK_DIR="$REPO_ROOT/.otel-eval/$PROJECT_NAME"
CLUSTER_NAME="otel-eval-$PROJECT_NAME"
HOST_TELEMETRY_DIR="/tmp/otel-eval-$PROJECT_NAME"

# ── Helpers ───────────────────────────────────────────────────────────────────

log()  { echo "▶ $*"; }
ok()   { echo "✓ $*"; }
die()  { echo "✗ $*" >&2; exit 1; }

# ── Step 0: Prerequisites ─────────────────────────────────────────────────────

log "Checking prerequisites..."
missing=()
for tool in kind kubectl helm docker; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing required tools: ${missing[*]}"
fi
docker info &>/dev/null || die "Docker daemon is not running"
ok "All prerequisites met (kind, kubectl, helm, docker)"

# ── Step 1: Working directory ─────────────────────────────────────────────────

log "Creating working directory at $WORK_DIR ..."
mkdir -p \
    "$WORK_DIR/kind" \
    "$WORK_DIR/collector" \
    "$WORK_DIR/services/nodejs-app"
ok "Working directory created"

# ── Step 2: Kind cluster config ───────────────────────────────────────────────

log "Writing kind cluster config..."
sed "s/__PROJECT_NAME__/$PROJECT_NAME/g" \
    "$TEMPLATES_DIR/kind-cluster.yaml" \
    > "$WORK_DIR/kind/cluster.yaml"
ok "Kind config written to $WORK_DIR/kind/cluster.yaml"

# ── Step 3: Collector Helm values ─────────────────────────────────────────────

log "Writing OTel Collector Helm values..."
cp "$TEMPLATES_DIR/collector-values.yaml" "$WORK_DIR/collector/values.yaml"
ok "Collector values written to $WORK_DIR/collector/values.yaml"

# ── Step 4: Copy Node.js test backend ────────────────────────────────────────

log "Copying Node.js test backend..."
cp -r "$TEMPLATES_DIR/nodejs-app/." "$WORK_DIR/services/nodejs-app/"
ok "Node.js backend copied to $WORK_DIR/services/nodejs-app/"

# ── Step 5: Host telemetry output directory ───────────────────────────────────

log "Creating host telemetry output directory at $HOST_TELEMETRY_DIR ..."
mkdir -p "$HOST_TELEMETRY_DIR"
ok "Telemetry output directory created"

# ── Step 6: Create kind cluster ───────────────────────────────────────────────

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
    ok "Kind cluster '$CLUSTER_NAME' already exists — skipping creation"
else
    log "Creating kind cluster '$CLUSTER_NAME' ..."
    kind create cluster --config "$WORK_DIR/kind/cluster.yaml"
    ok "Kind cluster created"
fi

log "Waiting for cluster nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all \
    --context "kind-$CLUSTER_NAME" \
    --timeout=120s
ok "All nodes ready"

# ── Step 7: Build and load the Node.js test backend ──────────────────────────

log "Building Node.js test backend image..."
docker build -t otel-eval-backend:latest "$WORK_DIR/services/nodejs-app/"
ok "Image built: otel-eval-backend:latest"

log "Loading image into kind cluster..."
kind load docker-image otel-eval-backend:latest --name "$CLUSTER_NAME"
ok "Image loaded into kind cluster"

# ── Step 8: Install the OpenTelemetry Collector ───────────────────────────────

COLLECTOR_IMAGE="otel/opentelemetry-collector-contrib:0.150.1"

log "Pre-pulling OTel Collector image on host Docker..."
docker pull "$COLLECTOR_IMAGE"
ok "Image pulled: $COLLECTOR_IMAGE"

log "Loading collector image into kind cluster..."
kind load docker-image "$COLLECTOR_IMAGE" --name "$CLUSTER_NAME"
ok "Image loaded into kind cluster"

log "Adding OpenTelemetry Helm repo..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
helm repo update

log "Creating opentelemetry namespace..."
kubectl create namespace opentelemetry \
    --context "kind-$CLUSTER_NAME" \
    --dry-run=client -o yaml | kubectl apply --context "kind-$CLUSTER_NAME" -f -

log "Installing OTel Collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --kube-context "kind-$CLUSTER_NAME" \
    --namespace opentelemetry \
    -f "$WORK_DIR/collector/values.yaml" \
    --wait --timeout 5m
ok "OTel Collector installed"

# ── Step 9: Deploy the test backend ──────────────────────────────────────────

log "Deploying Node.js test backend..."
kubectl apply --context "kind-$CLUSTER_NAME" \
    -f "$WORK_DIR/services/nodejs-app/manifests/deployment.yaml"

log "Waiting for test backend to be ready..."
kubectl wait --for=condition=ready pod \
    -l app=otel-eval-backend \
    -n demo \
    --context "kind-$CLUSTER_NAME" \
    --timeout=120s
ok "Test backend is running"

# ── Step 10: Verify ───────────────────────────────────────────────────────────

log "Verifying cluster state..."
kubectl get pods -A --context "kind-$CLUSTER_NAME"
echo ""
log "OTel Collector logs (last 10 lines):"
kubectl logs -n opentelemetry \
    --context "kind-$CLUSTER_NAME" \
    -l app.kubernetes.io/instance=otel-collector \
    --tail=10 || true
echo ""
log "Telemetry output directory:"
ls -la "$HOST_TELEMETRY_DIR"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════════════════"
echo " Cluster ready for evaluation"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  Cluster:   $CLUSTER_NAME"
echo "  Context:   kind-$CLUSTER_NAME"
echo ""
echo "  Telemetry output (written after traffic is generated):"
echo "    Traces:  $HOST_TELEMETRY_DIR/traces.jsonl"
echo "    Metrics: $HOST_TELEMETRY_DIR/metrics.jsonl"
echo "    Logs:    $HOST_TELEMETRY_DIR/logs.jsonl"
echo ""
echo "  OTel Collector OTLP endpoints (in-cluster):"
echo "    gRPC: otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317"
echo "    HTTP: otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4318"
echo ""
echo "  Test backend:"
echo "    Service:   otel-eval-backend.demo.svc.cluster.local:3000"
echo "    Namespace: demo"
echo ""
echo "  Next: install the CNCF project and point its telemetry at the collector."
echo "  To tear down: kind delete cluster --name $CLUSTER_NAME"
echo ""

---
name: setup-otel-cluster
description: Set up a local kind Kubernetes cluster with an OpenTelemetry Collector for evaluating a CNCF project's telemetry. Creates a single-node cluster with file-based telemetry export for programmatic inspection. Use when starting an OpenTelemetry maturity evaluation of a CNCF project.
argument-hint: "<project-name>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - WebFetch
  - WebSearch
---

# Setup OpenTelemetry Evaluation Cluster

You set up local kind Kubernetes clusters for evaluating the OpenTelemetry support maturity of CNCF projects. The cluster uses file-based telemetry export so that traces, metrics, and logs can be inspected programmatically as JSON.

## Required argument

The user must provide a `<project-name>` (e.g., `traefik`, `kgateway`, `linkerd`). This name is used for:
- Kind cluster name: `otel-eval-<project-name>`
- Host telemetry output directory: `/tmp/otel-eval-<project-name>/`
- Working directory for configs: created in the current working directory under `.otel-eval/<project-name>/`

## Prerequisites

Before proceeding, verify these tools are installed:
- `kind` — Kubernetes in Docker
- `kubectl` — Kubernetes CLI
- `helm` — Helm package manager
- `docker` — Docker runtime (must be running)

If any are missing, tell the user what to install and stop.

## Setup steps

### Step 1: Create working directory

Create a local working directory `.otel-eval/<project-name>/` with this structure:

```
.otel-eval/<project-name>/
  kind/cluster.yaml
  collector/values.yaml
  services/nodejs-app/  (copied from templates)
```

### Step 2: Write the kind cluster config

Use the template from `templates/kind-cluster.yaml` in this skill's directory, replacing `__PROJECT_NAME__` with the actual project name.

The kind config uses a single control-plane node with an `extraMounts` that maps `/tmp/otel-eval-<project-name>` on the host to `/tmp/otel` inside the node. This is where the OTel Collector writes telemetry JSON files.

### Step 3: Write the collector Helm values

Use the template from `templates/collector-values.yaml` in this skill's directory. This configures:

- **Single deployment collector** (not a daemonset) — keeps it simple
- **Receivers**: OTLP (gRPC + HTTP) for projects that push telemetry, Prometheus for projects that expose scrape endpoints, k8s_cluster for cluster metrics, log collection from container stdout/stderr via filelog
- **Processors**: memory_limiter, k8sattributes (full pod metadata extraction), batch
- **Exporters**: `file/traces`, `file/metrics`, `file/logs` writing JSONL to `/tmp/otel/`, plus `debug` with detailed verbosity for stdout verification
- **Presets**: clusterMetrics, logsCollection, kubeletMetrics, kubernetesAttributes enabled

The Prometheus receiver starts with an empty `scrape_configs: []`. This will be configured later when installing the specific CNCF project (by the `install-cncf-project` skill or manually).

### Step 4: Create host output directory

```bash
mkdir -p /tmp/otel-eval-<project-name>
```

### Step 5: Create the kind cluster

```bash
kind create cluster --config .otel-eval/<project-name>/kind/cluster.yaml
```

Wait for the node to be ready:

```bash
kubectl wait --for=condition=Ready nodes --all --timeout=120s
```

### Step 6: Build and load the Node.js test backend

The test backend is a simple Express app with OpenTelemetry auto-instrumentation. It echoes back trace context headers, which makes it useful to verify context propagation through whatever CNCF project is under evaluation.

Copy the Node.js app from this skill's `templates/nodejs-app/` directory into `.otel-eval/<project-name>/services/nodejs-app/`.

Build and load:

```bash
docker build -t otel-eval-backend:latest .otel-eval/<project-name>/services/nodejs-app/
kind load docker-image otel-eval-backend:latest --name otel-eval-<project-name>
```

### Step 7: Install the OpenTelemetry Collector

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

kubectl create namespace opentelemetry --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f .otel-eval/<project-name>/collector/values.yaml \
    --wait --timeout 3m
```

### Step 8: Deploy the test backend

```bash
kubectl apply -f .otel-eval/<project-name>/services/nodejs-app/manifests/deployment.yaml
kubectl wait --for=condition=ready pod -l app=otel-eval-backend -n demo --timeout=120s
```

### Step 9: Verify

1. Check all pods are running:
   ```bash
   kubectl get pods -A
   ```

2. Check the collector is healthy:
   ```bash
   kubectl logs -n opentelemetry -l app.kubernetes.io/instance=otel-collector --tail=20
   ```

3. Verify the host output directory exists:
   ```bash
   ls -la /tmp/otel-eval-<project-name>/
   ```

## Output

When complete, print a summary:

```
Cluster: otel-eval-<project-name>
Context: kind-otel-eval-<project-name>

Telemetry output:
  Traces:  /tmp/otel-eval-<project-name>/traces.jsonl
  Metrics: /tmp/otel-eval-<project-name>/metrics.jsonl
  Logs:    /tmp/otel-eval-<project-name>/logs.jsonl

Collector OTLP endpoints (in-cluster):
  gRPC: otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317
  HTTP: otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4318

Test backend:
  Service: otel-eval-backend.demo.svc.cluster.local:3000
  Namespace: demo

Next: Install the CNCF project and configure its telemetry export to point at the collector.
```

## Cleanup

To tear down the evaluation environment:

```bash
kind delete cluster --name otel-eval-<project-name>
rm -rf /tmp/otel-eval-<project-name>
rm -rf .otel-eval/<project-name>
```

## Important notes

- The Prometheus receiver `scrape_configs` is empty by default. When installing a CNCF project that exposes Prometheus metrics, update the collector values and re-apply with `helm upgrade`.
- The collector writes JSONL (one JSON object per line). Each line is a full OTLP export batch containing resource spans/metrics/logs.
- The k8sattributes processor enriches telemetry with pod metadata. When evaluating a project's resource attributes, compare what the project emits natively (before enrichment) versus what appears after the processor. The `debug` exporter logs to stdout and shows pre-enrichment data.
- The test backend auto-instruments with `@opentelemetry/auto-instrumentations-node` so it produces its own spans, which helps verify trace context propagation through the project under evaluation.

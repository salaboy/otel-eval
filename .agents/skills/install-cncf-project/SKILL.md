---
name: install-cncf-project
description: Research, install, and configure a CNCF project in an OpenTelemetry evaluation cluster. Looks up official docs, installs via Helm or manifests, configures telemetry export (OTLP or Prometheus), and generates traffic for evaluation. Use after setup-otel-cluster.
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

# Install CNCF Project for OpenTelemetry Evaluation

You install and configure a CNCF project in an evaluation cluster created by the `setup-otel-cluster` skill. Your goal is to get the project running with all available telemetry flowing to the OpenTelemetry Collector, so it can be evaluated for OpenTelemetry maturity.

## Context

The evaluation cluster is already running with:
- Kind cluster: `otel-eval-<project-name>`
- OTel Collector in namespace `opentelemetry` with OTLP (gRPC :4317, HTTP :4318) and Prometheus receivers
- Test backend `otel-eval-backend` in namespace `demo`
- Telemetry written to `/tmp/otel-eval-<project-name>/` as JSONL files
- Working directory at `.otel-eval/<project-name>/`

## Required argument

The user provides the `<project-name>` — the CNCF project to install (e.g., `traefik`, `linkerd`, `dapr`, `keda`).

## Process

### Phase 1: Research the project

Before installing anything, research the project's observability capabilities. Use web search and the project's official documentation to answer:

1. **What is the project?** Brief description and its role in a Kubernetes cluster.
2. **How is it installed?** Helm chart, operator, manifests, CLI tool, etc.
3. **What telemetry does it produce?**
   - Traces: Does it emit spans? Via OTLP, Zipkin, Jaeger, or other protocols?
   - Metrics: Prometheus endpoints? OTLP metrics? Both?
   - Logs: Structured JSON? Plain text? OTLP log export?
4. **How is OpenTelemetry configured?** Custom resources, Helm values, environment variables, config files?
5. **Does it support context propagation?** W3C Trace Context, B3, other formats?
6. **Does it require special setup?** CRDs, sidecars, mesh injection, specific Kubernetes APIs (e.g., Gateway API)?

Save your research notes to `.otel-eval/<project-name>/RESEARCH.md` so they can be referenced during evaluation.

### Phase 2: Plan the installation

Based on research, create an installation plan. Document it in `.otel-eval/<project-name>/INSTALL-PLAN.md` with:

1. **Installation method** — Helm chart URL, version, namespace
2. **Telemetry configuration** — what needs to be set to enable OTel export
3. **Collector changes needed** — Prometheus scrape configs, additional receivers, etc.
4. **Routing/ingress setup** — how to route traffic through the project to the test backend
5. **Traffic generation** — how to send requests that exercise the project's telemetry

Present this plan to the user and ask for confirmation before proceeding.

### Phase 3: Install the project

Follow the installation plan:

#### Step 1: Install the project

Install using Helm or the project's recommended method. Use a dedicated namespace named after the project (e.g., `traefik`, `linkerd`, `dapr`).

Always pin to a specific version for reproducibility. Document the version in `INSTALL-PLAN.md`.

```bash
# Example for a Helm-based project:
helm repo add <repo-name> <repo-url>
helm repo update
kubectl create namespace <project-name> --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install <release-name> <chart> \
    --namespace <project-name> \
    -f .otel-eval/<project-name>/<project-name>/values.yaml \
    --wait --timeout 5m
```

Save all Helm values and manifests to `.otel-eval/<project-name>/<project-name>/`.

#### Step 2: Configure telemetry export

Based on research, configure the project to export telemetry:

**If the project supports OTLP export:**
Point it at the collector's in-cluster endpoints:
- gRPC: `otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317`
- HTTP: `otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4318`

**If the project only exposes Prometheus metrics:**
Update the collector's Prometheus scrape config. Edit `.otel-eval/<project-name>/collector/values.yaml` to add the project's scrape targets, then upgrade the Helm release:

```bash
helm upgrade otel-collector open-telemetry/opentelemetry-collector \
    --namespace opentelemetry \
    -f .otel-eval/<project-name>/collector/values.yaml \
    --wait
```

**If the project uses sidecar injection or mesh:**
Ensure the `demo` namespace is labeled for injection so the test backend gets instrumented by the project.

#### Step 3: Configure routing to test backend

Set up the necessary resources (Ingress, HTTPRoute, Gateway, VirtualService, etc.) so that traffic can flow through the project to the test backend.

Save all routing manifests to `.otel-eval/<project-name>/<project-name>/routing/`.

#### Step 4: Verify the project is running

```bash
kubectl get pods -n <project-namespace>
kubectl get pods -n demo
```

### Phase 4: Generate traffic and verify telemetry

#### Step 1: Determine access method

Depending on the project type:
- **Ingress/Gateway**: `kubectl port-forward` to the project's service, then `curl` through it
- **Service mesh**: Traffic between services in the mesh, triggered via the test backend
- **Other**: Project-specific access patterns

#### Step 2: Generate traffic

Send at least 10-20 requests to exercise the project. Include requests with and without trace context:

```bash
# Without trace context (project should start new traces)
curl -s http://localhost:<port>/ | jq .

# With trace context (project should propagate)
curl -s -H "traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01" \
    http://localhost:<port>/ | jq .
```

Vary request patterns to exercise different code paths if applicable (different routes, methods, error cases).

#### Step 3: Wait for telemetry to flush

```bash
sleep 10
```

#### Step 4: Verify telemetry files have data

```bash
echo "=== Traces ===" && wc -l /tmp/otel-eval-<project-name>/traces.jsonl 2>/dev/null || echo "No traces file"
echo "=== Metrics ===" && wc -l /tmp/otel-eval-<project-name>/metrics.jsonl 2>/dev/null || echo "No metrics file"
echo "=== Logs ===" && wc -l /tmp/otel-eval-<project-name>/logs.jsonl 2>/dev/null || echo "No logs file"
```

#### Step 5: Quick sanity check

Read the first few lines of each telemetry file to confirm data is flowing and looks reasonable:

```bash
head -1 /tmp/otel-eval-<project-name>/traces.jsonl | jq '.resourceSpans[0].resource' 2>/dev/null
head -1 /tmp/otel-eval-<project-name>/metrics.jsonl | jq '.resourceMetrics[0].resource' 2>/dev/null
head -1 /tmp/otel-eval-<project-name>/logs.jsonl | jq '.resourceLogs[0].resource' 2>/dev/null
```

### Phase 5: Document what was done

Update `.otel-eval/<project-name>/RESEARCH.md` with actual observations:
- What telemetry signals are actually flowing
- Any surprises or deviations from documentation
- Any configuration that was harder than expected

## Output

When complete, print a summary:

```
Project: <project-name>
Version: <version>
Namespace: <project-namespace>

Telemetry status:
  Traces:  [flowing/not flowing] — [OTLP/Zipkin/other]
  Metrics: [flowing/not flowing] — [OTLP/Prometheus scrape/other]
  Logs:    [flowing/not flowing] — [OTLP/stdout collected/other]

Access:
  <how to reach the project, e.g., port-forward command>

Telemetry files:
  /tmp/otel-eval-<project-name>/traces.jsonl
  /tmp/otel-eval-<project-name>/metrics.jsonl
  /tmp/otel-eval-<project-name>/logs.jsonl

Next: Run the evaluate-otel-maturity skill to assess the project's OpenTelemetry support.
```

## Important guidance

- **Always check official docs first.** Don't guess at configuration — look it up. OpenTelemetry configuration varies wildly between projects.
- **Don't over-configure the collector.** The goal is to capture what the project emits as-is. Avoid adding transforms, attribute processors, or parsing rules beyond what's needed for basic collection. The evaluation should reflect the project's native telemetry, not a heavily processed version.
- **Keep the k8sattributes processor.** It's needed to understand what the project emits natively vs what gets enriched. The debug exporter shows pre-processor data in collector logs.
- **If something doesn't work, document it.** A project's failure to emit telemetry or difficulty in configuration is itself a data point for the maturity evaluation.
- **Be explicit about what is project-native vs collector-derived.** This distinction is critical for the maturity evaluation. When you update RESEARCH.md, clearly note which telemetry characteristics come from the project itself and which come from collector processing.
- **Prometheus metrics are valid telemetry.** Many CNCF projects only expose Prometheus endpoints. This is expected and should be captured via the Prometheus receiver. The maturity evaluation will assess this as part of the Integration Surface and Multi-Signal dimensions.

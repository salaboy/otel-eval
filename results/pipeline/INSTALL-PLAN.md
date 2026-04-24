# Tekton Pipelines — Install Plan

## Installation Method

- **Method:** Raw Kubernetes manifests (official release YAML)
- **Version:** v1.11.1
- **Namespace:** `tekton-pipelines`
- **Manifest URL:** https://github.com/tektoncd/pipeline/releases/download/v1.11.1/release.yaml

## Telemetry Configuration

### Metrics
- Patch `config-observability` ConfigMap to use Prometheus (default is already prometheus)
- Add Prometheus scrape config to OTel Collector for:
  - `tekton-pipelines-controller` service on port 9090
  - `tekton-pipelines-events` service on port 9090
  - `tekton-pipelines-remote-resolvers` service on port 9090
  - `tekton-pipelines-webhook` service on port 9090

### Traces
- Patch `config-observability` ConfigMap:
  - `tracing-protocol: grpc`
  - `tracing-endpoint: otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317`
  - `tracing-sampling-rate: "1.0"`
- Also patch `config-tracing` ConfigMap:
  - `enabled: "true"`
  - `endpoint: http://otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4318/v1/traces`

### Logs
- No OTLP log export supported; logs go to stdout (collected by k8s log scraping if configured)

## Collector Changes Needed

Update OTel Collector Helm values to add Prometheus scrape targets for Tekton components.

## Traffic Generation

- Create a simple Tekton Task and TaskRun that runs a shell command
- Create a Pipeline and PipelineRun with multiple steps
- This will exercise the controller reconciliation paths that emit traces and metrics

## Steps

1. Apply Tekton release manifest
2. Wait for all Tekton pods to be ready
3. Patch config-observability for OTLP tracing
4. Patch config-tracing for HTTP tracing
5. Update OTel Collector with Tekton Prometheus scrape targets
6. Create and run sample TaskRuns and PipelineRuns
7. Verify telemetry in /tmp/otel-eval-pipeline/

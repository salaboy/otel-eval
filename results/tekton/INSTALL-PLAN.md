# Tekton Pipelines - Installation Plan

## Version
- **Tekton Pipelines**: v1.11.1
- **Release date**: 2026-04-21

## Installation Method
- **Method**: kubectl apply of official release manifest
- **Manifest URL**: https://storage.googleapis.com/tekton-releases/pipeline/releases/v1.11.1/release.yaml
- **Namespace**: `tekton-pipelines` (created by manifest)

## Telemetry Configuration

### Traces (OTLP gRPC)
Patch the `config-tracing` ConfigMap post-install to enable OTLP trace export:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-tracing
  namespace: tekton-pipelines
data:
  backend: "otlp"
  endpoint: "otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317"
  debug: "true"
```

### Metrics (Prometheus scrape)
Add Prometheus scrape configs for Tekton controller and webhook to the OTel Collector:
- `tekton-pipelines-controller.tekton-pipelines.svc.cluster.local:9090`
- `tekton-pipelines-webhook.tekton-pipelines.svc.cluster.local:9009`

### Logs
- Collected from stdout via kubectl/container runtime
- No OTLP log export natively

## Collector Changes
Update collector values.yaml to add Prometheus scrape configs for Tekton.

## Traffic Generation
Create sample TaskRun and PipelineRun resources to exercise Tekton's reconciler and generate telemetry:
1. Create a simple Task that runs `echo hello`
2. Create a TaskRun to execute it
3. Create a Pipeline with multiple steps
4. Create a PipelineRun to execute the pipeline

## Steps
1. Apply Tekton release manifest
2. Wait for all pods to be ready
3. Patch config-tracing ConfigMap for OTLP trace export
4. Update OTel Collector to scrape Tekton Prometheus metrics
5. Create and run sample Task/Pipeline resources
6. Verify telemetry is flowing

# Tekton Pipelines - Installation Plan

## Project Summary
Tekton Pipelines v1.11.1 - Kubernetes-native CI/CD framework

## Installation Method
- **Method**: kubectl apply of official release manifest
- **Version**: v1.11.1
- **Manifest**: https://github.com/tektoncd/pipeline/releases/download/v1.11.1/release.yaml
- **Namespace**: `tekton-pipelines` (created by manifest)

## Telemetry Configuration

### Metrics
- Protocol: Prometheus (via `metrics-protocol: prometheus` in config-observability)
- Endpoints: `:9090` on controller, webhook, and events-controller services
- Collector: Prometheus receiver scraping all three endpoints

### Traces
- Protocol: OTLP HTTP (via `config-tracing` ConfigMap)
- Keys: `enabled: "true"`, `endpoint: http://...:4318/v1/traces`
- Note: Uses otlptracehttp internally (NOT gRPC)

### Logs
- Stdout JSON logs only; no OTLP export

## Collector Changes
Added Prometheus scrape targets to collector values.yaml:
- `tekton-pipelines-controller.tekton-pipelines.svc.cluster.local:9090`
- `tekton-pipelines-webhook.tekton-pipelines.svc.cluster.local:9090`
- `tekton-events-controller.tekton-pipelines.svc.cluster.local:9090`

## Traffic Generation
Created TaskRuns and PipelineRuns to exercise the project:
- 3x hello-task TaskRuns
- 3x hello-pipeline PipelineRuns
- 1x fail-task TaskRun (error case)
- Additional TaskRuns and PipelineRuns after tracing config was set

## Actual Installation Steps
1. `kubectl apply -f https://github.com/tektoncd/pipeline/releases/download/v1.11.1/release.yaml`
2. `kubectl patch configmap config-observability -n tekton-pipelines` (set metrics-protocol: prometheus)
3. `kubectl patch configmap config-tracing -n tekton-pipelines` (set enabled: true, endpoint: OTLP HTTP URL)
4. Helm upgrade otel-collector with Prometheus scrape configs added
5. Create Tasks, Pipelines, TaskRuns, PipelineRuns to generate telemetry

## Telemetry Status
- Traces: FLOWING via OTLP HTTP (2 services: taskrun-reconciler, pipelinerun-reconciler)
- Metrics: FLOWING via Prometheus scrape (96 metrics, 19 Tekton-specific)
- Logs: NOT FLOWING (stdout only, no OTLP export)

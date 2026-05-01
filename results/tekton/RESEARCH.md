# Tekton Pipelines - OTel Research Notes

## What is Tekton?
Tekton is a CNCF project providing a Kubernetes-native CI/CD framework. It defines CRDs (Task, Pipeline, TaskRun, PipelineRun) and a controller that reconciles them, running build/deploy workloads as Kubernetes pods. The controller is built on Knative's reconciliation framework.

## Installation
- **Method**: kubectl apply of official release manifests
- **Version**: v1.11.1 (released 2026-04-21)
- **Namespace**: `tekton-pipelines` (created by manifest)
- **Release manifest**: https://github.com/tektoncd/pipeline/releases/download/v1.11.1/release.yaml
- **Components**: tekton-pipelines-controller, tekton-pipelines-webhook, tekton-events-controller, tekton-pipelines-remote-resolvers

## Telemetry Capabilities

### Metrics (Prometheus - CONFIRMED FLOWING)
- Exposed at `controller-service.tekton-pipelines:9090` (Prometheus format)
- Also at `webhook-service.tekton-pipelines:9090` and `events-controller:9090`
- Configured via `config-observability` ConfigMap with `metrics-protocol: prometheus`
- **Tekton-specific metrics (19 total)**:
  - `tekton_pipelines_controller_pipelinerun_duration_seconds` (Histogram)
  - `tekton_pipelines_controller_pipelinerun_taskrun_duration_seconds` (Histogram)
  - `tekton_pipelines_controller_pipelinerun_total` (Counter)
  - `tekton_pipelines_controller_running_pipelineruns` (Gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_pipeline_resolution` (Gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_task_resolution` (Gauge)
  - `tekton_pipelines_controller_running_taskruns` (Gauge)
  - `tekton_pipelines_controller_running_taskruns_waiting_on_task_resolution_count` (Gauge)
  - `tekton_pipelines_controller_taskrun_duration_seconds` (Histogram)
  - `tekton_pipelines_controller_taskrun_total` (Counter)
  - `tekton_pipelines_controller_taskruns_pod_latency_milliseconds` (Histogram)
  - `kn_workqueue_*` (Knative work queue metrics)
  - `kn_webhook_handler_duration_seconds`
  - `kn_k8s_client_http_response_status_code_total`
- Uses OTel SDK internally (otel_scope_name label visible in Prometheus output)
- Resource attributes include: `service.name`, `service.instance.id`, `service_name`, `service_version` (git commit)
- **96 total unique metrics** collected via Prometheus scrape

### Traces (OTLP HTTP - CONFIRMED FLOWING)
- Configured via `config-tracing` ConfigMap with keys: `enabled: "true"`, `endpoint: http://...:4318/v1/traces`
- Uses `otlptracehttp` exporter (HTTP, NOT gRPC)
- **Two reconciler services**:
  - `taskrun-reconciler`: TaskRun reconciliation spans
  - `pipelinerun-reconciler`: PipelineRun reconciliation spans
- **Span names (16 unique)**:
  - `TaskRun:ReconcileKind`, `TaskRun:Reconciler`
  - `PipelineRun:ReconcileKind`, `PipelineRun:Reconciler`
  - `prepare`, `reconcile`, `createPod`, `createTaskRun`, `createTaskRuns`
  - `resolvePipelineState`, `runNextSchedulableTask`
  - `updateTaskRunWithDefaultWorkspaces`, `updateLabelsAndAnnotations`
  - `updatePipelineRunStatusFromInformer`
  - `finishReconcileUpdateEmitEvents`, `durationAndCountMetrics`, `stopSidecars`
- **Resource attributes**: `service.name` (set natively), plus k8s.* (enriched by collector)
- **Span attributes**: Custom keys only (`taskrun`, `namespace`) - NOT OTel semantic conventions
- **No service.version** in trace resource attributes (only git commit in metrics)

### Context Propagation (W3C Trace Context - CONFIRMED)
- Tekton propagates W3C traceparent to TaskRun pods via annotation `tekton.dev/taskrunSpanContext`
- Example: `{"traceparent":"00-3dbb099caf71396db5596e9a20f9fc6f-ee013ea73bfc5df8-01"}`
- Allows workloads inside TaskRuns to join the parent trace
- Uses `propagation.TraceContext{}` propagator (W3C standard)

### Logs
- Controller emits structured JSON logs to stdout
- Logs include `knative.dev/traceid` field (internal Knative trace ID, UUID format - NOT OTel trace ID)
- No OTLP log export
- No logs flowing to collector

## Configuration Details

### Tracing Config (config-tracing ConfigMap)
```yaml
data:
  enabled: "true"
  endpoint: "http://otel-collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4318/v1/traces"
```

### Metrics Config (config-observability ConfigMap)
```yaml
data:
  metrics-protocol: prometheus
  metrics.taskrun.level: "task"
  metrics.taskrun.duration-type: "histogram"
  metrics.pipelinerun.level: "pipeline"
  metrics.pipelinerun.duration-type: "histogram"
  metrics.count.enable-reason: "true"
```

## Observations vs Documentation

### What worked as documented:
- Prometheus metrics endpoint at :9090 on controller service
- config-tracing ConfigMap with `enabled` and `endpoint` keys for OTLP HTTP traces
- W3C trace context propagation to TaskRun pods via annotations
- Dynamic config reload (controller picks up ConfigMap changes without restart)

### Surprises:
- In v1.11.1, there are TWO tracing systems:
  1. Legacy `config-tracing` ConfigMap (enabled/endpoint keys) - uses otlptracehttp
  2. New `config-observability` ConfigMap (tracing-protocol/tracing-endpoint keys) - not yet active
- The `config-observability` tracing settings were not effective in v1.11.1 (only `metrics-protocol` worked)
- Traces use HTTP OTLP (not gRPC), despite config-observability supporting gRPC
- Span attributes use custom keys (taskrun, namespace) not OTel semantic conventions
- service.version not set in trace resource (only git commit hash in metrics)
- Logs contain internal Knative trace IDs (UUID), not OTel trace IDs

### Project-native vs collector-derived:
- **Project-native**: service.name, span names, span attributes (taskrun, namespace)
- **Collector-derived (k8sattributes)**: k8s.pod.name, k8s.namespace.name, k8s.deployment.name, k8s.node.name, k8s.pod.uid, k8s.pod.label.*, k8s.pod.annotation.*
- **Prometheus-native**: service.instance.id, service_version (git commit), job label

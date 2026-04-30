# Tekton Pipelines - OTel Research Notes

## What is Tekton?

Tekton is a CNCF graduated project providing Kubernetes-native CI/CD pipeline primitives. It defines CRDs (Task, Pipeline, TaskRun, PipelineRun) that allow building, testing, and deploying applications. The controller runs in the `tekton-pipelines` namespace and processes these CRDs.

## Installation

- **Method**: kubectl apply with release YAML from Google Cloud Storage
- **Latest version**: v1.11.1 (released 2026-04-21)
- **Release URL**: `https://storage.googleapis.com/tekton-releases/pipeline/previous/v1.11.1/release.yaml`
- **Namespace**: `tekton-pipelines` (created by the release YAML)

## Telemetry Capabilities

### Metrics
- **Protocol**: Prometheus (default), OTLP gRPC, OTLP HTTP (`http/protobuf`), or `none`
- **Endpoint**: Port 9090 on `controller-service` in `tekton-pipelines` namespace
- **Configuration**: `config-observability` ConfigMap in `tekton-pipelines` namespace
- **Key metrics**:
  - `tekton_pipelines_controller_pipelinerun_duration_seconds_*` (histogram)
  - `tekton_pipelines_controller_pipelinerun_taskrun_duration_seconds_*` (histogram)
  - `tekton_pipelines_controller_pipelinerun_total` (counter)
  - `tekton_pipelines_controller_running_pipelineruns` (gauge)
  - `tekton_pipelines_controller_taskrun_duration_seconds_*` (histogram)
  - `tekton_pipelines_controller_taskrun_total` (counter)
  - `tekton_pipelines_controller_running_taskruns` (gauge)
  - `tekton_pipelines_controller_client_latency_*` (histogram)

### Traces
- **Protocol**: OTLP gRPC, OTLP HTTP (`http/protobuf`), `stdout`, or `none` (default)
- **Configuration**: `config-observability` ConfigMap
- **Sampling rate**: Configurable 0.0 to 1.0 (default 1.0)
- **Tracing scope**: Controller operations for TaskRun/PipelineRun reconciliation

### Logs
- **Format**: Structured JSON logs via Go's `zap` logger
- **Output**: stdout (container logs)
- **No native OTLP log export** - logs go to container stdout

## Configuration Method

The `config-observability` ConfigMap in `tekton-pipelines` namespace controls all telemetry:

```yaml
data:
  metrics-protocol: grpc                    # prometheus | grpc | http/protobuf | none
  metrics-endpoint: "otel-collector:4317"   # for grpc/http
  metrics-export-interval: "30s"
  tracing-protocol: grpc                    # grpc | http/protobuf | stdout | none
  tracing-endpoint: "otel-collector:4317"   # for grpc/http
  tracing-sampling-rate: "1.0"
```

## Context Propagation

- Tekton uses W3C TraceContext for propagating trace context
- Spans are created for TaskRun and PipelineRun reconciliation loops

## Special Setup Notes

- Requires `cert-manager` or built-in webhook certificates
- The release YAML includes all CRDs and RBAC
- Metrics are labeled with pipeline/task/run names and status

## Traffic Generation

- Create TaskRun and PipelineRun CRDs to trigger controller activity
- The controller will emit metrics/traces as it processes these resources
- No HTTP traffic routing needed (CI/CD system, not an HTTP proxy)

## Actual Observations (Post-Installation)

### Traces - FLOWING via OTLP gRPC
- **Service names**: `pipelinerun-reconciler`, `taskrun-reconciler`
- **Instrumentation scopes**: `PipelineRunReconciler`, `TaskRunReconciler`
- **Span names**: PipelineRun:Reconciler, PipelineRun:ReconcileKind, TaskRun:Reconciler, TaskRun:ReconcileKind, reconcile, resolvePipelineState, createTaskRuns, createTaskRun, createPod, prepare, updateLabelsAndAnnotations, finishReconcileUpdateEmitEvents, durationAndCountMetrics, stopSidecars, updatePipelineRunStatusFromInformer, updateTaskRunWithDefaultWorkspaces, runNextSchedulableTask
- **Span attributes**: Only `pipelinerun`/`taskrun` + `namespace` on root spans; child spans have no attributes
- **Resource attributes**: `service.name` only (no `service.version`, no `telemetry.sdk.*`)
- **Context propagation**: TraceContext is stored in TaskRun/PipelineRun status annotations ("updating TaskRun status with SpanContext" events)
- **No W3C traceparent header injection** in HTTP requests from users - this is internal controller instrumentation only
- **Total spans observed**: ~1815 across 14 batches

### Metrics - FLOWING via Prometheus scrape
- **Protocol**: Prometheus (scraped by OTel collector from port 9090)
- **Scope name**: `tekton_pipelines_controller`
- **Tekton-native metrics** (11 metrics):
  - `tekton_pipelines_controller_pipelinerun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_pipelinerun_taskrun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_pipelinerun_total` (counter)
  - `tekton_pipelines_controller_running_pipelineruns` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_pipeline_resolution` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_task_resolution` (gauge)
  - `tekton_pipelines_controller_running_taskruns` (gauge)
  - `tekton_pipelines_controller_running_taskruns_waiting_on_task_resolution_count` (gauge)
  - `tekton_pipelines_controller_taskrun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_taskruns_pod_latency_milliseconds` (histogram)
  - `tekton_pipelines_controller_taskrun_total` (counter)
- **Labels**: namespace, pipeline/task name, status
- **Also exposes**: Go runtime metrics, kn (Knative) workqueue metrics, process metrics

### Logs - NOT via OTLP
- Logs are structured JSON to stdout (zap logger)
- Include `knative.dev/traceid` field in each log line (trace correlation!)
- No OTLP log export capability

### Config Mechanism
- `config-observability` ConfigMap in `tekton-pipelines` namespace
- `config-tracing` ConfigMap (legacy, for HTTP endpoint)
- Requires controller restart to pick up changes

### Notable Findings
- Tekton supports BOTH Prometheus AND OTLP metrics export (configurable)
- Trace context is propagated by storing span context in K8s resource annotations
- Metrics are labeled with Tekton-specific dimensions (pipeline name, task name, namespace, status)
- No `service.version` in trace resource (only in pod labels, collector-enriched)
- Metrics use Prometheus naming conventions (not OTel semantic conventions)
- The `config-tracing` ConfigMap is a legacy mechanism for HTTP-based tracing; `config-observability` is the new OTel-native config

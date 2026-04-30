# Tekton Pipelines - OTel Research Notes

## What is Tekton?

Tekton is a CNCF graduated project that provides cloud-native CI/CD pipeline primitives for Kubernetes. It defines CRDs (`Task`, `TaskRun`, `Pipeline`, `PipelineRun`) that allow users to define and run CI/CD workflows as Kubernetes-native objects.

GitHub: https://github.com/tektoncd/pipeline
Version evaluated: v1.11.1

## Installation Method

- **Primary method**: kubectl apply of official release manifest
- **Manifest URL**: https://github.com/tektoncd/pipeline/releases/download/v1.11.1/release.yaml
- **Namespace**: `tekton-pipelines` (created by manifest)
- **Additional namespace**: `tekton-pipelines-resolvers` (for remote resolvers)

## Telemetry Capabilities (Observed)

### Traces - FLOWING via OTLP HTTP
- Tekton emits traces via OTLP HTTP (configured via `config-tracing` ConfigMap)
- Configuration: `enabled: "true"`, `endpoint: http://<otlp-endpoint>:4318/v1/traces`
- Service names: `taskrun-reconciler`, `pipelinerun-reconciler`
- Instrumentation scopes: `TaskRunReconciler`, `PipelineRunReconciler`
- Schema URL: `https://opentelemetry.io/schemas/1.12.0`
- Span names: `TaskRun:Reconciler`, `TaskRun:ReconcileKind`, `PipelineRun:Reconciler`, `PipelineRun:ReconcileKind`, `reconcile`, `prepare`, `createPod`, `updateLabelsAndAnnotations`, `finishReconcileUpdateEmitEvents`, `durationAndCountMetrics`, `resolvePipelineState`, `runNextSchedulableTask`, `createTaskRun`, `createTaskRuns`, `stopSidecars`, `updatePipelineRunStatusFromInformer`
- Span events: "updating TaskRun status with SpanContext", "updating PipelineRun status with SpanContext"
- Span attributes: `taskrun`, `namespace`, `pipelinerun` (limited, non-OTel semantic conventions)
- No span links between PipelineRun and TaskRun spans (separate traces)
- No OTel SDK resource attributes (telemetry.sdk.name, telemetry.sdk.version) in trace resource
- Status codes: all empty `{}` (no explicit OK/ERROR status set)
- 1024 total spans captured across 14 trace batches

### Metrics - FLOWING via Prometheus scrape
- Tekton exposes Prometheus metrics from controller, events-controller, and webhook
- Metric service names: `tekton-pipelines-controller`, `tekton-events-controller`, `tekton-pipelines-webhook`
- Tekton-specific metrics (scope: `tekton_pipelines_controller`):
  - `tekton_pipelines_controller_taskrun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_taskrun_total` (sum)
  - `tekton_pipelines_controller_taskruns_pod_latency_milliseconds` (histogram)
  - `tekton_pipelines_controller_pipelinerun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_pipelinerun_taskrun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_pipelinerun_total` (sum)
  - `tekton_pipelines_controller_running_taskruns` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_pipeline_resolution` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_task_resolution` (gauge)
  - `tekton_pipelines_controller_running_taskruns_waiting_on_task_resolution_count` (gauge)
- Also includes: HTTP client/server metrics (otelhttp scope), runtime metrics, knative workqueue metrics
- Metric labels include: `namespace`, `status`, `task`, `pipeline` (Tekton-specific, not OTel semantic conventions)
- config-observability ConfigMap supports `metrics-protocol: grpc` for OTLP gRPC metrics export (v1.11.1 feature)
  - When configured, metrics would flow via OTLP gRPC directly (not yet confirmed flowing in this eval)

### Logs - NOT FLOWING via OTLP
- Tekton controller emits structured JSON logs to stdout
- Logs contain: severity, timestamp, logger, caller, message, commit, knative.dev/pod, knative.dev/traceid, knative.dev/key, duration
- No OTLP log export support
- `knative.dev/traceid` in logs is a Knative internal ID, NOT an OTel trace ID

## Context Propagation
- Traces are internally consistent (parent-child span hierarchy within a single reconcile cycle)
- No cross-service trace propagation (TaskRun and PipelineRun traces are separate)
- No W3C Trace Context injection into TaskRun pods/steps

## Configuration Details
- **Tracing**: `config-tracing` ConfigMap - `enabled`, `endpoint`, `credentialsSecret`
- **Metrics**: `config-observability` ConfigMap - `metrics-protocol` (prometheus/grpc/http/protobuf/none), `metrics-endpoint`, `metrics-export-interval`, `tracing-protocol`, `tracing-endpoint`, `tracing-sampling-rate`
- Note: v1.11.1 has BOTH `config-tracing` AND `config-observability` for tracing config - the newer approach is `config-observability`

## Surprises / Deviations from Documentation
1. The `config-tracing` ConfigMap uses `enabled`/`endpoint` keys (not `backend`/`endpoint` as older docs suggest)
2. Tekton v1.11.1 has moved to a unified `config-observability` approach that supports OTLP for both traces and metrics
3. Span attributes use non-standard keys (`taskrun`, `namespace`, `pipelinerun`) rather than OTel semantic conventions
4. No `telemetry.sdk.*` resource attributes in trace data
5. No span status codes set (all spans have empty status `{}`)
6. Logs contain `knative.dev/traceid` which is NOT an OTel trace ID (it's a Knative internal UUID)

## Project-Native vs Collector-Derived
- **Project-native traces**: All trace data (service.name, span names, span attributes) comes from Tekton itself
- **Project-native metrics**: `tekton_pipelines_controller_*` metrics come from Tekton's Prometheus endpoint
- **Collector-derived**: k8s.* resource attributes (pod name, deployment name, namespace, etc.) are added by the k8sattributes processor
- **Collector-derived**: `server.address`, `service.instance.id`, `server.port`, `url.scheme` on metrics come from Prometheus receiver

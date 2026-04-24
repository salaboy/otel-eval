# Tekton Pipelines — OTel Research Notes

## What is the project?

Tekton Pipelines is a CNCF graduated project providing cloud-native CI/CD primitives for Kubernetes. It introduces CRDs (Task, TaskRun, Pipeline, PipelineRun, StepAction) that let users define and execute CI/CD workflows as Kubernetes-native objects. Tekton is the foundation for higher-level tools like Tekton Triggers, Tekton Chains, and Red Hat OpenShift Pipelines.

## Version

- **Latest release:** v1.11.1 ("Javanese Jocasta") — released 2026-04-21
- **Install manifest:** https://github.com/tektoncd/pipeline/releases/download/v1.11.1/release.yaml

## Installation Method

Tekton Pipelines is installed via raw Kubernetes manifests (no Helm chart). The official release YAML bundles:
- Namespace: `tekton-pipelines`
- CRDs (Task, TaskRun, Pipeline, PipelineRun, StepAction, etc.)
- RBAC (ClusterRoles, ClusterRoleBindings, ServiceAccounts)
- Controllers: `tekton-pipelines-controller`, `tekton-pipelines-events`, `tekton-pipelines-remote-resolvers`, `tekton-pipelines-webhook`
- ConfigMaps: `config-observability`, `config-tracing`, `config-logging`, `feature-flags`, etc.

## Telemetry Capabilities

### Metrics
- **Protocol:** Prometheus (default), or OTLP via `grpc`/`http/protobuf`
- **Configuration:** `config-observability` ConfigMap in `tekton-pipelines` namespace
  - `metrics-protocol`: `prometheus` (default), `grpc`, `http/protobuf`, `none`
  - `metrics-endpoint`: empty (uses default OTLP endpoint for grpc/http)
  - `metrics-export-interval`: empty (uses default)
- **Prometheus port:** 9090 on controller, events, remote-resolvers, webhook pods
- **Key metrics:**
  - `tekton_taskrun_duration_seconds` (histogram)
  - `tekton_pipelinerun_duration_seconds` (histogram)
  - `tekton_running_taskruns_count`
  - `tekton_running_pipelineruns_count`
  - `tekton_taskrun_count` (counter by result: succeeded/failed/etc.)
  - `tekton_pipelinerun_count`
  - Various reconciler/workqueue metrics from controller-runtime

### Traces
- **Protocol:** HTTP/protobuf or gRPC (OTLP-compatible), `stdout`, or `none`
- **Configuration:** Two overlapping mechanisms:
  1. `config-tracing` ConfigMap: `enabled: "true"`, `endpoint: "<otlp-http-endpoint>"`
  2. `config-observability` ConfigMap: `tracing-protocol: grpc|http/protobuf|none|stdout`, `tracing-endpoint: ""`, `tracing-sampling-rate: "1.0"`
- **What is traced:** TaskRun and PipelineRun reconciliation spans; step execution spans
- **Context propagation:** Traces are propagated via Kubernetes annotations on TaskRun/PipelineRun objects (SpanContext field in status)

### Logs
- **Format:** Structured JSON via `zap` logger
- **Configuration:** `config-logging` ConfigMap
- **OTLP log export:** Not supported natively; logs go to stdout only
- **Log levels:** Configurable per component

## OpenTelemetry Support (v1.11.1)

Tekton v1.11.1 has migrated from OpenCensus to OpenTelemetry SDK natively:
- Uses `go.opentelemetry.io/otel` SDK
- Supports OTLP gRPC and HTTP/protobuf for both metrics and traces
- `config-observability` is the primary config point (replaces legacy `metrics.backend-destination`)
- `config-tracing` is a secondary/legacy tracing config

## Context Propagation

- SpanContext is stored in TaskRun/PipelineRun `.status.spanContext` annotations
- W3C Trace Context propagation is used internally between reconciler spans

## Special Setup Notes

- Requires cert-manager or the bundled webhook certificates
- The webhook mutates/validates Tekton CRD objects
- Tekton controller watches TaskRun/PipelineRun objects and creates pods for steps
- No sidecar injection; telemetry comes from the controller/webhook pods themselves

## Actual Observations (post-install)

### Traces (FLOWING via OTLP gRPC)
- **Service names:** `pipelinerun-reconciler`, `taskrun-reconciler`
- **Instrumentation scopes:** `PipelineRunReconciler`, `TaskRunReconciler`
- **Span names observed:**
  - `PipelineRun:Reconciler`, `PipelineRun:ReconcileKind`
  - `TaskRun:Reconciler`, `TaskRun:ReconcileKind`
  - `createTaskRun`, `createTaskRuns`, `createPod`
  - `resolvePipelineState`, `runNextSchedulableTask`
  - `prepare`, `reconcile`, `updateLabelsAndAnnotations`
  - `updatePipelineRunStatusFromInformer`, `updateTaskRunWithDefaultWorkspaces`
  - `finishReconcileUpdateEmitEvents`, `durationAndCountMetrics`, `stopSidecars`
- **Span attributes:** `taskrun` (name), `namespace`, `pipelinerun` (name) — minimal, no OTel semantic conventions
- **Span events:** "updating PipelineRun status with SpanContext", "updating TaskRun status with SpanContext"
- **Span kind:** All INTERNAL (kind=1) — no CLIENT/SERVER spans
- **Context propagation:** SpanContext stored in TaskRun/PipelineRun `.status.spanContext` annotations; no W3C Trace Context propagation for external callers
- **Source:** Project-native (OTel SDK via OTLP gRPC to collector)

### Metrics (FLOWING via Prometheus scrape)
- **Source:** Prometheus endpoints on port 9090 of controller pods; scraped by OTel Collector Prometheus receiver
- **Tekton-native metrics:**
  - `tekton_pipelines_controller_taskrun_duration_seconds` (histogram, labels: namespace, status, task)
  - `tekton_pipelines_controller_pipelinerun_duration_seconds` (histogram, labels: namespace, status, pipeline)
  - `tekton_pipelines_controller_pipelinerun_taskrun_duration_seconds` (histogram)
  - `tekton_pipelines_controller_taskrun_total` (counter, labels: namespace, status, task)
  - `tekton_pipelines_controller_pipelinerun_total` (counter, labels: namespace, status, pipeline)
  - `tekton_pipelines_controller_running_taskruns` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_pipeline_resolution` (gauge)
  - `tekton_pipelines_controller_running_pipelineruns_waiting_on_task_resolution` (gauge)
  - `tekton_pipelines_controller_running_taskruns_waiting_on_task_resolution_count` (gauge)
  - `tekton_pipelines_controller_taskruns_pod_latency_milliseconds` (histogram)
- **Knative workqueue/webhook metrics:** `kn_workqueue_*`, `kn_webhook_*`, `kn_k8s_client_*` — from controller-runtime/knative infra
- **Note:** Metrics are Prometheus-native (not OTLP). The `metrics-protocol: prometheus` setting means no OTLP metrics export. OTLP metrics export is supported but not default.

### Logs (NOT FLOWING via OTLP)
- Logs are emitted to stdout only (structured JSON via zap logger)
- No OTLP log export supported natively
- Logs file: 0 lines (not collected via OTLP)

### Surprises / Deviations
- `config-tracing` ConfigMap exists but appears to be a legacy/overlapping mechanism with `config-observability`; the `config-observability` `tracing-protocol: grpc` setting is what actually activates OTLP trace export
- Span attributes use non-standard key names (`taskrun`, `namespace`, `pipelinerun`) rather than OTel semantic conventions (e.g., `tekton.taskrun.name`)
- No `service.version` attribute in trace resource (only in k8s labels, added by collector's k8sattributes processor)
- Step-level traces not emitted (only reconciler/controller spans); actual task step execution is not traced at the step level in the controller
- Metrics use non-OTel naming (Prometheus convention with underscores) but have good descriptions and labels

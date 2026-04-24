# OpenTelemetry Support Maturity Evaluation: Tekton Pipelines

## Project overview

- **Project**: Tekton Pipelines — cloud-native CI/CD primitives for Kubernetes (Tasks, TaskRuns, Pipelines, PipelineRuns)
- **Version evaluated**: v1.11.1 ("Javanese Jocasta")
- **Evaluation date**: 2026-04-24
- **Cluster**: otel-eval-pipeline (kind)
- **Maturity model version**: OpenTelemetry Support Maturity Model for CNCF Projects (draft)

## Summary

| Dimension | Level | Summary |
|-----------|-------|---------|
| Integration Surface | 2 | OTLP gRPC traces and Prometheus metrics both work; logs stdout-only; OTLP metrics available but not default |
| Semantic Conventions | 1 | Custom attribute names (`taskrun`, `pipelinerun`, `namespace`) instead of OTel conventions; metrics use Prometheus naming; schema URL present but pinned to old version |
| Resource Attributes & Configuration | 1 | `service.name` set natively; no `service.version` in resource; no `OTEL_*` env var support; configuration via proprietary ConfigMaps only |
| Trace Modeling & Context Propagation | 2 | Rich reconciler span hierarchy with parent-child relationships; SpanContext propagated via k8s annotations; no W3C Trace Context injection for external callers |
| Multi-Signal Observability | 2 | Traces via OTLP and metrics via Prometheus both flowing; logs stdout-only with no OTLP export; no cross-signal correlation (no traceId on logs) |
| Audience & Signal Quality | 2 | Span names reflect logical operations (not raw code paths); metric descriptions present; telemetry is operator-useful but missing step-level granularity |
| Stability & Change Management | 2 | Breaking OTel migration documented in dedicated `metrics-migration-otel.md`; metrics marked "experimental"; schema URL present; no explicit stability guarantees |

**Overall profile**: Tekton Pipelines has made a genuine, intentional investment in OpenTelemetry support — migrating from OpenCensus to the OTel SDK in v1.11.x, supporting OTLP export for both traces and metrics, and documenting breaking changes carefully. The main gaps are: non-standard span/metric attribute naming, no `OTEL_*` env var support, no OTLP log export, and no W3C Trace Context propagation for external callers.

---

## Telemetry overview

### Signals observed
- **Traces**: Flowing — OTLP gRPC to collector (`tracing-protocol: grpc` in `config-observability`)
- **Metrics**: Flowing — Prometheus scrape on port 9090 of controller pods (`metrics-protocol: prometheus`)
- **Logs**: Not flowing via OTLP — stdout only (structured JSON via zap); 0 lines in logs.jsonl

### Resource attributes (native, before collector enrichment)

From trace resource attributes — the project natively emits only:
- `service.name`: `pipelinerun-reconciler` or `taskrun-reconciler`

No other resource attributes are set by Tekton itself. All `k8s.*` attributes in the telemetry files are added by the OTel Collector's `k8sattributes` processor.

Confirmed by: the scope names (`PipelineRunReconciler`, `TaskRunReconciler`) and the fact that no `service.version`, `service.namespace`, or `telemetry.sdk.*` attributes appear in the raw resource before enrichment.

### Resource attributes (after collector enrichment)

After `k8sattributes` processing, traces carry:
```
k8s.container.name: tekton-pipelines-controller
k8s.deployment.name: tekton-pipelines-controller
k8s.namespace.name: tekton-pipelines
k8s.node.name: otel-eval-pipeline-control-plane
k8s.pod.annotation.kubectl.kubernetes.io/restartedAt: 2026-04-24T08:56:16Z
k8s.pod.label.app.kubernetes.io/component: controller
k8s.pod.label.app.kubernetes.io/instance: default
k8s.pod.label.app.kubernetes.io/name: controller
k8s.pod.label.app.kubernetes.io/part-of: tekton-pipelines
k8s.pod.label.app.kubernetes.io/version: v1.11.1
k8s.pod.label.app: tekton-pipelines-controller
k8s.pod.label.pipeline.tekton.dev/release: v1.11.1
k8s.pod.label.pod-template-hash: d649b7587
k8s.pod.label.version: v1.11.1
k8s.pod.name: tekton-pipelines-controller-d649b7587-2nmsm
k8s.pod.start_time: 2026-04-24T08:56:16Z
k8s.pod.uid: be32dfbf-538f-4fd3-a835-f3aa064f4242
k8s.replicaset.name: tekton-pipelines-controller-d649b7587
service.name: pipelinerun-reconciler   ← native
```

---

## Dimension evaluations

### 1. Integration Surface

**Level: 2 — Structured OTLP Export**

#### Evidence

- **Traces**: Tekton emits traces via OTLP gRPC natively. Activated by setting `tracing-protocol: grpc` and `tracing-endpoint: <collector>:4317` in the `config-observability` ConfigMap. Traces are flowing from `pipelinerun-reconciler` and `taskrun-reconciler` services.
- **Metrics**: Tekton exposes Prometheus endpoints on port 9090 of all controller pods. Prometheus is the default (`metrics-protocol: prometheus` in ConfigMap). OTLP gRPC and HTTP/protobuf are also supported options for metrics export.
- **Logs**: No OTLP log export. Logs go to stdout as structured JSON (zap). Not collected via OTLP.
- **Configuration interface**: All telemetry configuration is via a proprietary `config-observability` ConfigMap (not `OTEL_*` env vars). The `config-tracing` ConfigMap is a secondary/legacy mechanism for HTTP-only tracing.
- **No sidecar or agent required**: Tekton emits telemetry directly from controller pods.
- **Default behavior**: By default, `tracing-protocol: none` (traces disabled), `metrics-protocol: prometheus` (metrics on). Operators must explicitly enable OTLP tracing.

#### Checklist assessment

- ✅ Project emits at least one signal via a structured format (OTLP traces, Prometheus metrics)
- ✅ OTLP export is available for traces (gRPC and HTTP/protobuf)
- ✅ OTLP export is available for metrics (gRPC and HTTP/protobuf, opt-in)
- ✅ Prometheus scrape endpoint available for metrics (default)
- ❌ OTLP log export not available
- ❌ OTLP is not the default for metrics (Prometheus is default; tracing is off by default)
- ❌ No `OTEL_EXPORTER_OTLP_ENDPOINT` env var support; endpoint configured via ConfigMap only

#### Rationale

Level 2 is appropriate: Tekton has genuine OTLP support for traces (working, tested) and offers OTLP as an option for metrics. This is more than basic Prometheus-only (Level 1) but falls short of Level 3 because OTLP is not the default for any signal, log export is absent, and configuration requires proprietary ConfigMap editing rather than standard `OTEL_*` env vars.

---

### 2. Semantic Conventions

**Level: 1 — Partial / Inconsistent Conventions**

#### Evidence

##### Trace attributes

Span-level attributes observed (all spans):
- `taskrun`: `"hello-taskrun-qvrmt"` — custom key, should be `tekton.taskrun.name` or similar
- `pipelinerun`: `"sample-pipelinerun-npzxs"` — custom key
- `namespace`: `"default"` — generic key, should be `k8s.namespace.name` (OTel semconv)

No OTel semantic convention attributes found in span attributes:
- No `k8s.taskrun.*` (no such semconv yet, but no Tekton-specific namespace either)
- No `error.type` on failed spans
- No `exception.*` events

Span kinds: All spans are `INTERNAL` (kind=1), including root reconciler spans. Root spans that represent the entry point of a reconciliation loop could arguably be `CONSUMER` kind (processing work from a queue), but `INTERNAL` is not technically wrong for controller reconciliation.

Schema URL in traces: `https://opentelemetry.io/schemas/1.12.0` — present but pinned to a **2022 schema version** (current stable is 1.29.0+). This indicates the OTel SDK version used is older.

##### Metric names and attributes

Tekton-native metric names use Prometheus underscore convention:
- `tekton_pipelines_controller_taskrun_duration_seconds`
- `tekton_pipelines_controller_pipelinerun_total`
- etc.

These are not OTel semantic convention names (which would use `.` separators like `tekton.pipeline.taskrun.duration`), but Prometheus naming is an accepted pattern for Prometheus-native metrics.

Metric attribute keys observed on Tekton metrics:
- `namespace`, `status`, `task`, `pipeline` — custom keys, not OTel semconv

Infrastructure metrics from knative/otelhttp instrumentation use proper OTel semconv:
- `http_request_method`, `http_response_status_code`, `server_address`, `server_port`, `url_scheme` — these are current stable HTTP semconv attribute names (correct!)
- Scope: `go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.67.0`

Schema URL in metrics: `https://opentelemetry.io/schemas/1.18.0` — present but also older than current.

##### Log attributes

No OTLP logs emitted. Cannot assess.

#### Checklist assessment

- ✅ Schema URL is set in both traces and metrics exports
- ✅ HTTP instrumentation (via otelhttp) uses current stable semconv (`http_request_method`, `http_response_status_code`)
- ❌ Span attributes use custom keys (`taskrun`, `pipelinerun`, `namespace`) instead of OTel conventions
- ❌ No `k8s.namespace.name` on spans (uses plain `namespace` key)
- ❌ Schema URL is pinned to old versions (1.12.0 for traces, 1.18.0 for metrics)
- ❌ Instrumentation scope version is `unknown` for both `PipelineRunReconciler` and `TaskRunReconciler`
- ❌ No `service.version` in resource attributes (native)

#### Rationale

Level 1: Tekton partially follows conventions — the HTTP auto-instrumentation layer uses correct current semconv, and schema URLs are present. However, the project's own span attributes use non-standard custom keys rather than OTel conventions. The schema URLs are stale, and instrumentation library versions are not set. This is better than Level 0 (no conventions at all) but not Level 2 (consistent, correct semconv alignment).

---

### 3. Resource Attributes & Configuration

**Level: 1 — Minimal Resource Identity**

#### Evidence

##### Native resource attributes

The only resource attribute Tekton sets natively is:
- `service.name`: `pipelinerun-reconciler` or `taskrun-reconciler`

This is a meaningful, distinct identity (two separate reconciler services are distinguished). However:
- No `service.version` (version v1.11.1 is only in k8s pod labels, added by collector)
- No `service.namespace` 
- No `service.instance.id`
- No `telemetry.sdk.name`, `telemetry.sdk.version`, `telemetry.sdk.language` (these would be set by the OTel Go SDK automatically — their absence suggests the SDK may not be initializing them, or they are stripped)

##### OTEL_* environment variable support

No `OTEL_*` environment variable support documented or observed. All telemetry configuration goes through:
1. `config-observability` ConfigMap: `tracing-protocol`, `tracing-endpoint`, `metrics-protocol`, `metrics-endpoint`
2. `config-tracing` ConfigMap: `enabled`, `endpoint`, `credentialsSecret`

There is no mechanism to set `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_RESOURCE_ATTRIBUTES`, etc. as standard env vars.

##### Identity consistency across signals

- Traces: `service.name = pipelinerun-reconciler` or `taskrun-reconciler`
- Metrics: No `service.name` in Prometheus-scraped metrics resource (Prometheus receiver creates its own resource); the metrics scope is `tekton_pipelines_controller`
- Logs: N/A (no OTLP logs)

The service identity is not consistent across signals — trace resources use `service.name`, but scraped Prometheus metrics don't carry the same identity.

#### Checklist assessment

- ✅ `service.name` is set natively and meaningfully distinguishes reconciler types
- ❌ `service.version` not set natively in resource
- ❌ No `OTEL_*` env var support
- ❌ No `OTEL_RESOURCE_ATTRIBUTES` support for operator customization
- ❌ Service identity not consistent across trace and metric signals
- ❌ `telemetry.sdk.*` attributes not present in exported data

#### Rationale

Level 1: Tekton sets a meaningful `service.name` natively, which is the minimum for signal identity. However, it lacks `service.version`, does not support standard `OTEL_*` env vars, and has no cross-signal identity consistency between traces and Prometheus metrics. This is a common pattern for Go projects that have adopted OTel SDK but haven't fully wired up resource detection.

---

### 4. Trace Modeling & Context Propagation

**Level: 2 — Coherent Trace Hierarchy**

#### Evidence

##### Span structure

A rich, hierarchical span tree is produced for both PipelineRun and TaskRun reconciliation:

**PipelineRun reconciliation tree:**
```
PipelineRun:Reconciler  [root, INTERNAL]
├── updatePipelineRunStatusFromInformer
├── reconcile
│   ├── PipelineRun:ReconcileKind
│   │   ├── resolvePipelineState
│   │   ├── resolvePipelineState (x2)
│   │   ├── runNextSchedulableTask
│   │   │   ├── createTaskRuns
│   │   │   │   └── createTaskRun
│   │   └── updateLabelsAndAnnotations
├── finishReconcileUpdateEmitEvents
└── durationAndCountMetrics
```

**TaskRun reconciliation tree:**
```
TaskRun:Reconciler  [root, INTERNAL]
├── updateTaskRunWithDefaultWorkspaces
├── TaskRun:ReconcileKind
│   ├── prepare
│   ├── createPod
│   └── stopSidecars
└── finishReconcileUpdateEmitEvents
```

Parent-child relationships are correctly set (confirmed via `parentSpanId` inspection). Span names are logical operation names, not raw Go function names.

##### Context propagation

- **Internal propagation**: SpanContext is stored in TaskRun/PipelineRun `.status.spanContext` Kubernetes annotations. This allows the controller to resume a trace across reconciliation loops (since each reconciliation is a separate goroutine invocation). Span events confirm this: "updating PipelineRun status with SpanContext" and "updating TaskRun status with SpanContext".
- **External propagation**: No W3C Trace Context (`traceparent`/`tracestate`) injection for external callers. A user submitting a TaskRun via `kubectl apply` or the Kubernetes API cannot inject a parent trace context that Tekton would honor.
- **Cross-component propagation**: No evidence of trace context propagation from PipelineRun spans to the child TaskRun reconciler spans (they appear as separate traces, not linked as parent-child across the controller boundary).

##### Trace coherence

Each reconciliation loop produces a coherent, self-contained trace tree. The trace tells a clear operational story: "here is what happened when this PipelineRun/TaskRun was reconciled." However, the full lifecycle of a PipelineRun (from creation through all reconciliation loops to completion) is not represented as a single continuous trace.

#### Checklist assessment

- ✅ Parent-child span relationships are correctly modeled
- ✅ Span names represent logical operations, not raw code paths
- ✅ SpanContext is persisted in k8s object status for cross-reconciliation continuity
- ✅ Span events are used meaningfully ("updating ... status with SpanContext")
- ❌ Root spans are all `INTERNAL` kind — no `CONSUMER` kind for queue-driven reconciliation
- ❌ No W3C Trace Context (`traceparent`) ingestion from external callers
- ❌ PipelineRun and its child TaskRun reconciliations appear as separate traces (not linked)
- ❌ No step-level spans for individual Task step execution (only controller-level spans)
- ❌ No span links connecting related traces

#### Rationale

Level 2: Tekton has a genuinely well-modeled trace hierarchy within each reconciliation loop. The use of `spanContext` in k8s object status to bridge reconciliation invocations is a clever and intentional design. The gaps — no external context ingestion, no cross-component trace linking between PipelineRun and TaskRun reconcilers, no step-level tracing — prevent Level 3. The trace gives operators visibility into controller behavior but not end-to-end pipeline execution visibility.

---

### 5. Multi-Signal Observability

**Level: 2 — Two Signals with Partial Correlation**

#### Evidence

##### Signal availability

| Signal | Status | Protocol | Native? |
|--------|--------|----------|---------|
| Traces | Flowing | OTLP gRPC | Yes (OTel SDK) |
| Metrics | Flowing | Prometheus scrape | Yes (OTel SDK Prometheus exporter) |
| Logs | Not via OTLP | stdout (zap JSON) | No OTLP export |

Both traces and metrics are flowing and cover the same operational domain (TaskRun/PipelineRun lifecycle). This is genuinely two complementary signals.

##### Cross-signal correlation

- **Trace-to-log correlation**: No `traceId` or `spanId` in logs (logs not OTLP-exported; stdout logs may contain trace context in JSON fields but this was not verified as no OTLP log export exists)
- **Trace-to-metric correlation**: Metrics do not carry `trace_id` or `span_id` attributes (expected for aggregated metrics). However, both signals share `namespace` and `task`/`pipeline` labels, enabling indirect correlation via label matching.
- **No exemplars**: No trace exemplars on histogram metrics (which would link specific histogram samples to trace IDs).

##### Collection model

- **Traces**: OTLP push (controller → collector gRPC 4317)
- **Metrics**: Prometheus pull (collector scrapes controller:9090 every 15s)
- **Logs**: Not collected via OTel pipeline

The mixed push/pull model means there is no unified collection configuration — operators must configure both OTLP endpoint and Prometheus scrape separately.

##### Metric coverage

Tekton-native metrics cover the key operational dimensions:
- Duration histograms for TaskRuns and PipelineRuns (by namespace, status, task/pipeline name)
- Running counts (gauges for active runs)
- Total counts (counters by status)
- Pod scheduling latency (`taskruns_pod_latency_milliseconds`)
- Resolution wait metrics (waiting on pipeline/task resolution)

Infrastructure metrics (workqueue, k8s client, Go runtime) are also present via the knative/otelhttp instrumentation layer.

#### Checklist assessment

- ✅ Two signals (traces + metrics) are flowing and cover the same operational domain
- ✅ Metrics have meaningful labels enabling correlation with trace context (namespace, task name)
- ✅ Metrics cover both performance (duration histograms) and availability (running counts, totals)
- ❌ No OTLP log export — log signal is missing from the OTel pipeline
- ❌ No trace exemplars on histogram metrics
- ❌ No `traceId` on log records
- ❌ Mixed push/pull collection model requires separate configuration
- ❌ OTLP metrics export requires opt-in (default is Prometheus)

#### Rationale

Level 2: Two signals are genuinely flowing and are operationally useful. The absence of log export and lack of cross-signal exemplar linking prevent Level 3. The project has the infrastructure for all three signals but has not completed the log signal integration.

---

### 6. Audience & Signal Quality

**Level: 2 — Operator-Useful Telemetry**

#### Evidence

##### Span naming

Span names are logical and meaningful to an operator:
- `PipelineRun:Reconciler`, `TaskRun:Reconciler` — clear entry points
- `createTaskRun`, `createTaskRuns`, `createPod` — meaningful k8s operations
- `resolvePipelineState`, `runNextSchedulableTask` — domain-relevant operations
- `finishReconcileUpdateEmitEvents`, `durationAndCountMetrics` — operational lifecycle steps

These are not raw Go function names (e.g., `reconcileImpl` or `handleErr`) but rather descriptive operation labels. An operator can understand what a trace shows without reading source code.

##### Signal-to-noise ratio

**Traces**: Each reconciliation loop produces a focused, bounded trace. No excessive span noise observed. The `durationAndCountMetrics` span (a span for recording metrics within a reconciliation) is an unusual pattern — it represents an internal implementation detail rather than a user-visible operation.

**Metrics**: 11 Tekton-native metrics, all with descriptions. Additionally, knative infrastructure metrics (`kn_workqueue_*`, `kn_webhook_*`) and standard Go/HTTP metrics are present. The signal-to-noise ratio is good — all Tekton-prefixed metrics are meaningful operational signals.

Metric descriptions are present (e.g., `"The taskrun's execution time in seconds"`, `"Number of pipelineruns executing currently"`).

##### Default usability

- **Traces**: Disabled by default (`tracing-protocol: none`). Operators must explicitly enable. This is a deliberate choice that avoids unexpected overhead but means traces are not available out-of-the-box.
- **Metrics**: Enabled by default on Prometheus port 9090. Operators can immediately scrape metrics without any configuration changes.
- **Documentation**: `docs/metrics.md` documents all metrics with types, labels, and status. `docs/metrics-migration-otel.md` documents the OTel migration with before/after tables. This is strong documentation for operators.

##### Missing granularity

The most significant quality gap is the absence of step-level tracing. A TaskRun executes multiple Steps (containers), but there are no spans for individual step execution. An operator cannot use traces to understand which step in a multi-step Task is slow. This is a significant gap for a CI/CD system where step-level performance visibility is critical.

#### Checklist assessment

- ✅ Span names are logical operations, not raw code paths
- ✅ Metrics have descriptions
- ✅ Metrics documentation is comprehensive (`docs/metrics.md`)
- ✅ Migration documentation is thorough (`docs/metrics-migration-otel.md`)
- ✅ Metrics are available by default (Prometheus)
- ❌ Traces are disabled by default (must opt-in)
- ❌ No step-level spans for Task step execution
- ❌ `durationAndCountMetrics` span represents internal implementation detail
- ❌ Metrics are marked "experimental" — no stability guarantees
- ❌ Instrumentation scope version is `unknown` (makes SDK version opaque to users)

#### Rationale

Level 2: Tekton's telemetry is genuinely useful for operators. The span naming is thoughtful, metrics are comprehensive and documented, and the migration guide is exemplary. The gaps are the absence of step-level tracing (the most operationally valuable signal for CI/CD) and the fact that traces are opt-in. A Level 3 rating would require step-level spans and traces enabled by default.

---

### 7. Stability & Change Management

**Level: 2 — Breaking Changes Documented**

#### Evidence

##### Documentation of telemetry behavior

- `docs/metrics.md`: Comprehensive table of all metrics with types, labels, and status ("experimental" for all)
- `docs/metrics-migration-otel.md`: Dedicated migration guide for the OpenCensus → OpenTelemetry migration, including before/after tables for every changed metric, configuration changes, dashboard update guidance, and a FAQ
- `config/config-observability.yaml`: Inline documentation of all configuration options with comments

The tracing configuration is less well-documented — `config-tracing.yaml` only shows an example pointing to Jaeger; the `config-observability` tracing options are documented inline in the ConfigMap but not in a standalone doc page.

##### Change communication

The OTel migration (OpenCensus → OTel SDK) was a **breaking change** that was:
1. Documented in a dedicated `metrics-migration-otel.md` file
2. Explicitly labeled as "BREAKING CHANGE" with "Action Required"
3. Organized with impact levels (HIGH/MEDIUM/LOW) per category
4. Includes a quick-reference checklist for operators

This is exemplary breaking-change communication for a telemetry migration.

##### Schema URL presence

- **Traces**: `https://opentelemetry.io/schemas/1.12.0` — present but stale (2022 version; current is 1.29.0+)
- **Metrics**: `https://opentelemetry.io/schemas/1.18.0` — present but stale
- **Logs**: N/A (no OTLP export)

Schema URLs are set, which is positive, but they are pinned to old versions and not updated as the OTel spec evolves.

##### Stability guarantees

All metrics are explicitly marked "experimental" in `docs/metrics.md`. This is honest but means no stability guarantees are made. There is no `stable` or `deprecated` status for any metric.

No explicit stability guarantees for trace span names or attributes are documented.

#### Checklist assessment

- ✅ Breaking telemetry changes are documented with a dedicated migration guide
- ✅ Metrics are documented with types, labels, and status
- ✅ Schema URL is present in both trace and metric exports
- ✅ Configuration options are documented inline in ConfigMaps
- ❌ All metrics are "experimental" — no stable telemetry contract
- ❌ Schema URLs are stale (1.12.0, 1.18.0 vs current 1.29.0+)
- ❌ No stability documentation for trace span names or attributes
- ❌ No CHANGELOG entries specifically tracking telemetry changes (v1.11.1 release notes have no OTel mentions)
- ❌ Tracing configuration is less well-documented than metrics

#### Rationale

Level 2: The OTel migration guide is a genuinely strong piece of breaking-change documentation that earns this level. The schema URL presence (even if stale) shows intentionality. The gaps are the "experimental" status of all metrics (no stable contract), stale schema URLs, and the absence of tracing documentation comparable to the metrics docs.

---

## Key findings

### Strengths

1. **Genuine OTel SDK adoption**: Tekton has fully migrated from OpenCensus to the OpenTelemetry SDK (`go.opentelemetry.io/otel`), supporting OTLP gRPC/HTTP for both traces and metrics. This is a real, working integration — not just a Prometheus endpoint relabeled.

2. **Rich reconciler trace hierarchy**: The span tree for PipelineRun and TaskRun reconciliation is well-structured, uses logical operation names, and correctly models parent-child relationships. The `spanContext` persistence in k8s object status is an innovative approach to bridging reconciliation loop boundaries.

3. **Exemplary breaking-change documentation**: The `metrics-migration-otel.md` file is a model of how to communicate telemetry breaking changes — with before/after tables, impact levels, configuration migration steps, dashboard update guidance, and a FAQ.

4. **Comprehensive metrics coverage**: 11 Tekton-specific metrics covering duration histograms, running counts, totals, and scheduling latency — all with descriptions and configurable label granularity.

5. **Infrastructure metrics via otelhttp**: The HTTP client/server instrumentation uses current stable OTel semantic conventions (`http_request_method`, `http_response_status_code`, `server_address`), demonstrating awareness of current semconv.

### Areas for improvement

1. **Add step-level spans**: The highest-value improvement for a CI/CD system. Each Task step (container) should produce a span, enabling operators to identify which step is slow, failing, or causing latency. This would transform traces from "controller visibility" to "pipeline execution visibility."

2. **Adopt OTel semantic conventions for span attributes**: Replace custom keys (`taskrun`, `pipelinerun`, `namespace`) with OTel-aligned names. Propose a `tekton.*` namespace in the OTel semantic conventions (e.g., `tekton.taskrun.name`, `tekton.pipeline.name`, `k8s.namespace.name`). Set `service.version` in resource attributes.

3. **Support `OTEL_*` environment variables**: Allow operators to configure `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES` as standard env vars. This enables standard operator tooling (e.g., OTel Operator auto-instrumentation injection) and follows OTel SDK conventions.

4. **Enable OTLP traces by default** (or provide a helm/manifest flag): Traces being disabled by default means most Tekton deployments have no trace data. Even a low-overhead sampling default (e.g., 10%) would dramatically improve operator visibility.

5. **Add OTLP log export**: Emit structured logs via OTLP to enable cross-signal correlation. At minimum, inject `trace_id` and `span_id` into stdout JSON log lines so log aggregators can correlate with traces.

6. **Update schema URLs and set instrumentation scope versions**: Bump schema URLs from 1.12.0/1.18.0 to the current version. Set `version` on instrumentation scopes (`PipelineRunReconciler`, `TaskRunReconciler`) to the Tekton release version.

### Notable observations

- **Two overlapping tracing configuration mechanisms**: Both `config-tracing` (HTTP-only, legacy Jaeger-focused) and `config-observability` (gRPC/HTTP, newer) exist simultaneously. The `config-observability` `tracing-protocol: grpc` is what actually works for OTLP gRPC. This dual-config is confusing and should be consolidated.

- **Metrics scope name `tekton_pipelines_controller`**: The instrumentation scope for Prometheus-scraped Tekton metrics is `tekton_pipelines_controller` (no version). This is a Prometheus-era artifact — the scope name doesn't align with the service identity used in traces (`pipelinerun-reconciler`, `taskrun-reconciler`).

- **`durationAndCountMetrics` span**: Recording metrics inside a span is an unusual pattern that exposes implementation details. This span should either be removed or renamed to something more meaningful.

- **All metrics are "experimental"**: Despite being stable, well-understood metrics in production use for years, Tekton marks all metrics as "experimental." This creates unnecessary uncertainty for operators building dashboards and alerts.

---

## Methodology notes

- Telemetry was collected using an OpenTelemetry Collector (v0.150.1) with file exporter in a kind cluster
- The `k8sattributes` processor was used; native vs enriched attributes were distinguished by examining what the project sets before enrichment
- Tekton v1.11.1 was installed via official release manifest and configured with `tracing-protocol: grpc` pointing to the collector
- 5 TaskRuns and 2 PipelineRuns were executed to generate reconciliation telemetry
- Semantic conventions were checked against OTel specification (current stable: 1.29.0+)
- Source code and documentation were reviewed at the `v1.11.1` git tag

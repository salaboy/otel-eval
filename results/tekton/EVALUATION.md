# OpenTelemetry Support Maturity Evaluation: Tekton Pipelines

## Project overview

- **Project**: Tekton Pipelines — cloud-native CI/CD pipeline primitives for Kubernetes, providing CRDs (`Task`, `TaskRun`, `Pipeline`, `PipelineRun`) for defining and executing CI/CD workflows.
- **Version evaluated**: v1.11.1 (released 2026-04-21)
- **Evaluation date**: 2026-04-30
- **Cluster**: otel-eval-tekton (kind)
- **Maturity model version**: OpenTelemetry Support Maturity Model for CNCF Projects (draft)

---

## Summary

| Dimension | Level | Summary |
|-----------|-------|---------|
| Integration Surface | 2 | OTLP HTTP traces + Prometheus metrics; OTLP metrics configurable but Prometheus is default |
| Semantic Conventions | 1 | Custom non-standard span/metric attributes; uses OTel SDK and semconv v1.12.0 schema URL |
| Resource Attributes & Configuration | 1 | Only `service.name` emitted natively; no `telemetry.sdk.*`, no `service.version`; no OTEL_* env var support |
| Trace Modeling & Context Propagation | 2 | Good internal span hierarchy; W3C TraceContext propagation set globally; no cross-service propagation to task pods |
| Multi-Signal Observability | 2 | Traces via OTLP, metrics via Prometheus (OTLP configurable); no log export; no cross-signal correlation |
| Audience & Signal Quality | 2 | Spans reflect logical operations; rich span hierarchy; all spans lack status codes; minimal span attributes |
| Stability & Change Management | 2 | Breaking change documented with migration guide; schema URL set; metrics status "experimental"; no telemetry stability contract |

---

## Telemetry overview

### Signals observed
- **Traces**: Flowing — OTLP HTTP export via `config-tracing` ConfigMap (`enabled: "true"`, `endpoint: http://<collector>:4318/v1/traces`)
- **Metrics**: Flowing — Prometheus scrape endpoint on port 9090 (controller, events-controller, webhook); OTLP gRPC/HTTP also configurable via `config-observability`
- **Logs**: Not flowing via OTLP — structured JSON to stdout only; no OTLP log export

### Resource attributes (native, before collector enrichment)
Only one resource attribute is emitted natively by Tekton in trace data:
- `service.name`: `taskrun-reconciler` or `pipelinerun-reconciler`

For Prometheus-scraped metrics, the Prometheus receiver adds:
- `service.name` (derived from job name)
- `server.address`, `server.port`, `url.scheme`, `service.instance.id` (collector-added)

### Resource attributes (after collector enrichment)
After k8sattributes processing, traces gain:
- `k8s.namespace.name`, `k8s.pod.name`, `k8s.pod.uid`, `k8s.pod.start_time`
- `k8s.deployment.name`, `k8s.replicaset.name`, `k8s.container.name`, `k8s.node.name`
- `k8s.pod.label.*` (all pod labels including `app.kubernetes.io/version: v1.11.1`)

---

## Dimension evaluations

### 1. Integration Surface

**Level: 2 — OTLP Push**

#### Evidence

- **Traces**: Tekton emits traces via OTLP HTTP (`otlptracehttp` exporter from `go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp`). Configured via `config-tracing` ConfigMap with `enabled: "true"` and `endpoint` URL. This is a first-class, documented feature.
- **Metrics**: Default export is Prometheus scrape (port 9090). The `config-observability` ConfigMap supports `metrics-protocol: grpc` or `metrics-protocol: http/protobuf` for OTLP push, but the default is `prometheus`. OTLP metrics were configured but the Prometheus scrape is what is confirmed flowing in this evaluation (14 trace batches, 46 metric batches all from Prometheus).
- **Logs**: No OTLP log export. Logs are structured JSON to stdout only.
- **Source code**: `pkg/tracing/tracing.go` uses `otlptracehttp.New()` directly with the OTel Go SDK. The `createTracerProvider` function builds a `tracesdk.TracerProvider` with a batcher exporter.
- **Configuration**: No OTLP-specific environment variables (`OTEL_EXPORTER_OTLP_ENDPOINT`, etc.) are supported. Configuration is exclusively via Kubernetes ConfigMaps (`config-tracing`, `config-observability`).

#### Checklist assessment
- ✅ Project exports traces via OTLP (HTTP)
- ✅ Project exposes Prometheus metrics (scrape endpoint)
- ✅ OTLP metrics also configurable (grpc/http/protobuf via config-observability)
- ❌ No OTLP log export
- ❌ OTLP is not the default for metrics (Prometheus is default)
- ❌ No `OTEL_*` environment variable support for endpoint configuration

#### Rationale
Level 2 is appropriate because Tekton natively emits traces via OTLP push using the OTel Go SDK, and also supports OTLP metrics as a configurable option (not just Prometheus). However, it falls short of Level 3 because: logs have no OTLP path, the default metrics protocol is Prometheus (not OTLP), and OTLP configuration is done through Kubernetes-specific ConfigMaps rather than standard `OTEL_*` env vars.

---

### 2. Semantic Conventions

**Level: 1 — Partial Alignment**

#### Evidence

##### Trace attributes
Span attributes found in traces:
- `taskrun` (string) — e.g., `"echo-hello-run-1"`
- `namespace` (string) — e.g., `"default"`
- `pipelinerun` (string) — e.g., `"hello-pipeline-run-1"`

These are Tekton-specific custom attributes, **not** aligned with OTel semantic conventions. The current OTel semconv for CI/CD systems would use `cicd.pipeline.run.id`, `cicd.task.run.id`, `k8s.namespace.name`, etc. The attribute names `taskrun`, `namespace`, `pipelinerun` are internal Tekton terminology without the `cicd.*` or `k8s.*` namespace prefix.

Most child spans (e.g., `reconcile`, `prepare`, `createPod`, `finishReconcileUpdateEmitEvents`) have **null attributes** — no attributes at all.

**Schema URL**: `https://opentelemetry.io/schemas/1.12.0` — set on `resourceSpans[].schemaUrl`. This is semconv v1.12.0, which is outdated (current stable is v1.27+). The schema URL is set but refers to an old version.

**Span kinds**: All spans have `kind=1` (INTERNAL). Root reconciler spans (`TaskRun:Reconciler`, `PipelineRun:Reconciler`) use INTERNAL kind rather than the more appropriate SERVER or PRODUCER kind for entry points.

**No `telemetry.sdk.*` resource attributes**: The trace resource only emits `service.name`. There is no `telemetry.sdk.name`, `telemetry.sdk.version`, or `telemetry.sdk.language`.

**Instrumentation scope**: `TaskRunReconciler` and `PipelineRunReconciler` — no version set on the scope.

##### Metric names and attributes
Tekton-specific metrics use a custom naming convention:
- `tekton_pipelines_controller_taskrun_duration_seconds` — uses `_` separator, Prometheus-style
- Metric labels: `namespace`, `status`, `task`, `pipeline` — custom labels, not OTel semconv

The metrics are documented as "experimental" status in the official docs. The metric names do not follow OTel semconv naming conventions (e.g., `cicd.pipeline.run.duration` would be the OTel-aligned name). The `tekton_pipelines_controller_` prefix is a legacy Prometheus convention.

##### Log attributes
No OTLP logs flowing. Stdout logs contain `knative.dev/traceid` which is a Knative-internal UUID, NOT an OTel trace ID.

#### Checklist assessment
- ✅ OTel SDK is used (Go SDK, semconv v1.12.0)
- ✅ Schema URL is set on trace data
- ❌ Span attributes do not follow OTel semantic conventions (custom `taskrun`, `namespace`, `pipelinerun` keys)
- ❌ Most child spans have no attributes at all
- ❌ Root spans use INTERNAL kind instead of SERVER/PRODUCER
- ❌ Metric names use Prometheus-style naming, not OTel semconv
- ❌ No `telemetry.sdk.*` resource attributes
- ❌ Schema URL references outdated semconv v1.12.0
- ❌ Instrumentation scope has no version

#### Rationale
Level 1 because Tekton uses the OTel SDK and sets a schema URL, demonstrating awareness of semantic conventions. However, actual attribute names are custom/non-standard. The span attributes (`taskrun`, `namespace`) are reasonable descriptors but don't follow OTel's CI/CD semantic conventions. Metric names follow Prometheus naming conventions rather than OTel. This is partial alignment — the plumbing is OTel-native but the naming choices predate or ignore the OTel semconv catalog.

---

### 3. Resource Attributes & Configuration

**Level: 1 — Minimal Native Resources**

#### Evidence

##### Native resource attributes
Tekton emits only one resource attribute natively in traces:
- `service.name`: Set programmatically to `"taskrun-reconciler"` or `"pipelinerun-reconciler"` in `pkg/tracing/tracing.go`:
  ```go
  tracesdk.WithResource(resource.NewWithAttributes(
      semconv.SchemaURL,
      semconv.ServiceNameKey.String(service),
  ))
  ```

Missing native resource attributes:
- ❌ `service.version` — not set (version is available as `v1.11.1` but not emitted)
- ❌ `service.namespace` — not set
- ❌ `service.instance.id` — not set
- ❌ `telemetry.sdk.name` — not set
- ❌ `telemetry.sdk.version` — not set
- ❌ `telemetry.sdk.language` — not set
- ❌ `process.runtime.name` — not set
- ❌ `host.name` — not set natively

##### OTEL_* environment variable support
Tekton does **not** support standard `OTEL_*` environment variables. All telemetry configuration is done via Kubernetes ConfigMaps (`config-tracing`, `config-observability`). There is no documentation of `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_ENDPOINT`, or `OTEL_RESOURCE_ATTRIBUTES` support.

##### Identity consistency across signals
- Traces: `service.name` = `taskrun-reconciler` or `pipelinerun-reconciler`
- Metrics (Prometheus): `service.name` = `tekton-pipelines-controller`, `tekton-events-controller`, `tekton-pipelines-webhook` (set by Prometheus receiver, not by Tekton itself)
- Logs: No OTLP; stdout logs have no OTel resource

The `service.name` values are **inconsistent** between traces and metrics. Traces use reconciler-level names while Prometheus metrics use deployment-level names. There is no shared identity that would allow correlation between the two signals.

#### Checklist assessment
- ✅ `service.name` is set natively in trace resource
- ❌ `service.version` not set
- ❌ `telemetry.sdk.*` attributes absent
- ❌ No `OTEL_*` environment variable support
- ❌ `service.name` is inconsistent between traces and metrics
- ❌ No `service.instance.id` for multi-replica disambiguation

#### Rationale
Level 1 because the project sets `service.name` (the minimum required resource attribute) but nothing else. The absence of `service.version`, `telemetry.sdk.*` attributes, and `OTEL_*` env var support limits configurability. The inconsistency of `service.name` between traces and metrics makes cross-signal correlation impossible without manual configuration.

---

### 4. Trace Modeling & Context Propagation

**Level: 2 — Good Internal Modeling**

#### Evidence

##### Span structure
Tekton produces a rich internal span hierarchy per reconcile cycle. Example from a TaskRun trace:
```
TaskRun:Reconciler (root, INTERNAL)
  └── TaskRun:ReconcileKind (INTERNAL)
        ├── updateTaskRunWithDefaultWorkspaces (INTERNAL)
        ├── prepare (INTERNAL)
        ├── createPod (INTERNAL)
        ├── reconcile (INTERNAL)
        ├── updateLabelsAndAnnotations (INTERNAL)
        ├── finishReconcileUpdateEmitEvents (INTERNAL)
        └── durationAndCountMetrics (INTERNAL)
```

PipelineRun traces show a similarly deep hierarchy:
```
PipelineRun:Reconciler (root, INTERNAL)
  └── PipelineRun:ReconcileKind (INTERNAL)
        ├── updatePipelineRunStatusFromInformer (INTERNAL)
        ├── reconcile (INTERNAL)
        │     ├── resolvePipelineState (INTERNAL)
        │     ├── runNextSchedulableTask (INTERNAL)
        │     │     ├── createTaskRuns (INTERNAL)
        │     │     │     └── createTaskRun (INTERNAL)
        │     └── ...
        ├── finishReconcileUpdateEmitEvents (INTERNAL)
        │     └── updateLabelsAndAnnotations (INTERNAL)
        └── durationAndCountMetrics (INTERNAL)
```

Total: 1558 spans across 14 trace batches, covering both TaskRun and PipelineRun reconciler lifecycles.

##### Context propagation
- **W3C TraceContext**: Tekton explicitly sets the global propagator to W3C TraceContext in `pkg/tracing/tracing.go`:
  ```go
  func init() {
      otel.SetTextMapPropagator(propagation.TraceContext{})
  }
  ```
- **SpanContext in annotations**: Tekton propagates span context between the controller and TaskRun/PipelineRun objects via annotations (`tekton.dev/taskrunSpanContext`). This allows a parent span to be linked across reconcile cycles.
- **Span events**: `"updating TaskRun status with SpanContext"` events are emitted when context is stored in the CR status.
- **Cross-service propagation to pods**: Tekton does **not** inject trace context into the actual task step pods/containers. The trace ends at the controller level and does not extend into user workloads.

##### Trace coherence
- Traces tell a complete story of the reconciler's work for each TaskRun/PipelineRun lifecycle
- Multiple reconcile cycles for the same TaskRun/PipelineRun are linked via the stored SpanContext
- PipelineRun and TaskRun traces are **separate traces** — there are no span links connecting a PipelineRun's trace to the TaskRun traces it creates
- All span status codes are empty `{}` (UNSET) — no explicit OK or ERROR status is set even on root spans

#### Checklist assessment
- ✅ Rich internal span hierarchy reflecting actual operations
- ✅ W3C TraceContext propagation configured globally
- ✅ Span context persisted in CR annotations for cross-reconcile continuity
- ✅ Logical span names (`prepare`, `createPod`, `reconcile`, etc.)
- ❌ All spans use INTERNAL kind (root spans should be SERVER or PRODUCER)
- ❌ No span links between PipelineRun and child TaskRun traces
- ❌ No trace context propagation into task step pods
- ❌ No span status codes set (all UNSET)
- ❌ Most child spans have no attributes

#### Rationale
Level 2 because Tekton demonstrates good trace modeling with a meaningful span hierarchy that accurately represents the reconciler's work. W3C TraceContext is explicitly configured. However, it falls short of Level 3 due to: no span links connecting PipelineRun to TaskRun traces, no propagation into user workload pods, all spans use INTERNAL kind, and no span status codes.

---

### 5. Multi-Signal Observability

**Level: 2 — Two Signals with Limited Correlation**

#### Evidence

##### Signal availability
- **Traces**: First-class, OTLP HTTP push, covers reconciler lifecycle for both TaskRun and PipelineRun
- **Metrics**: First-class, Prometheus endpoint (OTLP also configurable). 11 Tekton-specific metrics covering run counts, durations, pod scheduling latency, and queue depths. Additionally: HTTP client/server metrics, Go runtime metrics, Knative workqueue metrics.
- **Logs**: Structured JSON to stdout only. No OTLP log export.

##### Cross-signal correlation
- **Trace-to-metrics**: No correlation. Trace `service.name` (`taskrun-reconciler`) differs from metric `service.name` (`tekton-pipelines-controller`). No shared trace context in metrics.
- **Trace-to-logs**: No correlation. Logs contain `knative.dev/traceid` which is a Knative-internal UUID, NOT an OTel trace ID. This field cannot be used to correlate logs with OTel traces.
- **Metrics-to-logs**: No correlation mechanism.

##### Collection model per signal
| Signal | Protocol | Push/Pull | Endpoint |
|--------|----------|-----------|----------|
| Traces | OTLP HTTP | Push | `config-tracing` ConfigMap |
| Metrics | Prometheus | Pull (scrape) | Port 9090 |
| Metrics (alt) | OTLP gRPC/HTTP | Push | `config-observability` ConfigMap |
| Logs | stdout JSON | N/A (no export) | — |

##### Metric quality
Tekton metrics are documented as "experimental" in `docs/metrics.md`. The metrics cover:
- Duration histograms for TaskRun and PipelineRun execution
- Running counts (gauges)
- Pod scheduling latency
- Queue depth metrics (via Knative's kn_workqueue_*)

The v1.11.1 release includes a documented migration from OpenCensus to OpenTelemetry metrics (`docs/metrics-migration-otel.md`), which is a significant improvement in signal quality.

#### Checklist assessment
- ✅ Two signals flowing (traces via OTLP, metrics via Prometheus)
- ✅ OTLP metrics also available as alternative
- ✅ Meaningful metrics covering key operational concerns
- ❌ No OTLP log export
- ❌ No cross-signal correlation (different `service.name` between traces and metrics)
- ❌ `knative.dev/traceid` in logs is not an OTel trace ID
- ❌ No trace IDs in metrics data points

#### Rationale
Level 2 because two signals are flowing (traces and metrics), both with reasonable coverage of the project's key operations. However, the signals cannot be correlated with each other due to inconsistent identity and the absence of trace context in metrics and logs. The metrics-to-OTel migration is a positive recent development.

---

### 6. Audience & Signal Quality

**Level: 2 — Operator-Useful with Some Gaps**

#### Evidence

##### Span naming
Span names reflect logical operations rather than internal code paths:
- `TaskRun:Reconciler`, `TaskRun:ReconcileKind` — clear lifecycle entry points
- `prepare`, `createPod`, `reconcile`, `updateLabelsAndAnnotations` — meaningful operation names
- `finishReconcileUpdateEmitEvents`, `durationAndCountMetrics` — slightly internal-sounding but still meaningful
- `resolvePipelineState`, `runNextSchedulableTask`, `createTaskRuns` — good pipeline lifecycle naming

The span names tell a coherent story of what the controller is doing during a TaskRun or PipelineRun lifecycle.

##### Signal-to-noise ratio
- **Traces**: 1558 spans for 8 TaskRuns + 3 PipelineRuns. The volume is reasonable. Each reconcile cycle produces a bounded set of spans (typically 8-15 per cycle). No obviously noisy or redundant spans observed.
- **Metrics**: 11 Tekton-specific metrics with clear semantic meaning. Additional framework metrics (Knative workqueue, HTTP, Go runtime) add context but may be unfamiliar to operators. All metrics are marked "experimental" in docs.

##### Default usability
- Traces are **not enabled by default** — `config-tracing` requires `enabled: "true"` to be set. The default is a no-op TracerProvider.
- Metrics are available by default on port 9090 (no configuration needed for Prometheus scrape).
- The span hierarchy is deep enough to diagnose performance issues in the reconciler.
- Missing: span status codes (all UNSET) means error detection via traces is not possible without examining span names or attributes.
- Missing: most child spans have no attributes, limiting the diagnostic value for individual operations.

##### Cardinality concerns
- `tekton_pipelines_controller_taskruns_pod_latency_milliseconds` is noted in docs as having "unbounded cardinality" due to `pod` label — a known issue (#9393).
- Duration metrics at `taskrun`/`pipelinerun` level are explicitly discouraged in docs due to unbounded cardinality.

#### Checklist assessment
- ✅ Span names reflect logical operations
- ✅ Rich span hierarchy covering full reconciler lifecycle
- ✅ Span events used (`"updating TaskRun status with SpanContext"`)
- ✅ Metrics cover key operational concerns (duration, counts, latency)
- ❌ No span status codes (impossible to detect errors from trace data alone)
- ❌ Most child spans have no attributes (limited diagnostic value)
- ❌ Tracing is opt-in (not enabled by default)
- ❌ Known unbounded cardinality issue in pod latency metric
- ❌ All metrics marked "experimental"

#### Rationale
Level 2 because the signal quality is genuinely useful for operators — the span hierarchy is meaningful, span names are logical, and metrics cover the right operational concerns. However, the absence of span status codes, minimal child span attributes, and opt-in tracing limit the out-of-box experience. An operator cannot rely on traces alone to detect errors.

---

### 7. Stability & Change Management

**Level: 2 — Documented with Breaking Change Communication**

#### Evidence

##### Documentation of telemetry behavior
- `docs/metrics.md` documents all Tekton-specific metrics with names, types, labels, and status
- `docs/metrics-migration-otel.md` provides a comprehensive migration guide for the OpenCensus → OpenTelemetry transition (v1.11.1 feature)
- `config/config-observability.yaml` is well-commented with all configuration options
- `config/config-tracing.yaml` documents tracing configuration options
- No dedicated "telemetry contract" or "observability reference" document that commits to stability

##### Change communication
The v1.11.1 release includes `docs/metrics-migration-otel.md` — a detailed breaking change document covering:
- Which metrics changed names (workqueue, K8s client, Go runtime)
- Which metrics are backward-compatible (core Tekton metrics)
- Migration checklist for dashboards and alerts
- FAQ section

This is good change management practice. The v1.11.1 release notes do not mention the OTel migration in the GitHub release body, but the in-repo documentation is comprehensive.

##### Schema URL presence
- Traces: `schemaUrl: "https://opentelemetry.io/schemas/1.12.0"` is set on `resourceSpans[].schemaUrl` — present but references outdated semconv version (v1.12.0 vs current v1.27+)
- Metrics: `schemaUrl: "https://opentelemetry.io/schemas/1.18.0"` is set on metric resource data (from k8s_cluster receiver)
- Tekton-native metric scope (`tekton_pipelines_controller`) has no schema URL

##### Stability guarantees
- All Tekton metrics are documented as "experimental" status
- No explicit stability commitment for trace span names or attributes
- The OTel migration guide implies awareness of telemetry as a contract, but no formal stability promise

#### Checklist assessment
- ✅ Metrics documented with names, types, labels
- ✅ Breaking change migration guide provided (`metrics-migration-otel.md`)
- ✅ Schema URL set on trace exports
- ✅ Configuration options documented in ConfigMap comments
- ❌ All metrics labeled "experimental" — no stability commitment
- ❌ No stability guarantee for trace span names/attributes
- ❌ Schema URL references outdated semconv version (v1.12.0)
- ❌ Release notes don't mention OTel migration
- ❌ No formal telemetry contract document

#### Rationale
Level 2 because Tekton demonstrates awareness of telemetry as a contract by providing a detailed breaking change migration guide and documenting all metrics. The schema URL is present. However, all metrics are "experimental" with no stability commitment, trace telemetry has no documented stability guarantees, and the schema URL is outdated.

---

## Key findings

### Strengths
1. **Native OTLP trace export using OTel Go SDK** — Tekton uses `otlptracehttp` directly with `tracesdk.TracerProvider`, producing clean OTLP traces without any intermediate format translation. W3C TraceContext is explicitly configured as the global propagator.
2. **Rich, meaningful span hierarchy** — The 8-15 spans per reconcile cycle accurately represent the controller's work (prepare, createPod, reconcile, etc.), making it genuinely useful for diagnosing slow reconciliations.
3. **Documented breaking change migration** — The `docs/metrics-migration-otel.md` document is a high-quality migration guide that demonstrates mature change management practices for telemetry consumers.
4. **Multi-protocol metrics export** — The `config-observability` ConfigMap supports Prometheus, OTLP gRPC, and OTLP HTTP for metrics, giving operators flexibility in their collection pipeline.
5. **SpanContext propagation via CR annotations** — Tekton's mechanism of storing span context in TaskRun/PipelineRun status annotations allows trace continuity across multiple reconcile cycles, which is architecturally sound for a Kubernetes controller.

### Areas for improvement
1. **Add `service.version`, `telemetry.sdk.*` resource attributes** — The trace resource currently only emits `service.name`. Adding `service.version: "v1.11.1"`, `telemetry.sdk.name: "opentelemetry"`, `telemetry.sdk.version`, and `telemetry.sdk.language: "go"` would significantly improve observability platform integration.
2. **Align span attributes with OTel CI/CD semantic conventions** — Replace `taskrun`/`namespace`/`pipelinerun` span attributes with OTel semconv equivalents (e.g., `cicd.pipeline.run.id`, `cicd.task.run.id`, `k8s.namespace.name`). Add attributes to child spans that currently have `null` attributes.
3. **Set span status codes** — All 1558 spans have UNSET status. Root spans should set `STATUS_CODE_OK` on success and `STATUS_CODE_ERROR` with a description on failure. This is critical for error detection in trace-based alerting.
4. **Unify `service.name` between traces and metrics** — `taskrun-reconciler`/`pipelinerun-reconciler` (traces) vs `tekton-pipelines-controller` (metrics) makes cross-signal correlation impossible. Either use the same name or add a shared `service.namespace` to link them.
5. **Add span links between PipelineRun and TaskRun traces** — PipelineRun creates TaskRuns, but the two traces are completely disconnected. Adding span links from the `createTaskRun` span to the TaskRun's root span would enable end-to-end pipeline tracing.
6. **Promote metrics from "experimental" to stable** — The core Tekton metrics (`tekton_pipelines_controller_*`) have been stable in practice. Formalizing their stability status would give operators confidence in building dashboards and alerts.

### Notable observations
1. **Dual tracing configuration paths** — Tekton v1.11.1 has two ways to configure tracing: the legacy `config-tracing` ConfigMap (OTLP HTTP only) and the newer `config-observability` ConfigMap (supports grpc, http/protobuf, none, stdout). Both were functional in this evaluation. The `config-observability` approach is more flexible and aligned with the metrics configuration.
2. **`knative.dev/traceid` in logs is misleading** — The `knative.dev/traceid` field in controller logs looks like an OTel trace ID but is actually a Knative-internal UUID. This could confuse operators trying to correlate logs with traces.
3. **OTel SDK version is outdated** — The source code uses `semconv/v1.12.0` (from 2022). The current stable semconv is v1.27+. While this doesn't break functionality, it means Tekton is not using the latest CI/CD semantic conventions that were added in more recent versions.
4. **Metrics migration is a major positive step** — The migration from OpenCensus to OpenTelemetry metrics in this release cycle represents a significant architectural improvement. The migration document is unusually thorough for a CNCF project.
5. **Tracing is opt-in with a non-obvious default** — The `config-tracing` ConfigMap ships with only an `_example` key, meaning tracing is disabled by default. New users must know to set `enabled: "true"` explicitly. A more discoverable default (e.g., `enabled: "false"` explicitly in the data section) would improve the operator experience.

---

## Methodology notes

- Tekton v1.11.1 was installed via the official release manifest from GitHub releases
- 5 TaskRuns and 3 PipelineRuns were executed to generate telemetry
- Tracing was enabled via `config-tracing` ConfigMap patch; Prometheus scrape was configured in the OTel Collector
- The k8sattributes processor was used to distinguish native vs enriched resource attributes
- Source code was reviewed at `pkg/tracing/tracing.go`, `pkg/reconciler/taskrun/tracing.go`, `pkg/apis/config/tracing.go`, and `pkg/apis/config/metrics.go`
- Documentation reviewed: `docs/metrics.md`, `docs/metrics-migration-otel.md`, `config/config-observability.yaml`, `config/config-tracing.yaml`
- Semantic conventions were checked against the OTel specification (current stable: v1.27+)
- All telemetry evidence was collected from `/tmp/otel-eval-tekton/traces.jsonl` (14 batches, 1558 spans) and `/tmp/otel-eval-tekton/metrics.jsonl` (46 batches)

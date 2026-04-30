# OpenTelemetry Support Maturity Evaluation: Tekton Pipelines

## Project overview

- **Project**: Tekton Pipelines — a Kubernetes-native CI/CD framework providing CRDs (Task, Pipeline, TaskRun, PipelineRun) for building, testing, and deploying applications. The controller runs in `tekton-pipelines` namespace and reconciles these CRDs.
- **Version evaluated**: v1.11.1
- **Evaluation date**: 2026-04-30
- **Cluster**: otel-eval-tekton
- **Maturity model version**: OpenTelemetry Support Maturity Model for CNCF Projects (draft)

## Summary

| Dimension | Level | Summary |
|-----------|-------|---------|
| Integration Surface | 3 | OTLP gRPC/HTTP push for both traces and metrics; Prometheus also supported; configurable via ConfigMap |
| Semantic Conventions | 2 | OTel semconv for Go runtime and HTTP client metrics; custom Prometheus-style naming for core Tekton metrics; schema URL set |
| Resource Attributes & Configuration | 2 | `service.name`, `service.version`, `telemetry.sdk.*` set natively in OTLP push; no `OTEL_*` env var support documented |
| Trace Modeling & Context Propagation | 2 | Rich internal reconciler traces with parent-child hierarchy; context stored in K8s annotations; no external propagation |
| Multi-Signal Observability | 2 | Traces (OTLP) and metrics (OTLP or Prometheus) flowing; logs structured JSON to stdout only; trace IDs in logs |
| Audience & Signal Quality | 2 | Traces model internal reconciler operations clearly; metrics labeled with Tekton-domain concepts; some child spans lack attributes |
| Stability & Change Management | 2 | Well-documented migration guide (OpenCensus → OTel); metrics labeled "experimental"; schema URL present; no explicit stability SLO |

## Telemetry overview

### Signals observed
- **Traces**: Flowing — OTLP gRPC push from controller (service names: `pipelinerun-reconciler`, `taskrun-reconciler`)
- **Metrics**: Flowing — OTLP gRPC push (when configured) OR Prometheus scrape from port 9090; 11 Tekton-native metrics + Go runtime + Knative workqueue metrics
- **Logs**: Not via OTLP — structured JSON to stdout via zap logger; include `knative.dev/traceid` field for correlation

### Resource attributes (native, before collector enrichment)

**Traces (OTLP push):**
- `service.name`: `pipelinerun-reconciler` or `taskrun-reconciler`
- *(Note: no `service.version`, `telemetry.sdk.*` in traces — only in OTLP metrics push)*

**Metrics (OTLP push):**
- `service.name`: `tekton-pipelines-controller`
- `service.version`: `5a88281` (git commit SHA)
- `telemetry.sdk.name`: `opentelemetry`
- `telemetry.sdk.language`: `go`
- `telemetry.sdk.version`: `1.42.0`

### Resource attributes (after collector enrichment)
After k8sattributes processing, both signals gain:
- `k8s.pod.name`, `k8s.pod.uid`, `k8s.pod.start_time`
- `k8s.namespace.name`, `k8s.deployment.name`, `k8s.replicaset.name`, `k8s.node.name`
- `k8s.container.name`
- All pod labels (`k8s.pod.label.*`) and annotations (`k8s.pod.annotation.*`)

---

## Dimension evaluations

### 1. Integration Surface

**Level: 3 — OTLP Native with Flexibility**

#### Evidence

1. **OTLP gRPC push confirmed working** for both traces and metrics when configured:
   - Traces: `tracing-protocol: grpc` + `tracing-endpoint: <collector>:4317`
   - Metrics: `metrics-protocol: grpc` + `metrics-endpoint: http://<collector>:4317`

2. **OTLP HTTP also supported**: `metrics-protocol: http/protobuf` and `tracing-protocol: http/protobuf` are documented and implemented.

3. **Prometheus also supported** (default): `metrics-protocol: prometheus` exposes port 9090 with `/metrics` endpoint.

4. **Configuration mechanism**: `config-observability` ConfigMap in `tekton-pipelines` namespace — no restart required for ConfigMap changes (controller watches it), though we observed a restart was needed in practice for the OTLP endpoint URL.

5. **Legacy `config-tracing` ConfigMap** also exists for HTTP-based tracing (older mechanism), now superseded by `config-observability`.

6. **Documentation**: Official docs at `tekton.dev/docs/pipelines/metrics/` clearly documents all three protocols. A dedicated migration guide (`metrics-migration-otel.md`) explains the OpenCensus → OpenTelemetry transition.

7. **TLS note**: Initial OTLP gRPC config without `http://` prefix failed with TLS handshake error, requiring `http://` prefix for insecure mode. This is a minor usability gap but the feature works once properly configured.

#### Checklist assessment
- ✅ OTLP is a supported export path (not just Prometheus)
- ✅ Both gRPC and HTTP/protobuf OTLP endpoints supported
- ✅ Configuration is documented and first-class
- ✅ Prometheus also supported as alternative
- ✅ No sidecar or agent required for OTLP push
- ⚠️ Default is Prometheus (not OTLP) — operator must explicitly configure OTLP
- ⚠️ Tracing is disabled by default (`tracing-protocol: none`)

#### Rationale
Level 3: Tekton supports OTLP push natively for both traces and metrics via a well-documented ConfigMap mechanism. Multiple protocols are supported (gRPC, HTTP, Prometheus). The only gap from a perfect integration story is that OTLP is not the default — Prometheus is — but the OTLP path is fully functional, documented, and requires only a ConfigMap change.

---

### 2. Semantic Conventions

**Level: 2 — Partial Alignment**

#### Evidence

##### Trace attributes
- **Span names**: `PipelineRun:Reconciler`, `PipelineRun:ReconcileKind`, `TaskRun:Reconciler`, `TaskRun:ReconcileKind`, `reconcile`, `resolvePipelineState`, `createTaskRuns`, `createTaskRun`, `createPod`, `prepare`, `updateLabelsAndAnnotations`, `finishReconcileUpdateEmitEvents`, `durationAndCountMetrics`, `stopSidecars`, `updatePipelineRunStatusFromInformer`, `updateTaskRunWithDefaultWorkspaces`, `runNextSchedulableTask`
- **Span attributes on root spans**: `pipelinerun`/`taskrun` (Tekton-domain, not OTel semconv) and `namespace`
- **Child spans**: No attributes at all
- **Span kind**: All spans use `kind=1` (INTERNAL) — correct for internal reconciler operations
- **Status**: All `UNSET` — no error status set even for failed operations
- **Schema URL**: `https://opentelemetry.io/schemas/1.12.0` set on trace resource (outdated — current is 1.40.0)
- **Instrumentation scope**: `PipelineRunReconciler`, `TaskRunReconciler` — no version set on scope

##### Metric names and attributes (Tekton-native)
Core Tekton metrics use Prometheus-style naming (not OTel semconv):
- `tekton_pipelines_controller_pipelinerun_duration_seconds` — follows `<project>_<component>_<operation>_<unit>` Prometheus convention
- Labels: `namespace`, `pipeline`, `status`, `task` — Tekton-domain, not OTel semconv

Infrastructure metrics (from OTLP push) **do** follow OTel semconv:
- `go.goroutine.count`, `go.memory.used`, `go.config.gogc` — OTel Go runtime semconv
- `http.client.request.duration` — OTel HTTP client semconv
- Attributes: `http.request.method`, `server.address`, `server.port`, `url.scheme`, `url.template` — current OTel semconv ✅

##### Log attributes
- No OTLP log export; logs are structured JSON to stdout
- Log fields: `severity`, `timestamp`, `logger`, `caller`, `message`, `commit`, `knative.dev/traceid`, `knative.dev/key`, `duration`
- Not OTel semconv (Knative-native fields)

#### Checklist assessment
- ✅ OTel semconv used for Go runtime metrics (`go.*`)
- ✅ OTel semconv used for HTTP client metrics (`http.client.request.duration`, `http.request.method`, etc.)
- ✅ Schema URL set on traces (though outdated: 1.12.0 vs current 1.40.0)
- ⚠️ Core Tekton metrics (`tekton_pipelines_controller_*`) use Prometheus-style naming, not OTel semconv
- ⚠️ Trace span attributes are minimal (only `pipelinerun`/`taskrun` + `namespace` on root spans; nothing on child spans)
- ⚠️ `service.name` in traces uses `pipelinerun-reconciler` / `taskrun-reconciler` — not standard `service.name` format
- ❌ No `service.version` in traces resource
- ❌ Instrumentation scope has no version
- ❌ No error status set on spans for failed operations

#### Rationale
Level 2: Tekton demonstrates good semconv alignment for infrastructure metrics (Go runtime, HTTP client) using current OTel naming. However, the core Tekton-domain metrics retain Prometheus-style naming, and traces have minimal attribute coverage with no OTel semconv span attributes. The schema URL is present but outdated. This represents intentional partial alignment — infrastructure follows OTel semconv while domain metrics retain Prometheus compatibility.

---

### 3. Resource Attributes & Configuration

**Level: 2 — Consistent with Gaps**

#### Evidence

##### Native resource attributes (OTLP push metrics)
The controller natively sets:
- `service.name`: `tekton-pipelines-controller` ✅
- `service.version`: `5a88281` (git commit SHA, not semantic version like `v1.11.1`) ⚠️
- `telemetry.sdk.name`: `opentelemetry` ✅
- `telemetry.sdk.language`: `go` ✅
- `telemetry.sdk.version`: `1.42.0` ✅

##### Native resource attributes (OTLP push traces)
- `service.name`: `pipelinerun-reconciler` or `taskrun-reconciler` ⚠️ (inconsistent with metrics service name)
- No `service.version`, no `telemetry.sdk.*` in traces

##### OTEL_* environment variable support
- Not documented in Tekton's official docs
- Tekton uses a ConfigMap-based configuration model, not `OTEL_*` env vars
- The underlying Go OTel SDK may respect `OTEL_*` env vars, but this is not a documented or supported interface

##### Identity consistency across signals
- **Traces**: `service.name` = `pipelinerun-reconciler` or `taskrun-reconciler`
- **Metrics**: `service.name` = `tekton-pipelines-controller`
- **Inconsistency**: Traces and metrics use different service names — operators cannot trivially correlate them by `service.name`

##### Schema URL
- Traces: `https://opentelemetry.io/schemas/1.12.0` (outdated)
- Metrics (OTLP push): `https://opentelemetry.io/schemas/1.40.0` (current)

#### Checklist assessment
- ✅ `service.name` set natively in both traces and metrics
- ✅ `telemetry.sdk.*` set in OTLP metrics push
- ✅ `service.version` set in metrics (commit SHA)
- ⚠️ `service.name` is inconsistent between traces (`pipelinerun-reconciler`) and metrics (`tekton-pipelines-controller`)
- ⚠️ `service.version` missing from traces
- ⚠️ `service.version` is a commit SHA, not a semantic version (`v1.11.1`)
- ⚠️ No documented `OTEL_*` env var support
- ❌ `telemetry.sdk.*` not present in trace resource

#### Rationale
Level 2: Resource attributes are present and mostly correct for metrics, with `telemetry.sdk.*` and `service.version` natively set. However, the inconsistency between trace and metric service names is a significant gap for cross-signal correlation. The lack of `OTEL_*` env var support means operators cannot use standard OTel configuration patterns.

---

### 4. Trace Modeling & Context Propagation

**Level: 2 — Meaningful Traces with Internal Propagation**

#### Evidence

##### Span structure
Traces model the Kubernetes controller reconciliation loop in detail:
```
PipelineRun:Reconciler (root)
  └── PipelineRun:ReconcileKind
        ├── updatePipelineRunStatusFromInformer
        ├── reconcile
        │     ├── resolvePipelineState
        │     ├── runNextSchedulableTask
        │     │     └── createTaskRuns
        │     │           └── createTaskRun
        └── finishReconcileUpdateEmitEvents
              └── updateLabelsAndAnnotations
        └── durationAndCountMetrics
```

- **1,815 spans** observed across 14 batches covering 6 TaskRuns and 5 PipelineRuns
- **Parent-child relationships** are correctly modeled
- **Span kinds**: All `INTERNAL` (kind=1) — appropriate for controller reconciliation
- **Events**: Root spans include events like "updating PipelineRun status with SpanContext"

##### Context propagation
- **Internal propagation**: Trace context is stored in K8s resource annotations (`tekton.dev/taskrunSpanContext`). When a PipelineRun creates TaskRuns, the parent span context is passed via annotations, enabling correlated traces across reconciler iterations.
- **External propagation**: No W3C TraceContext header injection for external callers. Tekton is not an HTTP proxy — users submit CRDs, not HTTP requests. There is no mechanism for external trace context to be picked up from user submissions.
- **Log correlation**: Logs include `knative.dev/traceid` field, enabling manual correlation between logs and traces.

##### Trace coherence
- Traces tell a meaningful story of the reconciliation lifecycle
- The `createPod` span shows when K8s pod creation happens
- The `durationAndCountMetrics` span shows when metrics are emitted
- However, child spans beyond the first level have no attributes, limiting drill-down analysis
- No error status set on spans even when operations fail

#### Checklist assessment
- ✅ Rich parent-child span hierarchy modeling reconciler operations
- ✅ Internal context propagation via K8s annotations
- ✅ Trace IDs appear in logs (`knative.dev/traceid`)
- ✅ Span kinds are appropriate (INTERNAL for controller operations)
- ⚠️ Child spans have no attributes — limits drill-down analysis
- ⚠️ No error status on spans for failed operations
- ⚠️ Instrumentation scope has no version
- ❌ No external W3C TraceContext propagation (not applicable for CRD-based system)

#### Rationale
Level 2: Tekton's trace model is sophisticated for a Kubernetes controller — the reconciler loop is fully instrumented with meaningful parent-child relationships and context propagation via K8s annotations. The main gaps are the lack of attributes on child spans and missing error status codes, which limit the usefulness of traces for debugging failures. The absence of external W3C propagation is by design (not applicable for CRD-based CI/CD).

---

### 5. Multi-Signal Observability

**Level: 2 — Two Signals First-Class, Logs Secondary**

#### Evidence

##### Signal availability
- **Traces**: First-class — OTLP gRPC push, configurable, rich span hierarchy
- **Metrics**: First-class — OTLP gRPC/HTTP push or Prometheus scrape, 11 domain metrics + infrastructure metrics
- **Logs**: Secondary — structured JSON to stdout only; no OTLP log export; no configuration for log shipping

##### Cross-signal correlation
- **Trace → Log correlation**: Logs include `knative.dev/traceid` field. Example:
  ```json
  {"severity":"info","knative.dev/traceid":"de4ada81-1485-4a90-b7a7-1747a10bed20","knative.dev/key":"default/pipelinerun-3-second-task"}
  ```
  This enables manual correlation but requires the log collection pipeline to extract and index this field.
- **Metric → Trace correlation**: No direct link. Metrics use `tekton-pipelines-controller` as service name; traces use `pipelinerun-reconciler`/`taskrun-reconciler`. The `durationAndCountMetrics` span in traces shows when metrics are emitted but doesn't link to specific metric data points.
- **Shared attributes**: Metrics and traces both carry `namespace` and pipeline/taskrun identifiers, enabling domain-level correlation.

##### Collection model
- **Traces**: OTLP gRPC push (active, requires configuration)
- **Metrics**: OTLP gRPC push (active, requires configuration) or Prometheus scrape (default, passive)
- **Logs**: stdout only (passive, requires external log collection)

#### Checklist assessment
- ✅ Both traces and metrics are first-class, configurable OTLP signals
- ✅ Trace IDs in logs enable manual cross-signal correlation
- ✅ Metrics and traces share domain labels (namespace, pipeline name)
- ⚠️ Logs have no OTLP export — requires external collection
- ⚠️ `service.name` mismatch between traces and metrics prevents automatic correlation
- ⚠️ No `traceId`/`spanId` fields in OTLP-exported data (logs not exported via OTLP)
- ❌ No native log OTLP export capability

#### Rationale
Level 2: Tekton has two strong signals (traces + metrics) with OTLP push support, and provides trace IDs in logs for manual correlation. The service name inconsistency between signals and the lack of OTLP log export prevent automatic cross-signal correlation. Operators need to configure log collection separately and build correlation logic on top.

---

### 6. Audience & Signal Quality

**Level: 2 — Operator-Focused with Room for Improvement**

#### Evidence

##### Span naming
Span names reflect meaningful reconciler operations:
- `PipelineRun:Reconciler` — top-level reconciler entry point
- `PipelineRun:ReconcileKind` — the core reconcile logic
- `reconcile` — generic reconcile step
- `resolvePipelineState` — resolving task dependencies
- `createTaskRuns` / `createTaskRun` — creating K8s TaskRun objects
- `createPod` — creating the execution pod
- `prepare` — preparing the TaskRun execution
- `updateLabelsAndAnnotations` — K8s resource updates
- `finishReconcileUpdateEmitEvents` — completion and event emission
- `durationAndCountMetrics` — metric emission

These names are meaningful to Tekton operators and developers. They map to documented controller concepts.

##### Signal-to-noise ratio
- **Traces**: High signal — each span represents a distinct controller operation. 1,815 spans for 16 runs is reasonable. The `durationAndCountMetrics` span is somewhat meta (a span tracking when metrics are emitted), but not noisy.
- **Metrics**: Good signal — 11 domain metrics are focused on CI/CD outcomes (pipeline duration, task duration, run counts, pod latency). Infrastructure metrics (Go runtime, workqueue) are standard and expected.
- **Noise**: The Prometheus endpoint exposes ~40+ metrics including Go memstats, process metrics, and promhttp internals. The OTLP push is cleaner, exposing only ~26 metrics.

##### Default usability
- **Out-of-the-box**: Prometheus metrics work with zero configuration. Traces require ConfigMap changes and are disabled by default.
- **Dashboards**: Tekton provides no official Grafana dashboards or alerts. The metrics documentation is comprehensive enough to build them.
- **Child span attributes**: Many child spans have no attributes, limiting the ability to filter/aggregate by pipeline/task in trace backends.

#### Checklist assessment
- ✅ Span names map to meaningful Tekton controller operations
- ✅ Domain metrics labeled with pipeline/task/namespace/status
- ✅ Metrics documentation includes cardinality warnings
- ⚠️ Child spans lack attributes — cannot filter by pipeline name in trace queries
- ⚠️ No official dashboards or alert rules provided
- ⚠️ Tracing disabled by default — operators must actively configure it
- ❌ No error status on spans — cannot distinguish successful vs failed reconciliation in trace backends

#### Rationale
Level 2: The telemetry quality is operator-focused and meaningful. Span names model the controller lifecycle well, and metrics are domain-relevant with proper labels. The main gaps are the lack of attributes on child spans (limiting trace-based debugging) and the absence of error status codes on spans.

---

### 7. Stability & Change Management

**Level: 2 — Documented Migration, Experimental Status**

#### Evidence

##### Documentation of telemetry behavior
- **Metrics documentation**: `docs/metrics.md` provides a comprehensive reference for all metrics, their types, labels, and configuration options. Clearly documents all three export protocols.
- **Migration guide**: `docs/metrics-migration-otel.md` is a detailed migration guide covering the OpenCensus → OpenTelemetry transition with before/after metric name tables, impact assessment, and action items.
- **Config reference**: `config/config-observability.yaml` is extensively commented with all available options.

##### Change communication
- The OTel migration was documented as a **breaking change** with an explicit migration guide.
- Metric names are labeled as "experimental" in the official docs table.
- Release notes (PR #9043 referenced in migration guide) document the change.

##### Schema URL presence
- **Traces**: `https://opentelemetry.io/schemas/1.12.0` — set but outdated (current is 1.40.0)
- **Metrics (OTLP push)**: `https://opentelemetry.io/schemas/1.40.0` — current ✅
- **Metrics (Prometheus)**: No schema URL (not applicable for Prometheus format)

##### Stability guarantees
- All core Tekton metrics are labeled "experimental" in the documentation
- No explicit stability SLO or deprecation policy for telemetry signals
- The migration guide demonstrates willingness to make breaking changes with documentation

#### Checklist assessment
- ✅ Comprehensive metrics documentation with all labels and types
- ✅ Dedicated migration guide for breaking changes
- ✅ Schema URL set (metrics: current; traces: outdated)
- ✅ Config reference is self-documenting
- ⚠️ All metrics labeled "experimental" — no stability guarantee
- ⚠️ Trace schema URL outdated (1.12.0 vs 1.40.0)
- ⚠️ No explicit stability SLO for telemetry
- ❌ No changelog entry format specifically for telemetry changes

#### Rationale
Level 2: Tekton demonstrates good change management practices — the OTel migration was well-documented with a migration guide, and the metrics reference is comprehensive. The main gaps are the experimental status of all metrics (no stability guarantee) and the outdated schema URL in traces. The project clearly communicates breaking changes when they occur.

---

## Key findings

### Strengths

1. **Full OTLP support for both signals**: Tekton supports OTLP gRPC and HTTP push for both traces and metrics via a simple ConfigMap — this is a significant maturity differentiator from projects that only expose Prometheus.

2. **Rich reconciler traces**: The trace model for the Kubernetes controller reconciliation loop is detailed and meaningful, with proper parent-child relationships across 17 distinct span types. Context is propagated between reconciler iterations via K8s annotations — a clever adaptation of W3C TraceContext for the CRD model.

3. **OTel semconv for infrastructure metrics**: When using OTLP push, infrastructure metrics (`go.*`, `http.client.request.duration`) follow current OTel semantic conventions with correct attribute names (`http.request.method`, `server.address`, etc.). This reflects the OpenCensus → OTel migration being done properly.

4. **Comprehensive documentation with migration guide**: The `docs/metrics.md` and `docs/metrics-migration-otel.md` files provide detailed reference and migration guidance. The breaking change from OpenCensus to OTel was communicated clearly.

5. **Trace IDs in structured logs**: Every log line includes `knative.dev/traceid`, enabling manual correlation between logs and traces even without OTLP log export.

### Areas for improvement

1. **Inconsistent `service.name` between traces and metrics**: Traces use `pipelinerun-reconciler`/`taskrun-reconciler` while metrics use `tekton-pipelines-controller`. This prevents automatic cross-signal correlation in observability backends. Both signals should use a consistent `service.name` (e.g., `tekton-pipelines-controller`).

2. **Child spans lack attributes**: Only root spans (`PipelineRun:Reconciler`, `TaskRun:Reconciler`, `PipelineRun:ReconcileKind`, `TaskRun:ReconcileKind`) carry `pipelinerun`/`taskrun` + `namespace` attributes. All child spans (e.g., `createPod`, `resolvePipelineState`) have no attributes, making it impossible to filter traces by pipeline name in span-level queries.

3. **No error status on spans**: All spans report `UNSET` status regardless of outcome. Failed reconciliations should set `ERROR` status with an error description, enabling trace-based SLO monitoring and alerting.

4. **OTLP not the default**: Both tracing (`tracing-protocol: none`) and OTLP metrics (`metrics-protocol: prometheus`) are not enabled by default. Operators must explicitly configure OTLP. Given that Tekton markets itself as OTel-native, defaulting to Prometheus (or at least prompting for OTLP configuration) would improve adoption.

5. **No OTLP log export**: Logs are structured JSON but only to stdout. Adding an `OTEL_LOGS_EXPORTER` option or `logs-protocol` key to `config-observability` would complete the three-signal story. The trace ID is already present in logs — the infrastructure is almost there.

### Notable observations

- **OpenCensus → OTel migration is recent and well-executed**: The migration guide (PR #9043) shows the project made a deliberate, documented transition. The infrastructure metrics now use OTel semconv naming (`go.*`, `http.client.request.duration`) while preserving backward compatibility for core Tekton metrics.

- **Prometheus metrics expose `otel_scope_name` label**: The Prometheus endpoint includes `otel_scope_name` and `otel_scope_schema_url` labels on all metrics — a direct artifact of using the OTel Go SDK's Prometheus bridge. This is informational but slightly noisy for PromQL users.

- **`durationAndCountMetrics` span**: An unusual design choice — there's a span specifically tracking when the controller emits metrics. This provides traceability for metric emission but is an implementation detail that most operators don't need to see.

- **OTLP gRPC insecure mode requires `http://` prefix**: The `metrics-endpoint` must use `http://` prefix for insecure connections (e.g., `http://collector:4317`). Without it, Tekton attempts a TLS handshake and fails. This is not documented clearly and caused a TLS error during evaluation.

- **`service.version` is a commit SHA**: The `service.version` attribute is set to a git commit SHA (`5a88281`) rather than the release version (`v1.11.1`). While technically correct, this is less useful for operators who know the release version, not the commit hash.

---

## Methodology notes

- Telemetry was collected using an OpenTelemetry Collector (v0.150.1) with file export in a local kind cluster (otel-eval-tekton)
- The k8sattributes processor was used to distinguish native vs enriched resource attributes
- Both Prometheus scrape and OTLP push were tested; OTLP push was confirmed working after fixing the endpoint URL format
- 16 TaskRuns and 7 PipelineRuns were executed to generate telemetry
- Semantic conventions were checked against the latest stable OpenTelemetry specification (1.40.0)
- Documentation was reviewed at tekton.dev and github.com/tektoncd/pipeline/docs/
- The metrics migration guide (PR #9043) was reviewed for change management assessment

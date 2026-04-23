---
name: evaluate-otel-maturity
description: Evaluate a CNCF project's OpenTelemetry support maturity by inspecting telemetry data, documentation, and source code. Produces a structured per-dimension assessment using the OpenTelemetry Support Maturity Model. Use after install-cncf-project has telemetry flowing.
argument-hint: "<project-name>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - WebFetch
  - WebSearch
---

# Evaluate OpenTelemetry Support Maturity

You evaluate a CNCF project's OpenTelemetry support using the **OpenTelemetry Support Maturity Model for CNCF Projects**. The full model specification, including detailed dimension descriptions and the evaluation checklist, is in `maturity-model-spec.md` in this skill's directory. **Read it before starting any evaluation.**

Your evaluation must be thorough, evidence-based, and grounded in the actual telemetry data collected in the evaluation cluster. Always reference the latest stable OpenTelemetry semantic conventions when assessing attribute correctness.

## Context

The evaluation cluster is running with telemetry written to `/tmp/otel-eval-<project-name>/`:
- `traces.jsonl` — OTLP trace export batches
- `metrics.jsonl` — OTLP metrics export batches
- `logs.jsonl` — OTLP log export batches

Research notes from installation are in `.otel-eval/<project-name>/RESEARCH.md`.

## Required argument

The user provides the `<project-name>` to evaluate.

## Before you start

1. **Read the maturity model spec** — Read `maturity-model-spec.md` from this skill's directory. You need the full dimension definitions, level characteristics, and evaluation checklist questions.
2. **Read the research notes** — Read `.otel-eval/<project-name>/RESEARCH.md` for installation context.
3. **Verify telemetry exists** — Check that the JSONL files have data:
   ```bash
   wc -l /tmp/otel-eval-<project-name>/*.jsonl
   ```

## Evaluation process

### Phase 1: Collect evidence from telemetry

For each signal, extract and document concrete evidence. Use `jq` to parse the JSONL files.

#### Traces analysis

```bash
# Resource attributes on trace data
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]? | .resource.attributes[]? | "\(.key): \(.value)"' | sort -u

# Span names, kinds, and status
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]?.scopeSpans[]?.spans[]? | "\(.name) | kind=\(.kind) | status=\(.status.code // "UNSET")"' | sort | uniq -c | sort -rn

# Span attributes (first 50 unique keys)
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]?.scopeSpans[]?.spans[]?.attributes[]?.key' | sort -u | head -50

# Scope (instrumentation library) info
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]?.scopeSpans[]?.scope | "\(.name // "unknown") v\(.version // "unknown")"' | sort -u

# Check for W3C trace context propagation (look for parent span IDs)
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]?.scopeSpans[]?.spans[]? | select(.parentSpanId != "" and .parentSpanId != null) | .name' | head -10

# Check span kind correctness for entry points
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]?.scopeSpans[]?.spans[]? | select(.parentSpanId == "" or .parentSpanId == null) | "\(.name) | kind=\(.kind)"' | sort -u

# Schema URL if present
cat /tmp/otel-eval-<project-name>/traces.jsonl | jq -r '.resourceSpans[]?.schemaUrl // empty' | sort -u
```

#### Metrics analysis

```bash
# Resource attributes on metrics data
cat /tmp/otel-eval-<project-name>/metrics.jsonl | jq -r '.resourceMetrics[]? | .resource.attributes[]? | "\(.key): \(.value)"' | sort -u

# Metric names and types
cat /tmp/otel-eval-<project-name>/metrics.jsonl | jq -r '.resourceMetrics[]?.scopeMetrics[]?.metrics[]? | "\(.name) | \(if .sum then "sum" elif .gauge then "gauge" elif .histogram then "histogram" elif .exponentialHistogram then "exponentialHistogram" elif .summary then "summary" else "unknown" end)"' | sort -u

# Metric attribute keys (first 50)
cat /tmp/otel-eval-<project-name>/metrics.jsonl | jq -r '[.resourceMetrics[]?.scopeMetrics[]?.metrics[]? | (.sum.dataPoints[]?, .gauge.dataPoints[]?, .histogram.dataPoints[]?, .summary.dataPoints[]?) | .attributes[]?.key] | unique[]' | head -50

# Scope info for metrics
cat /tmp/otel-eval-<project-name>/metrics.jsonl | jq -r '.resourceMetrics[]?.scopeMetrics[]?.scope | "\(.name // "unknown") v\(.version // "unknown")"' | sort -u

# Schema URL if present
cat /tmp/otel-eval-<project-name>/metrics.jsonl | jq -r '.resourceMetrics[]?.schemaUrl // empty' | sort -u
```

#### Logs analysis

```bash
# Resource attributes on log data
cat /tmp/otel-eval-<project-name>/logs.jsonl | jq -r '.resourceLogs[]? | .resource.attributes[]? | "\(.key): \(.value)"' | sort -u

# Log severity levels
cat /tmp/otel-eval-<project-name>/logs.jsonl | jq -r '.resourceLogs[]?.scopeLogs[]?.logRecords[]? | .severityText // "UNSET"' | sort | uniq -c | sort -rn

# Check for trace context on logs (traceId and spanId present)
cat /tmp/otel-eval-<project-name>/logs.jsonl | jq -r '.resourceLogs[]?.scopeLogs[]?.logRecords[]? | select(.traceId != "" and .traceId != null and .traceId != "00000000000000000000000000000000") | "has_trace_context"' | wc -l

# Log body structure (first 5 records)
cat /tmp/otel-eval-<project-name>/logs.jsonl | jq '.resourceLogs[]?.scopeLogs[]?.logRecords[]?.body' | head -20

# Log attributes
cat /tmp/otel-eval-<project-name>/logs.jsonl | jq -r '.resourceLogs[]?.scopeLogs[]?.logRecords[]?.attributes[]?.key' | sort -u | head -50

# Schema URL if present
cat /tmp/otel-eval-<project-name>/logs.jsonl | jq -r '.resourceLogs[]?.schemaUrl // empty' | sort -u
```

#### Collector debug logs (pre-enrichment view)

```bash
# Check collector logs for what arrives before k8sattributes processing
kubectl logs -n opentelemetry -l app.kubernetes.io/instance=otel-collector --tail=100 | head -200
```

### Phase 2: Collect evidence from documentation and source

Use web search and web fetch to check:

1. **Official documentation** — How is OpenTelemetry documented? Is it the recommended path?
2. **Configuration reference** — Are `OTEL_*` env vars documented? Is OTLP the default?
3. **Changelog / release notes** — Are telemetry changes documented? Any breaking changes communicated?
4. **GitHub issues / PRs** — Any open issues about OTel support? Recent improvements?
5. **Source code** (if needed) — How is instrumentation implemented? SDK-based or custom?

### Phase 3: Evaluate each dimension

For each of the 7 dimensions, follow this process:

1. **Review the dimension definition and checklist** from the maturity model spec
2. **Gather all relevant evidence** (telemetry data, docs, source)
3. **Answer the checklist questions** for each level, starting from Level 0 upward
4. **Determine the level** — the highest level where the project substantially meets the characteristics
5. **Document your reasoning** with specific evidence

#### Critical evaluation principles

- **Evaluate what the project emits natively.** Downstream collector enrichment (k8sattributes, transforms, parsing) does not count toward a higher maturity level unless the project explicitly documents that pipeline as part of its supported integration contract.
- **Use the latest stable OpenTelemetry semantic conventions.** Check attributes against the current spec. Deprecated attributes like `http.method`, `http.status_code`, `http.url`, `http.target` should be flagged — the current conventions are `http.request.method`, `http.response.status_code`, `url.path`, `url.full`, etc.
- **Absence of a signal is a data point.** If the project doesn't emit metrics via OTLP, that's relevant for Integration Surface and Multi-Signal dimensions.
- **Be specific.** Quote actual attribute names, span names, metric names from the telemetry data. Don't generalize.
- **Note what is native vs enriched.** Compare resource attributes in the telemetry files (post-k8sattributes) with what the collector debug logs show arriving (pre-enrichment).

### Phase 4: Produce the evaluation report

Write the evaluation to `.otel-eval/<project-name>/EVALUATION.md` with this structure:

```markdown
# OpenTelemetry Support Maturity Evaluation: <project-name>

## Project overview

- **Project**: <name and brief description>
- **Version evaluated**: <version>
- **Evaluation date**: <date>
- **Cluster**: otel-eval-<project-name>
- **Maturity model version**: OpenTelemetry Support Maturity Model for CNCF Projects (draft)

## Summary

| Dimension | Level | Summary |
|-----------|-------|---------|
| Integration Surface | <0-3> | <one-line summary> |
| Semantic Conventions | <0-3> | <one-line summary> |
| Resource Attributes & Configuration | <0-3> | <one-line summary> |
| Trace Modeling & Context Propagation | <0-3> | <one-line summary> |
| Multi-Signal Observability | <0-3> | <one-line summary> |
| Audience & Signal Quality | <0-3> | <one-line summary> |
| Stability & Change Management | <0-3> | <one-line summary> |

## Telemetry overview

### Signals observed
- **Traces**: [flowing/not flowing] — [export method]
- **Metrics**: [flowing/not flowing] — [export method]
- **Logs**: [flowing/not flowing] — [export method]

### Resource attributes (native, before collector enrichment)
<list of resource attributes the project emits natively>

### Resource attributes (after collector enrichment)
<list of resource attributes after k8sattributes processing>

## Dimension evaluations

### 1. Integration Surface

**Level: <0-3> — <level name>**

#### Evidence
<specific observations from telemetry, docs, and configuration>

#### Checklist assessment
<answers to the relevant checklist questions from the maturity model>

#### Rationale
<why this level was chosen, referencing specific characteristics from the model>

---

### 2. Semantic Conventions

**Level: <0-3> — <level name>**

#### Evidence

##### Trace attributes
<list actual attribute names found, flag deprecated ones, note alignment with current semconv>

##### Metric names and attributes
<list actual metric names, note naming conventions used>

##### Log attributes
<list actual log attribute names, note schema used>

#### Checklist assessment
<answers to the relevant checklist questions>

#### Rationale
<why this level was chosen>

---

### 3. Resource Attributes & Configuration

**Level: <0-3> — <level name>**

#### Evidence

##### Native resource attributes
<what the project emits at the source>

##### OTEL_* environment variable support
<tested behavior>

##### Identity consistency across signals
<comparison of service.name, service.version across traces, metrics, logs>

#### Checklist assessment
<answers to the relevant checklist questions>

#### Rationale
<why this level was chosen>

---

### 4. Trace Modeling & Context Propagation

**Level: <0-3> — <level name>**

#### Evidence

##### Span structure
<root spans, parent-child relationships, span kinds>

##### Context propagation
<W3C Trace Context support, propagation to downstream services>

##### Trace coherence
<do traces tell a complete story?>

#### Checklist assessment
<answers to the relevant checklist questions>

#### Rationale
<why this level was chosen>

---

### 5. Multi-Signal Observability

**Level: <0-3> — <level name>**

#### Evidence

##### Signal availability
<which signals are first-class, which are missing or secondary>

##### Cross-signal correlation
<trace context in logs, shared attributes between signals>

##### Collection model
<OTLP push vs Prometheus scrape vs log collection — per signal>

#### Checklist assessment
<answers to the relevant checklist questions>

#### Rationale
<why this level was chosen>

---

### 6. Audience & Signal Quality

**Level: <0-3> — <level name>**

#### Evidence

##### Span naming
<are names logical operations or internal code paths?>

##### Signal-to-noise ratio
<volume of useful vs noisy telemetry>

##### Default usability
<can operators use telemetry without heavy customization?>

#### Checklist assessment
<answers to the relevant checklist questions>

#### Rationale
<why this level was chosen>

---

### 7. Stability & Change Management

**Level: <0-3> — <level name>**

#### Evidence

##### Documentation of telemetry behavior
<is telemetry documented as a contract?>

##### Change communication
<how are telemetry changes communicated in release notes?>

##### Schema URL presence
<does the project set schemaUrl in OTLP exports?>

##### Stability guarantees
<any explicit stability commitments for telemetry?>

#### Checklist assessment
<answers to the relevant checklist questions>

#### Rationale
<why this level was chosen>

---

## Key findings

### Strengths
<bullet list of what the project does well>

### Areas for improvement
<bullet list of concrete, actionable improvements>

### Notable observations
<anything surprising, unusual, or worth highlighting>

## Methodology notes

- Telemetry was collected using an OpenTelemetry Collector with file export in a local kind cluster
- The k8sattributes processor was used to distinguish native vs enriched resource attributes
- Semantic conventions were checked against the latest stable OpenTelemetry specification
- Documentation and source code were reviewed for context beyond what telemetry data alone reveals
```

### Phase 5: Present findings

After writing the evaluation, present a concise summary to the user with:
1. The summary table
2. Top 3 strengths
3. Top 3 improvement areas
4. Any surprising findings
5. Path to the full evaluation: `.otel-eval/<project-name>/EVALUATION.md`

## Important guidance

- **Thoroughness matters.** This evaluation is meant to be a comprehensive, referenceable document. Don't skip dimensions or rush through evidence collection.
- **Always use the latest semantic conventions.** The current stable HTTP semantic conventions use `http.request.method` (not `http.method`), `http.response.status_code` (not `http.status_code`), `url.path` (not `http.target`), `url.full` (not `http.url`). Flag any deprecated attributes explicitly.
- **Quote actual data.** Every claim in the evaluation should be backed by a specific attribute name, metric name, span name, or documentation quote.
- **Be fair and constructive.** The maturity model is descriptive, not judgmental. Lower maturity levels often reflect reasonable trade-offs. Acknowledge constraints (e.g., upstream Envoy dependencies) while still accurately assessing the current state.
- **Distinguish project-native from collector-derived.** This is the most important analytical distinction. The model evaluates what the project supports natively, not what pipeline processing can achieve.
- **Check documentation.** Telemetry data alone is not sufficient. Documentation, changelogs, and configuration guides provide essential context for the Stability & Change Management and Integration Surface dimensions.

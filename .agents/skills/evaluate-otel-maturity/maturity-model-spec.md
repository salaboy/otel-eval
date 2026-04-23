# **OpenTelemetry Support Maturity Model**

# **OpenTelemetry Support Maturity Model for CNCF Projects**

# Introduction & Purpose

OpenTelemetry has become the de facto standard for producing telemetry in cloud native systems. As adoption has grown, expectations around OpenTelemetry support in CNCF projects have evolved as well. Users increasingly expect projects to integrate cleanly with existing OpenTelemetry pipelines, follow shared semantic conventions, support correlation across signals, and behave predictably across environments.

At the same time, OpenTelemetry support is not binary. Projects evolve over time, often starting with basic instrumentation and gradually moving toward more intentional, user-oriented observability design. Different aspects of OpenTelemetry support mature at different rates, depending on project scope, architecture, and available resources.

This document introduces a *maturity model for OpenTelemetry support in CNCF projects*. The goal is to provide a shared framework for:

* evaluating the current state of OpenTelemetry support  
* discussing trade-offs and improvement areas  
* guiding incremental, intentional evolution over time

The model is inspired by the [*CNCF Platform Engineering Maturity Model*](https://tag-app-delivery.cncf.io/whitepapers/platform-eng-maturity-model/#conclusion) and follows the same philosophy: descriptive rather than prescriptive, multi-dimensional rather than score-based, and focused on progression rather than compliance.

# What This Model Is and What It’s Not

This model *is*:

* a tool for reflection and discussion  
* a way to describe typical evolution patterns  
* a shared vocabulary for maintainers, contributors, users, and CNCF groups

This model *is not*:

* a certification or conformance program  
* a checklist that must be “passed”  
* a ranking or comparison of CNCF projects

This model complements, but does not replace, other community efforts in the OpenTelemetry ecosystem. For example, the [Instrumentation Score](https://github.com/instrumentation-score/spec) specification provides rule-based checks that assess the quality and completeness of emitted telemetry, while ecosystem registries such as the [OpenTelemetry Ecosystem Explorer](https://github.com/open-telemetry/opentelemetry-ecosystem-explorer) catalog available components and integrations.

The maturity model focuses instead on design intent, consistency, and evolution over time \- how OpenTelemetry support is shaped, governed, and maintained \- rather than producing a numeric score or acting as a discovery index.

Projects may be at different maturity levels across different dimensions, and that is expected. Higher maturity is not always necessary or desirable for every project; the value lies in understanding where you are and what matters next.

# How to Use This Model

The model is structured around *dimensions* of OpenTelemetry support. Each dimension is described across *four maturity levels*.

This model evaluates the maturity of a project’s OpenTelemetry support based on what the project emits and supports natively.

Maturity assessments should be based on the structure, semantics, and configuration surface of the telemetry produced by the project itself (for example, its OTLP payloads, supported configuration options, and documented behavior).

Downstream processing \- such as enrichment, transformation, or correlation performed by an OpenTelemetry Collector \- may be noted as a mitigation, but should not be used to award a higher maturity level unless the project explicitly documents that pipeline as part of its supported integration contract.

This distinction helps separate project maturity from pipeline capability and avoids conflating what is possible with what is intentionally supported.

Rule-based quality assessments, such as those defined by the [Instrumentation Score](https://github.com/instrumentation-score/spec) specification, can be useful for validating the quality of emitted telemetry, but they do not determine maturity levels in this model.

You can use the model to:

* assess a project dimension by dimension  
* identify gaps or inconsistencies  
* guide roadmap or design discussions  
* align expectations between maintainers and users

There is intentionally no single overall maturity score. Each dimension stands on its own.

Readers can stop at the overview table for a high-level understanding, or dive deeper into individual dimensions for detailed explanations and examples.

# Global Maturity Levels

The following maturity levels apply consistently across all dimensions.

## Level 0: Instrumented

Telemetry exists, primarily to support internal debugging and development needs. Instrumentation is often incremental and opportunistic. OpenTelemetry is not yet a primary design concern, and observability is treated largely as an implementation detail.

## Level 1: OpenTelemetry-Aligned

OpenTelemetry is explicitly supported, often alongside legacy approaches. OpenTelemetry SDKs, protocols, or exporters are adopted, but legacy assumptions and constraints still influence design. Telemetry generally works for common scenarios.

## Level 2: OpenTelemetry-Native

OpenTelemetry is the primary integration surface for users. Telemetry is designed intentionally, with interoperability, correlation, and user experience in mind. OpenTelemetry concepts shape architecture and configuration choices.

## Level 3: OpenTelemetry-Optimized

OpenTelemetry support is continuously refined based on real-world usage, scale, and feedback. Telemetry is treated as a long-lived product surface, with deliberate evolution, governance, and attention to cost, quality, and usability.

# OpenTelemetry Support Maturity Matrix

The following table provides a high-level overview of the maturity model, showing how OpenTelemetry support typically evolves across each dimension and maturity level. Detailed explanations of each dimension are provided in the sections that follow..

| Dimension | Level 0:  Instrumented | Level 1:OTel-Aligned | Level 2:  OTel-Native | Level 3:  OTel-Optimized |
| :---: | :---: | :---: | :---: | :---: |
| **Integration Surface** | Tool-specific exporters | OTLP alongside legacy | OTel is primary interface | Intentionally evolved integration |
| **Semantic Conventions** | Proprietary / inconsistent | Partial OTel alignment | Consistent OTel semantics | Intentional semantic extensions |
| **Resource Attributes & Configuration** | Hard-coded identity | Inconsistent config | Stable identity, OTEL\_\* respected | Predictable, documented behavior |
| **Trace Modeling & Context Propagation** | Fragmented traces | Common paths coherent | Intentional trace modeling | Complex async workflows supported |
| **Multi-Signal Observability** | Single-signal focus | Loosely connected signals | Correlated traces, metrics, logs | Cross-signal workflows optimized |
| **Audience & Signal Quality** | Maintainer-focused, noisy | Reduced noise | User-oriented defaults | Signal quality actively optimized |
| **Stability & Change Management** | Undocumented changes | Informal communication | Telemetry treated as contract | Planned, reviewed evolution |

## Dimensions Covered

The maturity model evaluates OpenTelemetry support across the following dimensions:

1. **Integration Surface**  
   How users connect a project to their observability pipelines and how strongly telemetry is coupled to specific tools or vendors.  
2. **Semantic Conventions (including extensions)**  
   How consistently telemetry meaning aligns with OpenTelemetry semantic conventions, and how domain-specific meaning is introduced when needed.  
3. **Resource Attributes & Configuration**  
   How identity, scope, and configuration are handled across environments, including correct use of resource attributes and standard OpenTelemetry configuration mechanisms.  
4. **Trace Modeling & Context Propagation**  
   How traces are structured and how context flows through synchronous and asynchronous execution paths.  
5. **Multi-Signal Observability**  
   How traces, metrics, and logs are supported together and correlated to form a coherent observability experience.  
6. **Audience & Signal Quality**  
   Who telemetry is designed for, how noisy it is by default, and how well it communicates meaningful system behavior.  
7. **Stability & Change Management**  
   How telemetry evolves over time and how changes are communicated and managed once users depend on it.

## Visualizing maturity across dimensions

Because OpenTelemetry support often matures unevenly across different dimensions, visual representations can help make trade-offs and patterns easier to understand. One optional way to visualize an assessment is to plot the maturity level of each dimension on a radar chart, with each axis representing a specific aspect of OpenTelemetry support.

Used this way, the chart does not produce a single score or ranking. Instead, it highlights where maturity is concentrated and where gaps or inconsistencies may exist. A project may, for example, show strong trace modeling and context propagation while still relying on legacy approaches for metrics, or offer a clean integration surface while lagging in stability and change management.

### Example: layered maturity profiles

To illustrate how the model can be applied, the following example shows *three fictive projects* plotted on the same radar chart. Each project is evaluated across the same set of dimensions and maturity levels (0–3). The intent is not to compare real systems, but to demonstrate how different maturity profiles can emerge depending on architectural role and design priorities.

**![][image1]**

*Figure: Example radar chart showing layered OpenTelemetry maturity profiles for three fictive projects (for illustration purposes only). Each axis represents a maturity dimension, with values ranging from Level 0 (Instrumented) to Level 3 (OpenTelemetry-Optimized).*

In this fictive example, the differing shapes make trade-offs immediately visible. One project may emphasize trace modeling and context propagation, another may lead in metrics and stability, while a third balances maturity more evenly across dimensions. The chart makes these differences visible without collapsing them into a single score.

### Comparing maturity across categories

When assessments for multiple projects are visualized using the same dimensions, profiles can be layered to explore how different categories of software tend to evolve. Ingress controllers, service meshes, databases, and application frameworks often exhibit distinct maturity patterns, shaped by their role in the architecture and the signals they prioritize first.

These comparisons are intended to be illustrative rather than evaluative. They are most meaningful when used within similar categories and should be read as a way to understand expectations and trade-offs, not as a mechanism for ranking or judgment.

# Model Dimensions in Detail

## Dimension: Integration Surface

### What this dimension captures

The *integration surface* describes how a project exposes its telemetry to users and how easily that telemetry can be integrated into existing observability pipelines.

This dimension is less about *what telemetry is emitted* and more about *how users consume it*. A mature integration surface minimizes coupling to specific tools or vendors, allows configuration without code changes, and fits naturally into OpenTelemetry-based environments.

When this dimension is immature, users often experience friction early:

* they must adopt a specific backend or deployment model  
* they cannot reuse existing OpenTelemetry pipelines  
* they need project-specific flags, extensions, or sidecars to get telemetry out

As maturity increases, OpenTelemetry becomes the *default telemetry contract* between the project and its users.

### Level 0: Instrumented

At this level, telemetry exists, but the integration surface is tightly coupled to specific tools or deployment assumptions. Telemetry is exposed primarily to satisfy immediate operational needs rather than to integrate cleanly into diverse environments.

Instrumentation decisions are often driven by convenience or historical precedent rather than long-term interoperability.

**Characteristics**

* Telemetry is exposed via tool-specific exporters (for example, a built-in Jaeger exporter)  
* Configuration is handled through project-specific flags or config files  
* Users must adapt their environment to the project’s telemetry model  
* OpenTelemetry may not be present at all, or only indirectly

**Example scenarios**

* A project ships with a Jaeger extension that users must enable to get traces, making it difficult to send telemetry anywhere else.  
* Metrics are exposed only via a Prometheus endpoint with no alternative export path.  
* Users running centralized OpenTelemetry Collectors must add custom adapters or sidecars to consume the project’s telemetry.

At this level, telemetry is “available,” but integration cost is pushed onto users.

### Level 1: OpenTelemetry-Aligned

At this level, the project explicitly supports OpenTelemetry, but often alongside existing legacy integrations. OpenTelemetry is treated as an additional option rather than the primary interface.

This stage is commonly reached through incremental migration: adding OTLP export while keeping existing exporters intact.

**Characteristics**

* OTLP export is supported, often as an alternative to legacy exporters  
* OpenTelemetry SDKs or Collector components are introduced  
* Legacy integrations (Jaeger, Prometheus scraping) remain first-class  
* Configuration paths may overlap or conflict

**Example scenarios**

* A project supports both a Jaeger exporter and OTLP export, with separate configuration paths.  
* Documentation lists multiple ways to enable telemetry, leaving users unsure which is preferred.  
* OpenTelemetry pipelines work, but only if users disable legacy features explicitly.

This level reflects intentional movement toward OpenTelemetry, but with lingering ambiguity about the “right” integration path.

### Level 2: OpenTelemetry-Native

At this level, OpenTelemetry becomes the *primary integration surface* for telemetry. Legacy integrations may still exist, but they are clearly positioned as compatibility options rather than the default.

The project is designed to plug naturally into OpenTelemetry-native environments without requiring custom glue code.

**Characteristics**

* OpenTelemetry (typically via OTLP) is the default export mechanism  
* Users configure telemetry using standard OpenTelemetry configuration mechanisms  
* Legacy exporters are optional or deprecated  
* The project integrates cleanly with existing OpenTelemetry Collectors and pipelines

**Example scenarios**

* A user can deploy the project and immediately connect it to their existing OpenTelemetry Collector using standard configuration.  
* Telemetry configuration is handled via environment variables and OpenTelemetry SDK settings rather than project-specific flags.  
* Documentation clearly positions OpenTelemetry as the recommended integration path.

At this level, the project “speaks OpenTelemetry” fluently and predictably.

### Level 3: OpenTelemetry-Optimized

At this level, the integration surface is treated as a *long-lived, user-facing contract*. Changes are made intentionally, with attention to user impact, migration paths, and ecosystem compatibility.

The focus shifts from “supporting OpenTelemetry” to *optimizing how users integrate and operate the project at scale*.

**Characteristics**

* The integration surface is explicitly designed and documented  
* Legacy integrations are deprecated or removed with clear migration guidance  
* Changes to telemetry integration are reviewed with the same care as API changes  
* The project anticipates diverse deployment models and observability stacks

**Example scenarios**

* A project migrates from a custom exporter to OTLP and publishes a clear migration guide for users.  
* Telemetry integration changes are discussed in design proposals or release notes.  
* Users can integrate the project into managed observability platforms, self-hosted collectors, or hybrid environments without friction.

At this level, the integration surface enables ecosystem-wide interoperability rather than constraining it.

### Summary for Integration Surface

The integration surface is often the *first place users feel friction* when adopting a project. As maturity increases, responsibility shifts from the user adapting to the project toward the project integrating naturally into existing observability ecosystems.

Progression along this dimension reflects a shift from:

* tool-centric design → pipeline-centric design  
* ad-hoc integration → intentional contracts  
* short-term convenience → long-term interoperability

## Dimension: Semantic Conventions

### What this dimension captures

This dimension describes *how telemetry meaning is defined, shared, and understood* between a project and its users.

Semantic conventions are the *language* of telemetry. They define what attributes mean, how similar concepts are represented across signals, and whether telemetry from different components can be interpreted consistently. When semantic conventions are weak or inconsistent, users must rely on project-specific knowledge to make sense of data, dashboards become fragile, and cross-project correlation breaks down.

As maturity increases, semantic conventions move from being incidental side effects of instrumentation to an *explicit, stewarded contract* between the project and its users.

### Level 0: Instrumented

At this level, semantic meaning emerges organically from implementation details rather than from deliberate design. Attribute names and meanings are often chosen locally, with little consideration for consistency or interoperability.

**Characteristics**

* Attribute names are ad-hoc or proprietary  
* Similar concepts are represented differently across components or signals  
* Deprecated or legacy fields are used without clear intent  
* Telemetry meaning is implicit and undocumented

**Example scenarios**

* HTTP request paths appear as `path` in traces, `uri` in metrics, and `requestPath` in logs.  
* Contributors add new attributes by copying nearby code without knowing whether the attribute already exists elsewhere.  
* Users need to consult project-specific documentation or source code to understand what a span or metric represents.

At this level, telemetry can be useful locally, but does not scale well to larger systems or shared tooling.

### Level 1: OpenTelemetry-Aligned

At this level, the project intentionally adopts OpenTelemetry semantic conventions where they are known and convenient, but alignment is incomplete. Legacy or project-specific semantics may still coexist.

This stage often reflects incremental adoption: teams want to align with OpenTelemetry but are constrained by historical choices or partial refactors.

**Characteristics**

* OpenTelemetry semantic conventions are used in some areas  
* Inconsistencies remain across signals or subsystems  
* Legacy attributes coexist with standard ones  
* Users still need some project-specific knowledge

**Example scenarios**

* Traces use OpenTelemetry HTTP attributes, but metrics expose different labels for the same concepts.  
* Logs are structured, but do not follow OpenTelemetry log semantic conventions.  
* Dashboards work for some signals but require custom queries for others.

At this level, telemetry begins to look familiar to OpenTelemetry users, but still contains sharp edges.

### Level 2: OpenTelemetry-Native

At this level, OpenTelemetry semantic conventions are applied *consistently and deliberately* across the project. Telemetry meaning is predictable and interoperable without requiring project-specific interpretation.

Semantic alignment becomes a design constraint rather than an afterthought.

**Characteristics**

* Current OpenTelemetry semantic conventions are used wherever applicable  
* Naming and meaning are consistent across traces, metrics, and logs  
* Deprecated fields are removed or migrated intentionally  
* Telemetry can be interpreted using generic OpenTelemetry knowledge

**Example scenarios**

* A user can apply off-the-shelf dashboards or alerts and get meaningful results.  
* Contributors know which semantic conventions to use without guesswork.  
* Correlation across signals works naturally because shared attributes align.

At this level, telemetry integrates smoothly into the broader OpenTelemetry ecosystem.

### Level 3: Semantic Extension & Stewardship

At this level, the project goes beyond alignment and takes *active responsibility for semantic design*. Domain-specific concepts are modeled explicitly, and extensions are introduced in a controlled, transparent way.

This level reflects stewardship rather than customization for its own sake.

**Characteristics**

* Domain-specific semantics are defined explicitly and documented  
* Custom conventions are versioned, reviewed, and treated as part of the project’s public contract  
* Tooling such as [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver) may be used to define, generate, and validate semantic conventions across languages and signals  
* Extensions complement, rather than replace, upstream conventions  
* Changes are evaluated for downstream impact

**Example scenarios**

* A workflow engine defines a small, well-scoped set of custom attributes to represent workflow state transitions.  
* OpenTelemetry Weaver is used to define and generate semantic conventions across languages.  
* A proposal to change semantic meaning includes migration guidance for users and tooling.  
* A project defines and maintains its domain-specific semantic conventions using a schema-driven workflow, enabling consistent code generation, documentation, and validation across signals.

At this level, semantic conventions are treated as a long-lived contract that evolves alongside the project.

A project cannot be considered Level 3 on this dimension if a first-class signal (e.g. traces, metrics, or logs) uses a proprietary or internal schema in cases where stable OpenTelemetry semantic conventions exist, unless the project explicitly documents that schema as a semantic extension and describes how it maps to or extends OpenTelemetry conventions (for example, via a Weaver-style workflow).

### Summary for Semantic Conventions

Semantic conventions determine whether telemetry scales beyond a single project or team. As maturity increases, the burden of interpretation shifts from the user to the project, enabling interoperability, reuse, and trust.

Progression along this dimension reflects a shift from:

* implicit meaning → explicit contracts  
* local conventions → shared language  
* incidental alignment → intentional stewardship

## Dimension: Resource Attributes & Configuration

### What this dimension captures

This dimension describes *how a project expresses stable identity and how telemetry is configured across environments*.

Resource attributes define *what is producing telemetry* (for example service name, version, deployment environment), while configuration determines *how telemetry behaves* (export endpoints, sampling, processors, etc.). Confusion in this area is a frequent source of broken correlation, duplicated data, and surprising behavior once telemetry moves beyond local development.

As maturity increases, projects move from hard-coded or project-specific configuration toward predictable, OpenTelemetry-native behavior that works consistently across environments and signals.

### Level 0: Instrumented

At this level, resource identity and configuration are largely implicit. Identity is often derived from local assumptions, and configuration is handled through project-specific flags or defaults.

**Characteristics**

* Resource attributes are incomplete, inconsistent, or hard-coded  
* Identity differs between environments or signals  
* Configuration is handled through custom flags or config files  
* OpenTelemetry environment variables are ignored or overridden

**Example scenarios**

* `service.name` is set differently for metrics and traces.  
* The project hard-codes a service name that cannot be overridden in production.  
* Users set `OTEL_EXPORTER_OTLP_ENDPOINT`, but the project ignores it in favor of its own configuration.  
* Attributes like environment or version are duplicated on spans instead of being expressed as resource attributes.

At this level, telemetry may work locally, but breaks down when deployed at scale or integrated into shared pipelines.

### Level 1: OpenTelemetry-Aligned

At this level, resource attributes and OpenTelemetry configuration are present, but not yet treated as a coherent system. Some standard behavior is supported, while project-specific logic still takes precedence in places.

**Characteristics**

* Resource attributes exist but are not consistently applied  
* Configuration precedence between project settings and `OTEL_*` variables is unclear  
* Some attributes are duplicated across resource and span scope  
* Behavior may vary between signals or runtimes

**Example scenarios**

* `service.name` is set as a resource attribute for traces, but added manually as a span attribute elsewhere.  
* `OTEL_RESOURCE_ATTRIBUTES` is partially respected, but overridden by project defaults.  
* Sampling configuration works for traces but cannot be controlled via standard OpenTelemetry settings.

At this level, users can often make things work, but must understand project-specific quirks.

### Level 2: OpenTelemetry-Native

At this level, resource identity and configuration follow OpenTelemetry conventions consistently. The project relies on OpenTelemetry SDKs to handle configuration and avoids re-implementing this logic.

Identity is stable, predictable, and shared across all signals.

**Characteristics**

* Resource attributes are the single source of *service identity*  
* Attributes are placed in the correct scope (resource vs span vs metric)  
* `OTEL_*` environment variables are respected end-to-end via the SDK  
* Configuration behaves consistently across environments and signals

At this level, the following distinctions apply:

***Required at the source:***

* A stable and meaningful [`service.name`](http://service.name)  
* Consistent service identity across traces, metrics, and logs  
* Respect for standard OpenTelemetry configuration mechanisms (for example, `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES` where applicable)

***Allowed to be pipeline-derived:***

* Kubernetes cluster, node, pod, and workload attributes  
* Cloud-provider or infrastructure metadata  
* Attributes typically provided by standard OpenTelemetry resource detection processors

**Example scenarios**

* `service.name`, `service.version`, and environment are defined once and appear consistently across traces, metrics, and logs.  
* Users can configure exporters, endpoints, and sampling using standard OpenTelemetry variables without project-specific flags.  
* Telemetry from multiple components correlates naturally because resource identity is stable.

At this level, telemetry configuration feels familiar to OpenTelemetry users and predictable across deployments.

### Level 3: OpenTelemetry-Optimized

At this level, resource identity and configuration are treated as part of the project’s operational contract. Behavior is explicitly documented, validated, and evolved with user impact in mind.

The project anticipates diverse deployment environments and avoids surprising behavior.

**Characteristics**

* Resource attribute behavior is documented and stable  
* Configuration precedence is explicit and predictable  
  Changes to identity or configuration are reviewed carefully  
* The project avoids duplicating or mutating resource attributes at runtime

**Example scenarios**

* Documentation clearly explains how `OTEL_RESOURCE_ATTRIBUTES` and project defaults interact.  
* Changes to resource naming or scoping include migration guidance.  
* Users can move between environments (local, staging, production) without needing to relearn telemetry configuration.

At this level, resource identity and configuration enable large-scale observability rather than becoming a source of friction.

### Summary for Resource Attributes & Configuration

Stable identity and predictable configuration are prerequisites for meaningful correlation and long-term trust in telemetry. As maturity increases, projects shift from implicit assumptions to explicit contracts, reducing surprises for users and maintainers alike.

Progression along this dimension reflects a shift from:

* hard-coded identity → stable resource attributes  
* project-specific config → OpenTelemetry-native configuration  
* incidental behavior → documented, intentional design

## Dimension: Trace Modeling & Context Propagation

### What this dimension captures

This dimension describes *how a project models execution as traces and how trace context flows through the system,* especially across asynchronous, distributed, or internal boundaries.

Trace modeling and context propagation are tightly coupled in practice. Decisions about parent–child relationships, span links, and trace boundaries determine how users understand execution. Context propagation determines whether those decisions actually hold together at runtime.

When this dimension is immature, traces may technically exist but fail to tell a coherent story. As maturity increases, traces increasingly reflect the *user’s mental model* of how the system behaves, even when execution is asynchronous or graph-shaped.

### Level 0: Instrumented

At this level, spans are emitted, but trace structure and context propagation are largely incidental. Traces often reflect local implementation details rather than meaningful execution flow.

**Characteristics**

* Traces are flat, fragmented, or disconnected  
* Parent–child relationships are inconsistent or missing  
* Context propagation works only at obvious ingress points  
* Span links are rarely used or misunderstood

**Example scenarios**

* A user sees multiple short traces for what they believe is a single request.  
* Internal background work produces spans, but they are detached from any originating trace.  
* Contributors add spans without considering how they relate to existing execution context.  
* Debugging requires mentally stitching together multiple traces or logs.

At this level, tracing can help with low-level debugging but does not support end-to-end reasoning.

### Level 1: OpenTelemetry-Aligned

At this level, trace modeling and propagation work for common, synchronous execution paths. OpenTelemetry context propagation mechanisms are in place, but complex or asynchronous flows still create gaps.

This is often where projects land after “doing the right things” at boundaries but before addressing internal execution models.

**Characteristics**

* Parent–child relationships are mostly correct for request/response flows  
* Context propagation works across common framework boundaries  
* Asynchronous or background execution may still fragment traces  
* Span links may be introduced inconsistently as a "patch" for internal propagation failures where parent-child relationships are missing

**Example scenarios**

* HTTP requests produce coherent traces, but async workflows break the trace into multiple segments.  
* A retry or fan-out operation appears as a separate trace rather than part of the original execution.  
* Maintainers add span links to “connect” traces without fully addressing propagation gaps.

At this level, traces look correct at first glance but can become confusing under load or complexity.

### Level 2: OpenTelemetry-Native

At this level, trace modeling and context propagation are *designed intentionally*. The project explicitly defines what constitutes a logical unit of work and how execution should appear to users.

Trace structure is treated as a design choice, not an implementation side effect.

**Characteristics**

* Clear decisions about parent–child relationships versus span links  
* Context propagation is explicit across internal APIs and execution models  
* Traces represent meaningful logical operations  
* Asynchronous execution preserves trace continuity where appropriate

**Example scenarios**

* A workflow execution forms a coherent trace tree, even though work is executed asynchronously.  
* Fan-out work uses span links intentionally, with clear documentation of their meaning.  
* Contributors understand when to create a new root span versus attaching to existing context.

At this level, traces tell a consistent, interpretable story that matches user expectations.

### Level 3: OpenTelemetry-Optimized

At this level, trace modeling and propagation are refined based on real-world usage and scale. The project anticipates complex execution patterns and actively optimizes for clarity and correctness.

Trace design becomes part of the project’s architectural discipline.

**Characteristics**

* Trace topology supports complex async, streaming, or graph-shaped execution  
* Context propagation is validated and maintained over time  
* Trace behavior is documented and tested as part of the system  
* Trade-offs between trace completeness and cost are considered explicitly

**Example scenarios**

* Long-lived workflows, retries, and replays appear coherently in traces without overwhelming users.  
* Trace modeling decisions are discussed in design reviews.  
* Users can reason about system behavior using traces without deep knowledge of internals.

At this level, tracing becomes a reliable tool for understanding complex systems, not just inspecting individual operations.

### Summary for Trace Modeling & Context Propagation

Trace modeling and context propagation determine whether traces reflect how systems actually behave or merely how code is structured. As maturity increases, projects move from incidental tracing to intentional storytelling.

Progression along this dimension reflects a shift from:

* fragmented traces → coherent execution narratives  
* implicit propagation → explicit design  
* local correctness → user-centered understanding

## Dimension: Multi-Signal Observability

### What this dimension captures

This dimension describes *how a project supports traces, metrics, and logs together*, and how effectively those signals can be correlated to form a coherent observability experience.

Many projects begin by focusing on a single signal—most commonly metrics. As systems grow more complex, users increasingly expect to move fluidly between signals: starting from a metric, drilling into traces, and validating hypotheses with logs. When signals are emitted independently, observability becomes fragmented and harder to use.

As maturity increases, projects move from single-signal exposure toward *intentional, correlated multi-signal observability*.

### Level 0: Instrumented

At this level, the project focuses on a single signal, typically chosen based on immediate operational needs or historical precedent.

**Characteristics**

* Only one signal is first-class (often metrics)  
* Other signals are missing or experimental  
* Signals are designed independently  
* No correlation context is shared

**Example scenarios**

* The project exposes Prometheus metrics but provides no tracing support.  
* Logs exist but are unstructured or lack any correlation identifiers.  
* Users must switch tools and manually align timestamps to understand behavior.

At this level, observability supports basic monitoring but not deep investigation.

### Level 1: OpenTelemetry-Aligned

At this level, multiple signals are emitted, often through OpenTelemetry, but they are still loosely connected. Signals coexist rather than working together.

This stage commonly reflects incremental adoption: adding tracing or logs without revisiting the overall observability model.

**Characteristics**

* Traces, metrics, and logs are all present  
* Signals are emitted independently  
* Correlation context may exist in some signals but not others  
* Users must manually bridge gaps

**Example scenarios**

* Traces include trace IDs, but logs do not.  
* Metrics describe high-level behavior, but cannot be tied to specific traces.  
* Users can diagnose issues, but only with effort and domain knowledge.

At this level, observability improves, but cognitive load remains high. To reach Level 2, all three signals must be available as supported first-class outputs in the project’s recommended deployment model, and correlation must not depend on ad-hoc parsing.

### Level 2: OpenTelemetry-Native

At this level, the project treats observability as a *multi-signal system*. Traces, metrics, and logs are designed together and intentionally correlated.

Signals reinforce one another rather than duplicating or conflicting.

**Characteristics**

* All three signals are first-class  
* Logs include trace and span context  
* Metrics complement traces instead of replacing them  
* Signal relationships are consistent and predictable

**Example scenarios**

* A user starts from a latency metric, drills into a trace, and inspects correlated logs without switching mental models.  
* Logs automatically include trace and span identifiers without manual instrumentation.  
* Metrics describe aggregate behavior, while traces explain individual executions.

At this level, observability workflows feel natural and efficient.

### Level 3: OpenTelemetry-Optimized

At this level, multi-signal observability is refined based on real-world usage, cost, and scale. The project actively optimizes how signals work together.

The focus shifts from “having all signals” to *making them useful together*.

**Characteristics**

* Signal volume and cardinality are managed intentionally  
* Signals are shaped for common investigative workflows  
* Trade-offs between cost, detail, and clarity are explicit  
* Signal design evolves based on user feedback

**Example scenarios**

* High-cardinality metrics are avoided in favor of trace-driven investigation.  
* Logs are sampled or filtered intelligently while preserving correlation.  
* Documentation guides users on when to use which signal.

At this level, observability supports fast, confident decision-making at scale.

### Summary for Multi-Signal Observability

Multi-signal observability determines whether users can move from symptoms to root cause without friction. As maturity increases, projects shift from isolated signals to cohesive investigative workflows.

Progression along this dimension reflects a shift from:

* single-signal monitoring → multi-signal reasoning  
* manual correlation → automatic correlation  
* raw data → guided investigation

## Dimension: Audience & Signal Quality

#### What this dimension captures

This dimension describes who telemetry is designed for and how usable it is by default.

Telemetry is not consumed in a vacuum. It is read by operators during incidents, by developers during debugging, by platform teams maintaining shared tooling, and increasingly by automated systems. When telemetry is shaped primarily around internal implementation details or maintainer convenience, it may be technically correct but practically unusable.

Audience and signal quality capture whether telemetry:

* communicates meaningful system behavior  
* minimizes unnecessary noise and cognitive load  
* supports common investigative questions without extensive customization

As maturity increases, projects move from emitting “everything that is easy to emit” toward emitting *intentional, high-quality signals designed for real operational use.*

### Level 0: Instrumented

At this level, telemetry is primarily designed to support maintainers and contributors during development. Signal quality is incidental rather than intentional.

**Characteristics**

* Telemetry is verbose, noisy, or inconsistent  
* Logs and spans expose internal implementation details  
* Little distinction between debug and operational signals  
* Defaults are unsuitable for production use

**Example scenarios**

* Logs include large volumes of low-value debug output by default.  
* Spans contain internal function names or IDs that are not meaningful to users.  
* Operators must heavily filter or rewrite telemetry before it becomes usable.

At this level, telemetry exists, but users must do significant work to extract value from it.

### Level 1: OpenTelemetry-Aligned

At this level, some effort is made to reduce noise and improve clarity, but telemetry is still largely shaped by internal perspectives.

**Characteristics**

* Obvious noise is reduced, but defaults remain conservative  
* Some signals are user-oriented, others remain maintainer-focused  
* Telemetry usability varies across signals  
* Operators need domain knowledge to interpret data

**Example scenarios**

* Access logs are structured, but still include excessive low-value fields.  
* Traces are coherent, but span names reflect internal components rather than user actions.  
* Operators can diagnose issues, but with significant cognitive effort.

At this level, telemetry is improving, but usability is inconsistent.

### Level 2: OpenTelemetry-Native

At this level, telemetry is intentionally designed for its audience. Defaults are shaped around common operational and debugging workflows.

**Characteristics**

* Telemetry defaults are usable without extensive customization  
* Noise is actively controlled through sampling, aggregation, or filtering  
* Signals communicate user-relevant behavior  
* Telemetry supports common investigative questions

**Example scenarios**

* Span names describe logical operations rather than internal code paths.  
* Logs are structured and focused on events operators care about.  
* Operators can move from symptoms to causes without deep internal knowledge.

At this level, telemetry feels approachable, predictable, and useful.

### Level 3: OpenTelemetry-Optimized

At this level, signal quality is actively optimized based on real-world usage, scale, and feedback. Telemetry is treated as a product surface with explicit quality goals.

**Characteristics**

* Signal volume, cardinality, and cost are managed intentionally  
* Telemetry quality is evaluated continuously using objective, repeatable criteria (for example, rule-based checks aligned with community efforts such as the [Instrumentation Score](https://github.com/instrumentation-score/spec) specification)  
* Defaults are refined based on user feedback  
* Trade-offs between detail and clarity are explicit

**Example scenarios**

* High-cardinality signals are avoided or reshaped in favor of trace-driven investigation.  
* Logs are sampled or filtered while preserving correlation and meaning.  
* Telemetry quality regressions are detected and addressed proactively.

At this level, telemetry supports fast, confident decision-making at scale.

### Summary for Audience & Signal Quality

Audience and signal quality determine whether telemetry reduces or increases cognitive load. As maturity increases, projects shift from exposing raw internal signals to delivering *intentional***,** *high-quality telemetry that serves the people who rely on it*.

Progression along this dimension reflects a shift from:

* maintainer-centric output → user-oriented signals  
* raw verbosity → meaningful clarity  
* accidental noise → intentional quality

At higher maturity levels, signal quality is no longer assumed; it is verified through explicit criteria and feedback loops that reflect how telemetry is actually consumed.

## Dimension: Stability & Change Management

### What this dimension captures

This dimension describes *how telemetry evolves over time once users depend on it*, and how changes to telemetry are managed, communicated, and governed.

As OpenTelemetry adoption matures, telemetry stops being an internal implementation detail and becomes part of the project’s public surface. Dashboards, alerts, runbooks, automation, and even business decisions may depend on specific spans, attributes, and metrics. Unannounced or poorly managed changes can silently break user workflows and erode trust.

As maturity increases, projects shift from treating telemetry as “best effort” output to treating it as a *stable, evolving contract.*

### Level 0: Instrumented

At this level, telemetry changes are largely untracked and unmanaged. Instrumentation evolves opportunistically as code changes, without consideration for downstream consumers.

**Characteristics**

* Telemetry changes are undocumented  
* Span names, attributes, or metric definitions change without notice  
* No distinction between internal refactors and user-visible changes  
* Users discover breakage after the fact

**Example scenarios**

* A span name changes during a refactor, breaking dashboards with no explanation.  
* An attribute is removed because it is “no longer needed internally,” even though users rely on it.  
* A minor release unintentionally alters telemetry shape.

At this level, telemetry is fragile and difficult to rely on for long-term operations.

### Level 1: OpenTelemetry-Aligned

At this level, maintainers are aware that telemetry changes have impact, but handling is informal and inconsistent.

Changes may be communicated, but without a clear process or expectations.

**Characteristics**

* Some telemetry changes are mentioned in release notes  
* Breaking changes are discovered reactively  
* No clear distinction between stable and experimental telemetry  
* Users must adapt frequently

**Example scenarios**

* A release note briefly mentions “updated tracing,” without detailing what changed.  
* Users learn about telemetry changes through GitHub issues or broken alerts.  
* Maintainers debate whether telemetry changes are “breaking changes” at all.

At this level, intent exists, but governance is still emerging.

### Level 2: OpenTelemetry-Native

At this level, telemetry is treated as part of the project’s public contract. Changes are made intentionally and communicated clearly.

The project recognizes that telemetry stability is essential for trust and adoption.

**Characteristics**

* Telemetry changes are documented and communicated explicitly  
* Breaking changes are called out in release notes  
* Stable versus experimental telemetry is distinguished  
* Changes are reviewed with downstream impact in mind

**Example scenarios**

* Renaming a span includes migration guidance for dashboards and alerts.  
* New telemetry fields are introduced without removing existing ones.  
* Maintainers consider telemetry impact during design and review discussions.

At this level, users can safely build operational workflows on top of telemetry.

### Level 3: OpenTelemetry-Optimized

At this level, telemetry evolution is planned, reviewed, and governed deliberately. Stability and change management are proactive rather than reactive.

Telemetry is treated as a long-lived interface that evolves alongside the project.

**Characteristics**

* Telemetry changes follow a defined review process  
* Deprecation and migration strategies are standard practice  
* Telemetry stability is discussed alongside API stability  
* User feedback influences telemetry evolution  
* Changes to telemetry are assessed not only for compatibility, but also for their impact on signal quality, noise, and usability

**Example scenarios**

* A proposal to change trace structure includes rationale, alternatives, and migration plans.  
* Deprecated telemetry fields remain available across multiple releases.  
* Telemetry evolution is informed by how users actually consume the data.

At this level, telemetry becomes a dependable foundation rather than a moving target.

### Summary for Stability & Change Management

Stability and change management determine whether users can *trust telemetry over time*. As maturity increases, projects move from accidental change to intentional evolution.

Progression along this dimension reflects a shift from:

* implicit behavior → explicit contracts  
* reactive fixes → planned evolution  
* fragile dashboards → stable operational workflows

# Conclusion: Using the OpenTelemetry Support Maturity Model

OpenTelemetry has moved from being an emerging standard to becoming a foundational part of the cloud native ecosystem. As a result, expectations around OpenTelemetry support in CNCF projects have changed. Users increasingly rely on telemetry not only for debugging, but for operating, scaling, and evolving systems in production.

This maturity model is intended to help projects and users reason about that evolution. It recognizes that OpenTelemetry support is not a single capability, but a collection of interrelated concerns that mature at different rates: integration, semantics, configuration, trace modeling, signal correlation, usability, and stability.

The goal of the model is not to drive projects toward a single “correct” state, but to make trade-offs visible and progress intentional.

## Applying the Model in Practice

### For Project Maintainers

Maintainers can use this model to:

* assess current OpenTelemetry support dimension by dimension  
* identify areas where user friction is likely to occur  
* guide design discussions and roadmap prioritization  
* align contributors around shared expectations

Importantly, the model can help separate *necessary complexity* from *accidental complexity*. Not every project needs to reach the highest maturity level in every dimension, but understanding where maturity gaps exist makes decisions explicit rather than implicit.

### For Contributors

Contributors can use the model as:

* a guide for proposing improvements  
* a way to frame pull requests and design discussions  
* a shared vocabulary when discussing telemetry changes

Instead of debating individual implementation details in isolation, contributors can anchor discussions in broader maturity goals, such as improving integration surface consistency or reducing cognitive load for users.

### For Users and Platform Teams

Users and platform teams can use the model to:

* evaluate whether a project fits their observability expectations  
* understand what kinds of telemetry behavior to expect  
* anticipate integration effort when adopting a project

The maturity model also helps explain *why* certain projects behave differently, without framing those differences as defects. A project at an earlier maturity level may still be a good fit, depending on context and requirements.

# Relationship to Other CNCF Maturity Models

This model is intentionally aligned with the CNCF Platform Engineering Maturity Model in both structure and philosophy.

In the same way that platform maturity evolves from ad-hoc enablement to product-oriented platforms and finally to optimized ecosystems, OpenTelemetry support evolves from basic instrumentation to intentional, user-centered observability design.

Both models emphasize:

* multi-dimensional maturity  
* progression over time rather than static assessment  
* the importance of explicit contracts and user experience

Together, these models reinforce the idea that observability is not just a tooling concern, but a platform capability that benefits from deliberate design and stewardship.

# Final Thoughts

Effective OpenTelemetry support is not achieved by emitting more data, but by emitting *better, more intentional telemetry.* The most mature projects treat observability as part of their public interface, design telemetry with users in mind, and evolve it carefully over time.

This maturity model provides a shared framework for understanding that journey. Whether used for self-assessment, discussion, or planning, its value lies in helping teams ask better questions about how their telemetry serves the people who rely on it.

# **Appendix: Evaluation Checklist (Reference Guide)**

# Appendix: Evaluation Checklist (Reference Guide)

This checklist is provided as a *reference guide* to support consistent evaluation and discussion across projects.

It is intentionally extensive and non-exhaustive. Not every item applies to every project, and presence or absence of individual items does not determine maturity in isolation.

The checklist is designed to help reviewers ask the *right questions* when assessing each maturity dimension.

## Dimension: Integration Surface

A mature integration surface minimizes friction, avoids adapters, and allows users to reuse their existing observability infrastructure.

### Level 0: Instrumented

At this level, telemetry exists, but *OpenTelemetry is not a primary integration concern*.

#### Questions to ask

* Is telemetry exported only via tool-specific or legacy exporters?  
  * e.g. Jaeger exporter only  
  * e.g. Prometheus scraping only  
* Is OTLP unsupported or available only indirectly?  
  * via sidecars, adapters, or custom bridges  
* Does telemetry configuration rely on project-specific flags or config files?  
  * e.g. `--enable-tracing`  
  * e.g. `telemetry.enabled=true`  
* Do users need to adapt their observability stack to the project?  
* Is OpenTelemetry absent from the documentation or treated as an afterthought?

#### Concrete examples

* Project emits Jaeger spans but cannot export OTLP  
* Metrics are only exposed via `/metrics` with no OTLP option  
* Users must deploy a project-specific sidecar to extract telemetry  
* Export configuration is embedded in application config

#### Strong indicators of Level 0

* No mention of OpenTelemetry in docs  
* Telemetry integration varies widely between deployments  
* Centralized OpenTelemetry Collectors cannot be reused

### Level 1: OpenTelemetry-Aligned

At this level, OpenTelemetry is *supported*, but not central.

#### Questions to ask

* Is OTLP supported, but alongside equally promoted legacy exporters?  
  * e.g. OTLP and Jaeger documented side-by-side  
* Are there multiple, overlapping ways to configure telemetry?  
  * project flags \+ OTEL\_\* variables  
* Do users need to disable legacy behavior to make OTLP work cleanly?  
* Are OpenTelemetry SDKs or Collector components present but optional?  
* Is OpenTelemetry integration inconsistent across signals?

#### Concrete examples

* OTLP export exists but requires enabling experimental flags  
* Jaeger exporter remains the default  
* Metrics use Prometheus scraping, traces use OTLP  
* Configuration differs between traces, metrics, and logs

#### Strong indicators of Level 1

* “We support OpenTelemetry” with caveats  
* Users must read multiple docs to get it right  
* Integration works, but feels bolted on

### Level 2: OpenTelemetry-Native

At this level, OpenTelemetry is the *primary integration surface*.

#### Questions to ask

* Is OTLP the default or clearly recommended export path?  
* Are standard OpenTelemetry environment variables respected?  
  * `OTEL_EXPORTER_OTLP_ENDPOINT`  
  * `OTEL_EXPORTER_OTLP_PROTOCOL`  
  * `OTEL_SERVICE_NAME`  
* Can users connect the project to an existing OpenTelemetry Collector without adapters or glue code?  
* Are legacy exporters clearly secondary or deprecated?  
* Is telemetry configuration consistent across signals?

#### Concrete examples

* OTLP enabled by default  
* Users configure telemetry entirely via OTEL\_\* variables  
* One Collector handles telemetry from multiple components  
* Prometheus scraping remains optional, not required

#### Strong indicators of Level 2

* OpenTelemetry is the “happy path”  
* Documentation recommends OTLP first  
* Integration works with minimal configuration  
* Users can standardize observability across projects

### Level 3: OpenTelemetry-Optimized

At this level, the integration surface is intentionally designed, governed, and stable.

#### Questions to ask

* Is the telemetry integration surface documented as a stable contract?  
* Are telemetry integration changes reviewed like API changes?  
* Are breaking changes clearly communicated with migration guidance?  
* Are legacy exporters removed or tightly scoped?  
* Does the project explicitly consider different deployment models and observability backends?

#### Concrete examples

* Telemetry integration is versioned and documented  
* Migration guides exist for telemetry-related changes  
* Project supports shared, centralized Collectors cleanly  
* Integration works across:  
  * local development  
  * Kubernetes  
  * managed platforms

#### Advanced indicators

* Telemetry integration appears in architecture diagrams  
* Backward compatibility is explicitly considered  
* Observability is treated as part of the platform contract

## Dimension: Semantic Conventions

Semantic conventions are one of the strongest predictors of whether telemetry will remain usable, interoperable, and trustworthy over time.

### Level 0: Instrumented

At this level, telemetry exists, but *meaning is implicit, accidental, or internal.*

#### Questions to ask

* Are attribute names ad-hoc or derived from internal variable names?  
  * `status`  
  * `statusCode`  
  * `httpStatus`  
  * `resp_code`  
* Are deprecated OpenTelemetry attributes used unintentionally?  
  * `http.method`  
  * `http.status_code`  
  * `http.target`  
* Are different names used for the same concept across signals?  
  * traces: `http.method`  
  * metrics: `method`  
  * logs: `request_method`  
* Are attributes overloaded with multiple meanings?  
  * `name` used for route, service, component, or operation  
* Is semantic meaning encoded in span names instead of attributes?  
  * e.g. `handleRequest_user_v2`  
  * e.g. `route_match_success`  
* Do users need to inspect source code or internal docs to understand telemetry meaning?

#### Strong indicators of Level 0

* No reference to OpenTelemetry semantic conventions in documentation  
* Attribute names mirror internal structs or variable names  
* Dashboards normalize or rename attributes manually  
* Telemetry meaning changes silently over time  
* Cross-project tooling cannot interpret telemetry reliably

### Level 1: OpenTelemetry-Aligned

At this level, OpenTelemetry conventions are *partially adopted*, but inconsistently applied.

#### Questions to ask

* Are *some* OpenTelemetry semantic conventions used?  
  * e.g. `http.method` instead of generic `method`  
* Are deprecated and current fields mixed?  
  * `http.status_code` **and** `http.response.status_code`  
* Are conventions applied primarily to traces, but not to logs or metrics?  
* Are similar concepts named differently across signals?  
* Are attribute types inconsistent?  
  * HTTP status sometimes string, sometimes integer  
* Are URL and request attributes fragmented?

#### Concrete examples

* Traces use `http.method`, logs use `method`  
* Metrics expose `http_status` instead of `http.response.status_code`  
* URL information split across:  
  * `http.url`  
  * `http.target`  
  * `url.path`  
* Span attributes follow conventions, but log fields do not  
* Custom dashboards must reconcile naming differences

#### Strong indicators of Level 1

* “Mostly OpenTelemetry, but…” explanations  
* Migration appears partial or ongoing  
* Users need signal-specific interpretation knowledge  
* Tooling works only after customization or normalization

### Level 2: OpenTelemetry-Native

At this level, *current semantic conventions are applied intentionally and consistentl***y** across all signals.

#### Questions to ask

* Are **current, stable OpenTelemetry semantic conventions** used?  
  * `http.request.method`  
  * `http.response.status_code`  
  * `url.path`  
  * `url.full`  
* Are deprecated attributes fully removed or explicitly gated?  
  * No `http.method`  
  * No `http.status_code`  
  * No `http.target`  
* Are attributes aligned across traces, metrics, and logs?  
* Are attributes placed in the correct scope?  
  * request metadata on spans  
  * identity on resources  
  * event-like data on logs  
* Can telemetry be interpreted using **generic OpenTelemetry knowledge**, without project-specific mapping?

#### Concrete checks

* Logs reuse trace attributes instead of redefining them  
* Metrics share attribute keys with traces where meaningful  
* Attribute names and types are consistent across signals  
* URL fields are modeled using `url.*`, not legacy HTTP fields  
* Off-the-shelf dashboards and alerts work without normalization

#### Strong indicators of Level 2

* Minimal downstream enrichment required  
* Semantic conventions explicitly referenced in documentation  
* Telemetry “just works” with common OpenTelemetry tooling  
* Users do not need project-specific semantic knowledge

### Level 3: OpenTelemetry-Optimized

At this level, the project treats semantics as a *designed, governed interface.*

#### Questions to ask

* Are domain-specific concepts modeled **explicitly**, rather than implicitly?  
  * gateway routing decisions  
  * policy evaluation outcomes  
  * request classification  
  * workflow or state transitions  
* Are custom attributes documented with:  
  * name  
  * type  
  * semantic meaning  
* Do custom attributes **extend** OpenTelemetry conventions rather than replace them?  
* Are semantic changes versioned and reviewed?  
* Is there a defined process for evolving semantics over time?  
* If a first-class signal uses a proprietary schema where stable OpenTelemetry semantic conventions exist, is that schema explicitly documented as an extension and mapped to OpenTelemetry semantics?

#### Concrete examples (from ingress / gateway work)

* Instead of overloading `http.route`, introduce:  
  * `gateway.route.id`  
  * `gateway.route.match_type`  
* Instead of embedding logic in span names, expose:  
  * `gateway.decision`  
  * `gateway.backend.selected`  
* Explicit attributes for:  
  * retries  
  * policy evaluation results  
  * routing outcomes  
* Attributes reflect **domain concepts**, not implementation details

#### Advanced indicators

* Schema-driven semantic definitions  
* Weaver-style workflows for generation and validation  
* Clear compatibility and migration guidance  
* Semantic changes evaluated for downstream impact  
* Semantics treated as part of the public contract

## Dimension: Resource Attributes & Configuration

Correct resource modeling is foundational for correlation, aggregation, and long-term usability of telemetry.

### Level 0: Instrumented

At this level, identity exists only implicitly, or is inferred inconsistently.

#### Questions to ask

* Is `service.name` hard-coded, implicit, or unstable?  
  * e.g. always `proxy`, `gateway`, or `app`  
* Does `service.name` differ across signals?  
  * traces use one value, metrics another  
* Are key identity attributes missing?  
  * no `service.version`  
  * no instance identity  
* Are identity attributes attached to spans instead of resources?  
* Is `OTEL_RESOURCE_ATTRIBUTES` ignored or overridden?  
* Is the environment or deployment context embedded in span attributes or log fields?

#### Concrete examples

* `service.name=proxy` for all environments and deployments  
* `service.version` absent or derived from image tags at runtime  
* Instance identity inferred from span IDs  
* Environment info attached as `env=prod` on spans  
* No Kubernetes or platform attributes at the source

#### Strong indicators of Level 0

* Telemetry cannot be reliably grouped  
* Correlation depends on downstream enrichment  
* Identity changes unintentionally between releases  
* Users must reverse-engineer identity from context

### Level 1: OpenTelemetry-Aligned

At this level, some resource attributes exist, but *behavior is inconsistent or underspecified*.

#### Questions to ask

* Are some resource attributes set, but inconsistently?  
* Is `service.name` stable, but other identity fields missing?  
* Is configuration precedence unclear?  
  * project config vs `OTEL_*`  
* Are resource attributes injected later in the pipeline?  
  * e.g. via Collector processors only  
* Does identity differ across signals or exporters?  
* Are OpenTelemetry resource detectors partially relied on?

#### Concrete examples

* `service.name` set, but no `service.version`  
* Kubernetes attributes added only by Collector enrichment  
* Different identity behavior between traces and metrics  
* `OTEL_RESOURCE_ATTRIBUTES` works in some environments, not others  
* Sampling or exporter config behaves differently per signal

#### Strong indicators of Level 1

* “Mostly correct” identity  
* Users need environment-specific overrides  
* Grouping works sometimes, breaks in edge cases  
* Identity knowledge lives in tribal documentation

### Level 2: OpenTelemetry-Native

At this level, *resource attributes are the single source of identity*, applied consistently at the source.

#### Questions to ask

* Are resource attributes used as the authoritative identity?  
  * `service.name`  
  * `service.version`  
  * `service.instance.id`  
* Are OpenTelemetry configuration mechanisms respected end-to-end?  
  * `OTEL_SERVICE_NAME`  
  * `OTEL_RESOURCE_ATTRIBUTES`  
* Is identity stable across:  
  * restarts  
  * scaling  
  * environments  
* Are identity attributes placed correctly?  
  * identity on resources, not spans  
* Are platform or infrastructure attributes available through a documented, standard OpenTelemetry resource detection or enrichment pipeline (rather than custom parsing)?

#### Concrete Kubernetes checks (often pipeline-derived)

These attributes are commonly added by standard OpenTelemetry resource detectors or  
Collector processors are not required to be emitted at the source for Level 2\.

* Are the following present where applicable?  
  * `k8s.namespace.name`  
  * `k8s.pod.name`  
  * `k8s.pod.uid`  
  * `k8s.container.name`  
  * workload identifiers:  
    * `k8s.deployment.name`  
    * `k8s.daemonset.name`  
    * `k8s.statefulset.name`  
  * `k8s.cluster.name`  
  * `k8s.node.name`  
* Is instance identity modeled as:  
  * `service.instance.id = k8s.pod.uid`  
* Are container attributes present when relevant?  
  * `container.id`  
  * `container.name`

#### Strong indicators of Level 2

* Correlation “just works”  
* Grouping and filtering behave predictably  
* No custom or project-specific identity normalization required  
* Users can reason about identity without deep deployment knowledge

### Level 3: OpenTelemetry-Optimized

At this level, *resource modeling and configuration are intentional, governed, and stable over time.*

#### Questions to ask

* Is resource modeling explicitly documented?  
* Is configuration precedence clear and stable?  
  * project defaults vs `OTEL_*`  
* Are identity changes treated as breaking changes?  
* Are resource attributes immutable at runtime?  
* Can users reason about identity across:  
  * shared clusters  
  * multi-tenant deployments  
  * different environments  
* Are migration guides provided for identity changes?

#### Advanced examples

* Clear guidance on:  
  * per-namespace vs per-instance identity  
  * shared gateways vs dedicated deployments  
* No runtime mutation of:  
  * `service.name`  
  * `service.namespace`  
* Resource identity remains stable even when:  
  * scaling replicas  
  * rolling deployments  
* Identity changes follow a documented review process

#### Advanced indicators

* Identity is treated as part of the public contract  
* Resource modeling decisions are revisited intentionally  
* Changes consider downstream impact (dashboards, alerts, SLOs)  
* Users can build long-lived workflows on top of telemetry

## Dimension: Trace Modeling & Context Propagation

Correct trace modeling is what turns “spans exist” into *end-to-end understanding*.

### Level 0: Instrumented

At this level, spans exist, but *trace structure is accidental or misleading*.

#### Questions to ask

* Are spans emitted without meaningful parent–child relationships?  
* Do requests produce multiple unrelated traces?  
* Are root spans created arbitrarily?  
* Is context propagation missing or incomplete?  
* Do asynchronous or background operations create detached traces?

#### Concrete examples

* Each request creates multiple independent traces  
* Entry-point spans have no parents and no children  
* Background work emits spans with new trace IDs  
* Retries create separate traces instead of being linked  
* No `traceparent` or `tracestate` propagation

#### Strong indicators of Level 0

* Traces cannot be followed end-to-end  
* Users must manually correlate spans  
* Async behavior is invisible  
* Trace topology changes unintentionally

### Level 1: OpenTelemetry-Aligned

At this level, tracing works for *simple synchronous flows*, but breaks down in more complex cases.

#### Questions to ask

* Do synchronous request paths produce coherent traces?  
* Does context propagation break for:  
  * async execution  
  * background jobs  
  * fan-out/fan-in  
* Are span links used inconsistently or as a patch?  
* Do retries, redirects, or internal forwarding break trace continuity?  
* Is trace behavior undocumented or implicit?

#### Concrete examples

* HTTP request path is traceable, but async handlers start new traces  
* Span links added to “stitch together” broken propagation  
* Retries appear as independent traces  
* Fan-out creates multiple root spans

#### Strong indicators of Level 1

* “Works for the happy path”  
* Trace completeness depends on execution style  
* Users must know internals to interpret traces  
* Span links are used defensively

### Level 2: OpenTelemetry-Native

At this level, *trace modeling is intentional and documented*.

#### Questions to ask

* Is W3C Trace Context supported and propagated consistently?  
* Are parent–child vs span links used intentionally?  
* Are clear rules defined for:  
  * entry points  
  * internal boundaries  
  * async work  
* Do traces represent logical operations rather than internal calls?  
* Is trace topology stable across retries, fan-out, and async execution?

#### Concrete examples

* Entry-point spans are consistently `SERVER` spans  
* Retries appear as child spans or linked spans, not new traces  
* Async work continues the trace when appropriate  
* Span links used intentionally for:  
  * fan-out  
  * publish/subscribe  
* Trace behavior documented in architecture docs

#### Strong indicators of Level 2

* Traces tell a coherent story  
* Users can reason about behavior without internal knowledge  
* Context propagation “just works”  
* Async execution is visible and understandable

### Level 3: OpenTelemetry-Optimized

At this level, trace modeling is *actively refined, validated, and evolved*.

#### Questions to ask

* Does trace topology support complex async or graph-shaped workflows?  
* Are trace modeling decisions reviewed architecturally?  
* Are trade-offs between completeness, cost, and clarity explicit?  
* Is trace behavior tested or validated over time?  
* Are span links, events, and attributes used to enrich understanding intentionally?

#### Concrete examples

* Graph-shaped traces for event-driven systems  
* Explicit modeling of:  
  * workflow boundaries  
  * retries  
  * policy evaluation  
* Span links used to represent causal relationships  
* Trace modeling discussed alongside system design  
* Trace regressions detected and corrected

#### Advanced indicators

* Trace modeling guidelines exist  
* Changes to trace structure are reviewed  
* Traces support debugging, optimization, and analysis at scale  
* Users trust traces as a reliable representation of system behavior

## Dimension: Multi-Signal Observability

Mature multi-signal observability enables users to move fluidly between signals as part of a single investigative workflow.

### Level 0: Instrumented

At this level, *only one signal is effectively usable,* and others are missing or incidental.

#### Questions to ask

* Is only one signal treated as first-class?  
  * often metrics only  
* Are traces or logs missing, experimental, or undocumented?  
* Is there no shared context between signals?  
* Do users need to manually correlate timestamps across tools?

#### Concrete examples

* Metrics exposed via `/metrics`, no tracing  
* Logs are unstructured text with no trace or span identifiers  
* Traces exist but are incomplete or unused  
* Operators rely entirely on dashboards and alerts

#### Strong indicators of Level 0

* Observability \== monitoring  
* No investigative workflows  
* Signals are siloed  
* Root-cause analysis is slow and manual

### Level 1: OpenTelemetry-Aligned

At this level, **multiple signals exist**, but they are largely independent.

#### Questions to ask

* Are traces, metrics, and logs all present, but loosely coupled?  
* Do some signals include correlation identifiers while others do not?  
* Does investigation require switching tools without context?  
* Are signals produced by different pipelines or configurations?

#### Concrete examples

* Traces include trace IDs, but logs do not  
* Metrics exist but are not connected to traces  
* Logs require manual parsing to extract context  
* Users must know which signal to start with

#### Strong indicators of Level 1

* Signals coexist but do not reinforce each other  
* Correlation is partial or fragile  
* Investigation feels fragmented  
* Users need experience to navigate signals

### Level 2: OpenTelemetry-Native

At this level, *signals are intentionally correlated and designed to work together*.

#### Questions to ask

* Are traces, metrics, and logs all first-class signals?  
* Do logs automatically include `trace_id` and `span_id`?  
* Do metrics share attribute keys with traces where meaningful?  
* Can users pivot naturally between signals?  
* Do signals complement rather than duplicate each other?

#### Concrete examples

* Logs include trace context by default  
* Metrics include dimensions that match trace attributes  
* Users start with metrics, drill into traces, then inspect logs  
* Investigation flows feel natural and predictable

#### Strong indicators of Level 2

* Correlation “just works”  
* No manual stitching required  
* Users can follow symptoms → causes → details  
* Signals reinforce each other

### Level 3: OpenTelemetry-Optimized

At this level, *multi-signal observability is shaped around real investigative workflows*.

#### Questions to ask

* Are signal volume and cardinality managed intentionally across signals?  
* Are high-cardinality metrics avoided in favor of trace-driven analysis?  
* Are signals shaped for common investigative paths?  
* Is guidance provided on when to use which signal?  
* Does the system balance cost, clarity, and depth explicitly?

#### Concrete examples

* Metrics provide high-level signals, traces provide detail  
* Logs are sampled or filtered while preserving correlation  
* Documentation explains investigative workflows  
* Signal design evolves based on user feedback  
* Cost and performance trade-offs are explicit

#### Advanced indicators

* Clear signal design philosophy  
* Explicit guidance for operators and developers  
* Observability feels cohesive, not additive  
* Users trust the system during incidents

## Dimension: Audience & Signal Quality

High-quality telemetry communicates intent, not implementation.

### Level 0: Instrumented

At this level, telemetry is *maintainer-centric and noisy*, optimized for internal debugging rather than operational use.

#### Questions to ask

* Is telemetry verbose and noisy by default?  
* Do span names expose internal function, class, or component names?  
* Are debug and operational signals mixed together?  
* Do logs contain large volumes of low-value information?  
* Do users need extensive filtering to extract value?

#### Concrete examples

* Span names like `process_request_v3`  
* Logs emitted for every internal step  
* No distinction between info, debug, and error signals  
* High-cardinality attributes emitted indiscriminately  
* Operators rely on heavy filtering and sampling downstream

#### Strong indicators of Level 0

* Telemetry overwhelms users  
* Signal-to-noise ratio is low  
* Telemetry increases cognitive load  
* Defaults are unsuitable for production

### Level 1: OpenTelemetry-Aligned

At this level, *some effort is made to improve usability*, but signals are still shaped by internal perspectives.

#### Questions to ask

* Is obvious noise reduced, but defaults remain conservative?  
* Are some signals user-oriented while others remain maintainer-focused?  
* Do operators need domain or implementation knowledge to interpret telemetry?  
* Is signal quality inconsistent across traces, metrics, and logs?

#### Concrete examples

* Fewer debug logs, but still too verbose  
* Some spans renamed to logical operations, others not  
* Logs structured but overly detailed  
* Users can debug issues, but with effort

#### Strong indicators of Level 1

* Telemetry is “better than before,” but not ergonomic  
* Usability varies by signal  
* Operators need experience to interpret data  
* Telemetry still reflects internal structure

### Level 2: OpenTelemetry-Native

At this level, telemetry is *intentionally designed for its audience*, with sensible defaults.

#### Questions to ask

* Are telemetry defaults usable in production without customization?  
* Do span names describe logical, user-relevant operations?  
* Are logs structured around meaningful events?  
* Are metrics focused on operational signals rather than raw counters?  
* Can operators move from symptoms to causes efficiently?

#### Concrete examples

* Span names like `HTTP GET /orders`  
* Logs emitted on state changes or errors, not every step  
* Metrics expose SLO-relevant signals  
* Investigative workflows feel natural and predictable

#### Strong indicators of Level 2

* Telemetry is approachable and useful  
* Minimal downstream filtering required  
* Users can debug issues without internal knowledge  
* Signal design supports common questions

### Level 3: OpenTelemetry-Optimized

At this level, signal quality is *actively optimized based on real-world usage*.

#### Questions to ask

* Are signal quality goals explicit?  
* Are volume, cardinality, and cost managed intentionally?  
* Is telemetry quality evaluated using objective criteria?  
* Are quality regressions detectable over time?  
* Are defaults refined based on user feedback?

#### Concrete examples

* High-cardinality attributes replaced with trace-driven workflows  
* Sampling strategies tuned based on usage  
* Logs filtered while preserving correlation  
* Telemetry quality monitored continuously  
* User feedback informs telemetry evolution

#### Advanced indicators

* Telemetry treated as a product surface  
* Signal design decisions documented  
* Cost and usability trade-offs explicit  
* Telemetry evolves alongside user needs

## Dimension: Stability & Change Management

Mature telemetry is not just correct today \- it remains *trustworthy tomorrow*.

### Level 0: Instrumented

#### Questions to ask

* Do span names, attributes, or metric names change without notice?  
* Are users informed of telemetry changes only after breakage?  
* Is telemetry treated as an internal debugging aid?  
* Are changes driven by implementation refactors rather than user impact?  
* Is there no distinction between stable and experimental telemetry?

#### Concrete examples

* Span names change between releases with no mention  
* Attribute keys renamed silently  
* Metrics appear and disappear unpredictably  
* Dashboards break after upgrades  
* Users discover changes during incidents

#### Strong indicators of Level 0

* Telemetry is fragile  
* Users cannot rely on it  
* Operational workflows break frequently  
* Observability trust is low

### Level 1: OpenTelemetry-Aligned

At this level, *some awareness of stability exists*, but practices are informal.

#### Questions to ask

* Are telemetry changes mentioned in release notes inconsistently?  
* Are breaking changes discovered reactively?  
* Is stability handled differently per signal?  
* Are users expected to adapt frequently?  
* Is there no clear policy for telemetry evolution?

#### Concrete examples

* Release notes mention “telemetry improvements” without detail  
* Breaking changes acknowledged after reports  
* Traces stable, metrics volatile  
* Users pin versions to avoid breakage

#### Strong indicators of Level 1

* Stability depends on maintainers’ discretion  
* Users must monitor changes closely  
* Telemetry is usable, but risky to depend on

### Level 2: OpenTelemetry-Native

At this level, telemetry is **treated as part of the public contract**.

#### Questions to ask

* Are telemetry changes documented clearly?  
* Is there a distinction between stable and experimental telemetry?  
* Are breaking changes called out explicitly?  
* Is migration guidance provided?  
* Are changes reviewed with downstream impact in mind?

#### Concrete examples

* Changelog sections for telemetry changes  
* Experimental attributes clearly labeled  
* Migration notes for renamed attributes  
* Users can upgrade confidently  
* Telemetry stability discussed alongside APIs

#### Strong indicators of Level 2

* Users can build long-lived dashboards and alerts  
* Telemetry evolution is predictable  
* Trust in observability increases  
* Operational workflows remain stable

### Level 3: OpenTelemetry-Optimized

At this level, telemetry evolution is *governed, intentional, and quality-aware*.

#### Questions to ask

* Is there a defined process for reviewing telemetry changes?  
* Are telemetry changes evaluated for impact on:  
  * usability  
  * signal quality  
  * cost  
* Are deprecations planned and communicated?  
* Are migration paths standard practice?  
* Are telemetry regressions detected proactively?

#### Concrete examples

* Telemetry changes reviewed like API changes  
* Deprecation timelines documented  
* Migration guides included in releases  
* Telemetry quality monitored over time  
* Changes validated against real user workflows

#### Advanced indicators

* Telemetry stability is a first-class concern  
* Observability treated as a long-lived interface  
* Users trust telemetry as a reliable contract  
* Telemetry evolution balances innovation and stability

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtIAAAJHCAYAAAC9wbFaAABtdElEQVR4XuzdW+wc9X3/f0u95paLiisuuOCCCyok+qdIiAohShFC/EFRFH6kIFBIoSJE5ZBCEgoJCYGQEnIkCQWSgMiJBEpKA4EALgRiwDY2DuCzHTA+xwcMxt7f7zXOe/3Zz87sznk+n5nnQxp9d2dn9zunnXnNZ98zs2AEAAAAoLAFfg8AAAAA8xGkAQAAgBII0gAAAEAJBGkAAACgBII0AAAAUAJBGgAAACiBIA0AAACUQJAGAAAASiBIAwAAACUQpAEAAIASCNIAAABACQRpAAAAoASCNAAAAFACQRrA2NI1HyQd6rNryctJh3rs37Yw6QAgBARpAEl4PvemLVPdA7/b4w860z333JN099577+gXv/jFaNeuXf4guelzmrR///7x+NZt04++P1pxzilTnfoXYeP3n//5n6Of/OQno3feeccfJLc6plPzzPe///u/4/FUd//9949+//vf+4NVouC886lTU7si3PF84IEHRosWLfIHyU2fsW7dOr93IWnz03z44YejH/3oR6MLL7wwmacAwkSQBgZOYdkP0H6X11//9V9Pdd/85jf9wXLRe8t68803k/f/+c9/9l8au/jii8fjWDc/QPtdXv68VPexj33MHyyXqtOp93/hC1/we4+uueaaqXFU99///d/+oKX54dnv8vLH0boy9L7/+Z//8Xvn9jd/8zej008/3e+d+PWvfz01jhoeQHgI0sCA5QnRRcK0dvh/93d/N/Hcgso//dM/Ja1rN9988zgUvPvuu0mY0DCf+9znxu8TDWv++Mc/jk455ZSke/HFFw8P9P/88z//c/L+c889d/TBBx8krXx/+7d/m/T76Ec/OlqyZMnE8HLw4MFxONHfY445xh+kND80Z3V5aNw0j9znNj81HzWP1LKqeSD79u1L5oOGueqqq8bvE3d+ah5p3mi6/+M//uPwQKPDwfgf/uEfRjt27Ej66b02v2688cbU4d3W8uuvv348nlX5oTmry0PjdMMNN4yfn3322Uk/tUwvXbo0mc6NGzcm6+SBAweSYf7t3/4tGUYHMHv2HP6FRsO+8sor4+eXXnrp1OfLfffdl8w3rZNqvRebn+ree++9ieFXr149tU5qXNTvpZdecoYEEAKCNDBgflie1eWhnb0F6ddf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5ytWrJjanmzZsmXiudF2zN22ZoXWrO2ntmP+fNX/fvHFFyf6uWbtU/TeK6+8cqqf65133pl47krbJ2XRtGp/kcbfP2sc0vb/Ro1h+/fv93sn/O29ydpvIAzd7ZEjd9RRR40DpsvCnLrjjz8+6Xfcccclz3X0737R3WHVnXTSSUl/hZT7779/PIzbIu2/T19u9zN//vOfTzw36ve1r30tGee08RaF5hNPPHGi344dO0b33HNP8tgf39/+9rdJ/6VLlybPbfrsS3/mmWdOvcc2En5/G2dtON1+aeFV/b///e+P3yN33333+D22sb/44ounPl/02MbVHovmuZ5bi80pp5wy8R63s3Dzla98ZaL/L37xi9GBAwemhj/vvPMmnpuzzz57or9t3P33a17ffPPNqZ/Rlj4HjJARpNvX1xbqlStXjk477TS/d0LhLs+2yO/efffdZLis7ac/vDq/v+gXXm2zxRoMrPP3S2Lvc9m+StPpvt9teffHRQcOmzdvnvi8H//4x+P9mD+8SevvPrf9v73m/9o767Ns3/rEE09M9M86eEG3ptdE5OZ+YdwjX/Vzj0gVpM23vvWtcXmGhrMWUduIybwgnfZYwVK0wfjUpz41fs0899xzyXDHHHOM/9KYXvdbeV3u//z4xz+eHEyIps/+//nnnz8+ILAgbfRY06X/4fe35/prG0OFTP3c59MwtoFx+z366KPJXwvSGq/3339//PpvfvObife777XhX3311eSxhWF57LHHpv6X7WT12FoqFi1alDx33yvf+MY3Jp5/4hOfSP5qObv9daBjz93+7rzuokWaVuhu9THQxULzvm8n0Gr7oU7bZzeYad9x4YUXJo/9bdG11147Hk7P1WAj2j5/5CMfSR5nbT/19/TTTz/05r88dx9bi7QbpNX/l7/85cRwvrR+Rq9pu+s+/+pXvzp+bBT63f+pAO4Oo4MO2/Za/wcffHBiGHus1mR77O7/bTjNXzWoGD0/66yzJoYRd3uv/loWokYo91dwhCN7TUQu27ZtS468tcJb3bL/RVLQUii0VtBly5aNh3Pp+euvv144SH/hC18YP9dfbcRc9vOdvqD2usK2+6WWrBBu3P+pAwL3+a233ppsVNXPjv79IK3+GldtvD7zmc+M+99xxx0T4686OXXHHnvs1DyyYX72s58lgVxH+Wo1d9/v/vxo06zu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>
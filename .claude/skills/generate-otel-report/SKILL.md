---
name: generate-otel-report
description: Generate an HTML report with radar chart from an OpenTelemetry maturity evaluation. Reads EVALUATION.md and produces a self-contained webpage with Chart.js radar diagram, dimension details, and actionable guidance. Use after evaluate-otel-maturity.
argument-hint: "<project-name>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Generate OpenTelemetry Maturity Report

You generate a polished, self-contained HTML report from an OpenTelemetry maturity evaluation. The report visualizes the 7-dimension assessment as an interactive radar chart and presents findings as friendly, constructive guidance.

## Required argument

The user provides the `<project-name>`. The evaluation must already exist at `.otel-eval/<project-name>/EVALUATION.md`.

## Process

### Step 1: Read the evaluation

Read `.otel-eval/<project-name>/EVALUATION.md` to extract:
- Project name, version, evaluation date
- The 7 dimension scores (0-3) and their one-line summaries
- Strengths, areas for improvement, notable observations
- Per-dimension evidence, checklist assessments, and rationale
- Telemetry overview (signals observed, resource attributes)

### Step 2: Generate the HTML report

Write the report to `.otel-eval/<project-name>/report.html`.

The report must be:
- **Self-contained** — single HTML file, no external dependencies except CDN links for Chart.js
- **Readable** — clean typography, good use of whitespace, professional appearance
- **Constructive** — frame findings as guidance, not criticism. Use encouraging language.
- **Specific** — include actual attribute names, metric names, span names from the evaluation

### Report structure

The HTML report should contain these sections in order:

#### Header
- Project name and version
- Evaluation date
- Brief project description
- Maturity model reference

#### Radar chart
- Chart.js radar chart showing all 7 dimensions
- Scale from 0 to 3
- Level labels on the scale: 0=Instrumented, 1=OTel-Aligned, 2=OTel-Native, 3=OTel-Optimized
- The filled area should use a color that reflects the project's brand or a neutral professional color
- Include a legend explaining the scale

#### Summary table
- All 7 dimensions with level number, level name, and one-line summary
- Use color coding: Level 0 = muted red/orange, Level 1 = amber/yellow, Level 2 = blue/teal, Level 3 = green

#### Signal overview
- Which signals are flowing and how (OTLP, Prometheus, etc.)
- A simple visual indicator per signal (traces, metrics, logs)

#### Per-dimension detail sections
For each of the 7 dimensions, create a collapsible/expandable section containing:
- **Level badge** with color coding
- **What we observed** — key evidence from the evaluation, framed constructively
- **What's working well** — positive aspects at the current level
- **Opportunities** — concrete, actionable suggestions framed as opportunities rather than deficiencies
- **Concrete examples** — actual attribute names, span names, metric names from the telemetry data. Use `<code>` formatting for technical terms.

Frame everything constructively:
- Instead of "Missing X" → "Adding X would improve..."
- Instead of "Broken" → "There's an opportunity to..."
- Instead of "Wrong" → "Currently uses X, while the latest convention is Y"
- Acknowledge constraints (e.g., upstream Envoy dependencies) as context, not excuses

#### Key takeaways
- Top strengths (what the project does well)
- Priority improvements (highest-impact changes)
- Notable observations

#### Methodology footer
- Brief note on how the evaluation was conducted
- Link to the maturity model

### Design guidelines

- Use a clean, modern design with good typography (system fonts or Google Fonts via CDN)
- Color palette: use a professional, accessible color scheme
- The radar chart should be prominent but not overwhelming
- Use subtle backgrounds, borders, and spacing to create visual hierarchy
- Make it look like a professional assessment report, not a developer tool
- Responsive design that works on desktop and tablet
- Dark/light mode is not required but if included, default to light
- Use CSS grid or flexbox for layout
- No JavaScript frameworks beyond Chart.js for the radar chart

### Chart.js specifics

Use Chart.js v4 via CDN:
```html
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
```

Radar chart configuration:
- 7 axes, one per dimension
- Scale: min 0, max 3, step size 1
- Point labels: dimension names (abbreviated if needed to fit)
- Scale labels: 0="Instrumented", 1="Aligned", 2="Native", 3="Optimized"
- Fill the area with a semi-transparent color
- Show data points on the polygon
- The chart should include the level names (not just numbers) on the radial scale

## Output

When complete, print:
```
Report generated: .otel-eval/<project-name>/report.html

Open in browser:
  open .otel-eval/<project-name>/report.html
```

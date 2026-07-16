The document below is a CODE GENERATOR skill: its value is its code templates, which are NOT shown here and are NOT being assessed. You are grading only its PROSE GUIDANCE — design principles, API guidance, statistics, pitfalls — against a baseline AI answer produced without the document.

Step 1 — extract 5–10 claims from the document's knowledge/guidance prose ONLY. Ignore scaffolding: frontmatter, activation triggers, configuration question lists, generation steps, file layouts, references to template files, tool lists. Each claim MUST include a `quote`: a verbatim excerpt copied exactly from the document (machine-validated as a substring).

Step 2 — grade each claim against the baseline answer:
- "covered" — the answer states the same substance.
- "partial" — gestures at it but misses the specific number/API/ordering.
- "missed" — not addressed, or the answer said it was unsure.
- "contradicted" — the answer asserts something incompatible.

Rules:
- For covered/partial/contradicted you MUST include `evidence`: an exact quote from the baseline answer. No quote → verdict must be "missed".
- For "contradicted", set `who_is_right` ("skill" | "model" | "unclear") and `confidence` ("low"|"med"|"high").
- Set `suspect: true` (+ `suspect_reason`) on claims naming APIs/behaviors you believe deprecated, renamed, or nonexistent.
- Do NOT judge the templates or whether you could generate equivalent code. Prose claims only.

Document ({{SKILL_ID}}):
<document>
{{CONTENT}}
</document>

Baseline answer:
<answer>
{{ANSWER}}
</answer>

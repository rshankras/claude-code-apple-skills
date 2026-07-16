You are grading a blind test. A baseline AI assistant answered developer questions WITHOUT access to a reference document. Below are the reference document's CLAIMS and the assistant's ANSWERS.

For each claim, decide a verdict:
- "covered" — the answers state the same substance (wording may differ).
- "partial" — the answers gesture at it but miss the specific number, API name, or ordering.
- "missed" — the answers do not address it, or explicitly said they were unsure.
- "contradicted" — the answers assert something incompatible with the claim.

Rules:
- For covered, partial, or contradicted you MUST include `evidence`: an exact quote from the answers below (machine-validated as a substring). If you cannot quote evidence, the verdict must be "missed".
- For "contradicted", also set `who_is_right` ("skill" | "model" | "unclear") and `confidence` ("low" | "med" | "high"), judged from your own knowledge.
- Independently of coverage, set `suspect: true` on any claim that names an API or behavior you believe is deprecated, renamed, or nonexistent, and give a `suspect_reason`. Claims about APIs newer than your knowledge may look unfamiliar — that alone is weak evidence; still flag if you believe they are wrong, the flag is cross-checked elsewhere.
- Do NOT give an overall verdict on the document. Grade claims only.

CLAIMS:
{{CLAIMS_JSON}}

ANSWERS TRANSCRIPT:
{{TRANSCRIPT}}

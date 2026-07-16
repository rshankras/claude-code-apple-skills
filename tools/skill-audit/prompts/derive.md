You are auditing a knowledge-base document (a "skill") used to teach an AI coding assistant about Apple platform development. Your job: extract the document's distinct, testable knowledge, then write blind-test questions.

## Step 1 — Claims

Extract the 8–15 highest-value discrete CLAIMS — the deltas this document adds beyond generic knowledge: specific numbers, named APIs with versions, opinionated recommendations, ordered procedures, gotchas and traps. Skip scaffolding: frontmatter, activation triggers, tool lists, file-generation mechanics, section navigation.

Each claim MUST include a `quote`: a verbatim excerpt copied exactly from the document (it will be machine-validated as a substring — do not paraphrase, do not fix typos, do not merge lines that aren't adjacent).

## Step 2 — Questions

Write 3–5 natural developer questions that jointly exercise every claim.

Rules:
- Never mention this document or that any reference exists.
- Never embed a claim's answer in its question (no leading questions).
- Each question must stand alone.
- Prefer questions where a generic answer would plausibly differ from this document's answer.
- Every claim id must appear in at least one question's `claim_ids`.

Skill: {{SKILL_ID}}

<document>
{{CONTENT}}
</document>

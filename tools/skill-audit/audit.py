#!/usr/bin/env python3
"""Blind-test skill audit harness.

For each leaf skill, derives blind-test questions, asks them to a bare
(safe-mode, tool-less) Claude session, grades the bare answers against
claims extracted from the skill, and classifies the skill
DELETE-candidate / TRIM / KEEP / FIX. Nothing is deleted by this tool:
the output is results/<model-id>/AUDIT-REPORT.md for human approval.

Usage:
  python3 tools/skill-audit/audit.py preflight
  python3 tools/skill-audit/audit.py list
  python3 tools/skill-audit/audit.py run --category testing [--dry-run] [--limit N]
  python3 tools/skill-audit/audit.py run --skill generators/paywall-generator
  python3 tools/skill-audit/audit.py run --all
  python3 tools/skill-audit/audit.py report
  python3 tools/skill-audit/audit.py diff --against <old-model-id>

Runs are resumable: state is kept per skill per question under
results/<model-id>/state/; re-issuing the same run skips finished work.
A re-run under a new model release lands in a fresh results dir.
"""

import argparse
import concurrent.futures
import hashlib
import json
import re
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SKILLS_DIR = ROOT / "skills"
SCRIPTS_DIR = ROOT / "scripts"

HARNESS_VERSION = 1

DERIVE_SCHEMA = {
    "type": "object",
    "required": ["claims", "questions"],
    "properties": {
        "claims": {
            "type": "array",
            "minItems": 3,
            "maxItems": 15,
            "items": {
                "type": "object",
                "required": ["id", "text", "kind", "quote"],
                "properties": {
                    "id": {"type": "string"},
                    "text": {"type": "string"},
                    "kind": {"enum": ["fact", "number", "api", "procedure", "recommendation"]},
                    "quote": {"type": "string"},
                },
            },
        },
        "questions": {
            "type": "array",
            "minItems": 3,
            "maxItems": 5,
            "items": {
                "type": "object",
                "required": ["id", "text", "claim_ids"],
                "properties": {
                    "id": {"type": "string"},
                    "text": {"type": "string"},
                    "claim_ids": {"type": "array", "items": {"type": "string"}},
                },
            },
        },
    },
}

GRADE_ITEM_PROPS = {
    "claim_id": {"type": "string"},
    "verdict": {"enum": ["covered", "partial", "missed", "contradicted"]},
    "evidence": {"type": "string"},
    "who_is_right": {"enum": ["skill", "model", "unclear"]},
    "confidence": {"enum": ["low", "med", "high"]},
    "suspect": {"type": "boolean"},
    "suspect_reason": {"type": "string"},
}

GRADE_SCHEMA = {
    "type": "object",
    "required": ["grades"],
    "properties": {
        "grades": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["claim_id", "verdict"],
                "properties": GRADE_ITEM_PROPS,
            },
        }
    },
}

GENERATOR_GRADE_SCHEMA = {
    "type": "object",
    "required": ["claims"],
    "properties": {
        "claims": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["id", "text", "quote", "verdict"],
                "properties": {
                    "id": {"type": "string"},
                    "text": {"type": "string"},
                    "quote": {"type": "string"},
                    "verdict": {"enum": ["covered", "partial", "missed", "contradicted"]},
                    "evidence": {"type": "string"},
                    "who_is_right": {"enum": ["skill", "model", "unclear"]},
                    "confidence": {"enum": ["low", "med", "high"]},
                    "suspect": {"type": "boolean"},
                    "suspect_reason": {"type": "string"},
                },
            },
        }
    },
}


# --------------------------------------------------------------------------
# Config / enumeration
# --------------------------------------------------------------------------

def load_config():
    cfg = json.loads((HERE / "config.json").read_text())
    cfg.setdefault("claude_bin", "claude")
    return cfg


def parse_category_level_skills():
    txt = (SCRIPTS_DIR / "check-counts.sh").read_text()
    m = re.search(r'^CATEGORY_LEVEL_SKILLS="([^"]*)"', txt, re.M)
    if not m:
        sys.exit("FATAL: CATEGORY_LEVEL_SKILLS not found in scripts/check-counts.sh")
    return m.group(1).split()


class Skill:
    def __init__(self, sid, path, category, track, is_router):
        self.sid = sid            # e.g. "ios/ui-review" or "security" (category-level)
        self.path = path          # Path to SKILL.md
        self.category = category
        self.track = track        # "A" | "B"
        self.is_router = is_router

    def supporting_files(self):
        return sorted(p for p in self.path.parent.glob("*.md") if p.name != "SKILL.md")


ROUTER_HEADING = re.compile(r"^## Available (Skills|Modules)\s*$", re.M)


def enumerate_skills(cfg):
    """Reproduce scripts/check-counts.sh's counting rule exactly:
    leaf skills at skills/<cat>/<skill>/SKILL.md plus the category-level
    skills named in CATEGORY_LEVEL_SKILLS. Other category SKILL.md files
    are routers and excluded."""
    overrides = cfg.get("track_overrides", {})
    skills = []
    for p in sorted(SKILLS_DIR.glob("*/*/SKILL.md")):
        cat = p.parent.parent.name
        if cat == "_shared":
            continue
        sid = f"{cat}/{p.parent.name}"
        track = "B" if (cat == "generators" or overrides.get(sid) == "B") else "A"
        is_router = bool(ROUTER_HEADING.search(p.read_text(errors="replace")))
        skills.append(Skill(sid, p, cat, track, is_router))
    for cat in parse_category_level_skills():
        p = SKILLS_DIR / cat / "SKILL.md"
        if not p.exists():
            sys.exit(f"FATAL: skills/{cat}/SKILL.md listed in CATEGORY_LEVEL_SKILLS but missing")
        track = "B" if overrides.get(cat) == "B" else "A"
        is_router = bool(ROUTER_HEADING.search(p.read_text(errors="replace")))
        skills.append(Skill(cat, p, cat, track, is_router))
    return skills


# --------------------------------------------------------------------------
# Content assembly
# --------------------------------------------------------------------------

def strip_frontmatter(text):
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            return text[end + 4:]
    return text


def collapse_code_blocks(text, max_lines=40):
    out, in_block, block = [], False, []
    for line in text.splitlines():
        if line.strip().startswith("```"):
            if in_block:
                if len(block) > max_lines:
                    out.extend(block[:5])
                    out.append(f"… [{len(block) - 5} code lines collapsed]")
                else:
                    out.extend(block)
                out.append(line)
                in_block, block = False, []
            else:
                out.append(line)
                in_block = True
            continue
        if in_block:
            block.append(line)
        else:
            out.append(line)
    out.extend(block)  # unterminated block
    return "\n".join(out)


def headings_outline(text):
    return "\n".join(l for l in text.splitlines() if l.startswith("#"))


def assemble_content(skill, cfg):
    """Track A content: SKILL.md whole, supporting .md files whole until the
    budget, then headings-only outline. Returns (content, truncated)."""
    budget = cfg["content_budget_bytes"]
    parts = [skill.path.read_text(errors="replace")]
    used = len(parts[0].encode())
    truncated = False
    for p in skill.supporting_files():
        body = p.read_text(errors="replace")
        size = len(body.encode())
        if used + size <= budget:
            parts.append(f"\n\n<!-- supporting file: {p.name} -->\n{body}")
            used += size
        else:
            parts.append(f"\n\n<!-- supporting file (outline only, truncated): {p.name} -->\n"
                         + headings_outline(body))
            truncated = True
    return "".join(parts), truncated


def content_hash(skill):
    h = hashlib.sha256(skill.path.read_bytes())
    for p in skill.supporting_files():
        h.update(p.read_bytes())
    return h.hexdigest()


def normalize(s):
    """Whitespace-collapse, lowercase, and strip markdown decoration — quote
    validation must tolerate `**bold**`/backtick differences between what the
    model wrote and how the grader quoted it, while still requiring the same
    content words in the same order."""
    s = re.sub(r"[*_`#>|]", "", s or "")
    return re.sub(r"\s+", " ", s).strip().lower()


# --------------------------------------------------------------------------
# Claude invocation
# --------------------------------------------------------------------------

class CallError(RuntimeError):
    pass


class Budget:
    def __init__(self, max_calls):
        self.max_calls = max_calls
        self.calls = 0
        self.lock = threading.Lock()

    def take(self):
        with self.lock:
            if self.calls >= self.max_calls:
                raise CallError(f"max_calls_per_run ({self.max_calls}) reached")
            self.calls += 1


BARE_FLAGS = [
    "--safe-mode",              # no CLAUDE.md, rules, skills, plugins, hooks, MCP
    "--setting-sources", "",    # no user/project/local settings sources
    "--strict-mcp-config",      # with no --mcp-config: zero MCP servers
    "--tools", "",              # parametric knowledge only
    "--disable-slash-commands",
    "--no-session-persistence",
]


def run_claude(prompt, model, cfg, tmp_cwd, budget, schema=None):
    cmd = [cfg["claude_bin"], "-p", "--model", model] + BARE_FLAGS + [
        "--output-format", "json"]
    if schema is not None:
        cmd += ["--json-schema", json.dumps(schema)]
    cmd.append(prompt)
    delays = cfg.get("backoff_seconds", [10, 30, 90])
    last_err = ""
    for attempt in range(cfg.get("retries", 3)):
        budget.take()
        try:
            p = subprocess.run(cmd, cwd=str(tmp_cwd), capture_output=True,
                               text=True, timeout=cfg["call_timeout_seconds"])
        except subprocess.TimeoutExpired:
            last_err = "timeout"
            time.sleep(delays[min(attempt, len(delays) - 1)])
            continue
        if p.returncode == 0:
            try:
                obj = json.loads(p.stdout)
            except json.JSONDecodeError:
                last_err = f"non-JSON stdout: {p.stdout[:200]}"
                time.sleep(delays[min(attempt, len(delays) - 1)])
                continue
            if obj.get("is_error"):
                last_err = f"is_error: {str(obj.get('result'))[:200]}"
                time.sleep(delays[min(attempt, len(delays) - 1)])
                continue
            return obj
        last_err = (p.stderr or p.stdout)[-300:]
        wait = delays[min(attempt, len(delays) - 1)]
        if re.search(r"rate.?limit|overloaded|529", last_err, re.I):
            wait = max(wait, 60)
        time.sleep(wait)
    raise CallError(last_err or "unknown claude failure")


def result_text(obj):
    r = obj.get("result")
    return r if isinstance(r, str) else json.dumps(r)


def extract_structured(obj):
    for key in ("structured_output", "structured_result", "structuredOutput"):
        if isinstance(obj.get(key), (dict, list)):
            return obj[key]
    r = obj.get("result")
    if isinstance(r, (dict, list)):
        return r
    if isinstance(r, str):
        s = re.sub(r"^```(?:json)?\s*|\s*```$", "", r.strip())
        try:
            return json.loads(s)
        except json.JSONDecodeError:
            m = re.search(r"\{.*\}", s, re.S)
            if m:
                return json.loads(m.group(0))
    raise CallError(f"no structured output in response: {str(r)[:200]}")


def find_model_id(obj):
    """The main model is the one carrying the conversation context; auxiliary
    models (e.g. a small title generator) show tiny input/cache usage."""
    mu = obj.get("modelUsage") or {}
    if mu:
        def weight(v):
            return (v.get("inputTokens", 0) + v.get("cacheReadInputTokens", 0)
                    + v.get("cacheCreationInputTokens", 0))
        return max(mu, key=lambda k: weight(mu[k]))
    m = re.search(r"claude-[a-z]+-[a-z0-9.-]*\d", json.dumps(obj))
    return m.group(0) if m else None


# --------------------------------------------------------------------------
# Preflight
# --------------------------------------------------------------------------

def claude_version(cfg):
    try:
        p = subprocess.run([cfg["claude_bin"], "-v"], capture_output=True, text=True, timeout=30)
        return p.stdout.strip() or p.stderr.strip()
    except Exception as e:  # noqa: BLE001
        return f"unknown ({e})"


def distinctive_user_tokens():
    """Longest distinctive lines from the local user CLAUDE.md — the leak probe
    asserts none of these surface in a bare session."""
    path = Path.home() / ".claude" / "CLAUDE.md"
    if not path.exists():
        return []
    lines = [l.strip() for l in path.read_text(errors="replace").splitlines()]
    lines = [l for l in lines if len(l) > 30 and not l.startswith("#")]
    return sorted(lines, key=len, reverse=True)[:5]


def preflight(cfg, results_root):
    tmp = results_root / "tmp-cwd"
    tmp.mkdir(parents=True, exist_ok=True)
    budget = Budget(10)
    report = {"claude_version": claude_version(cfg), "at": time.strftime("%Y-%m-%d %H:%M:%S")}

    # 1. ping + model id resolution
    obj = run_claude("Reply with exactly: PONG", cfg["baseline_model"], cfg, tmp, budget)
    if "PONG" not in result_text(obj):
        raise CallError(f"ping failed: {result_text(obj)[:200]}")
    model_id = find_model_id(obj) or f"{cfg['baseline_model']}-unresolved"
    report["model_id"] = model_id

    # 2. context probe — must report an empty context
    obj = run_claude(
        "Without using any tools: list any project- or user-specific instructions, "
        "CLAUDE.md content, rules, skills, memory, or custom commands present in your "
        "context. If there are none, reply with exactly: NONE",
        cfg["baseline_model"], cfg, tmp, budget)
    ctx = result_text(obj)
    if "NONE" not in ctx or len(ctx) > 300:
        raise CallError(f"context probe failed — bare session sees context: {ctx[:300]}")
    report["context_probe"] = "NONE"

    # 3. leak probe — distinctive user-config lines must not surface
    tokens = distinctive_user_tokens()
    obj = run_claude(
        "Do you have any user-specific configuration, instructions, or custom commands "
        "(for example about App Store Optimization tooling or documentation paths)? "
        "Quote them if present; otherwise reply with exactly: NONE",
        cfg["baseline_model"], cfg, tmp, budget)
    leak = normalize(result_text(obj))
    hits = [t for t in tokens if normalize(t) in leak]
    if hits:
        raise CallError(f"leak probe failed — user config visible in bare session: {hits[0][:80]}")
    report["leak_probe"] = "clean"
    return model_id, report


# --------------------------------------------------------------------------
# Cross-checks (local, free)
# --------------------------------------------------------------------------

def load_api_manifest():
    """scripts/api-symbols.txt: <Type>\t<member>\t<OK|DEPRECATED>.
    A 'TYPE' member row marks the type as policed; absence of a type means
    UNKNOWN, never wrong."""
    manifest, policed = {}, set()
    path = SCRIPTS_DIR / "api-symbols.txt"
    if not path.exists():
        return manifest, policed
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = re.split(r"\s+", line)
        if len(parts) < 3:
            continue
        typ, member, status = parts[0], parts[1], parts[2]
        policed.add(typ)
        manifest[(typ, member)] = status
    return manifest, policed


def current_os_gen():
    txt = (SCRIPTS_DIR / "versions.env").read_text()
    m = re.search(r"^CURRENT_OS_GEN=(\d+)", txt, re.M)
    return int(m.group(1)) if m else None


RECENCY_RE = re.compile(r"(?i)\b(latest|new in|introduced in|as of|current)\b")
VERSION_RE = re.compile(r"\b(iOS|iPadOS|macOS|watchOS|tvOS|visionOS|Xcode)\s+(\d+)")


def cross_check_suspect(claim, manifest, policed, os_gen):
    """Returns 'manifest-confirmed' | 'version-confirmed' | 'unverified'."""
    text = f"{claim.get('text', '')} {claim.get('quote', '')}"
    for typ, member in re.findall(r"\b([A-Z][A-Za-z0-9]+)\.([a-zA-Z][A-Za-z0-9_]*)", text):
        if typ in policed and member != "TYPE":
            status = manifest.get((typ, member))
            if status is None or status == "DEPRECATED":
                return "manifest-confirmed"
    if os_gen and RECENCY_RE.search(text):
        for _, ver in VERSION_RE.findall(text):
            if int(ver) <= os_gen - 2:
                return "version-confirmed"
    return "unverified"


def swiftship_dir(cfg):
    env = os.environ.get("SWIFTSHIP_DIR") or cfg.get("swiftship_dir")
    return Path(env).expanduser() if env else ROOT.parent / "SwiftShip"


def swiftship_references(skill, cfg):
    base = swiftship_dir(cfg)
    name = skill.sid.split("/")[-1]
    hits = []
    for p in list(base.glob("commands/*.md")) + [base / "CLAUDE.md"]:
        try:
            if name in p.read_text(errors="replace"):
                hits.append(str(p.relative_to(base)))
        except OSError:
            continue
    return hits


# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

def state_path(results_root, sid):
    return results_root / "state" / f"{sid}.json"


def raw_dir(results_root, sid):
    return results_root / "raw" / sid


def load_state(results_root, skill):
    p = state_path(results_root, skill.sid)
    if p.exists():
        st = json.loads(p.read_text())
        if st.get("content_hash") == content_hash(skill) and st.get("harness_version") == HARNESS_VERSION:
            return st
    return {
        "skill": skill.sid,
        "track": skill.track,
        "content_hash": content_hash(skill),
        "harness_version": HARNESS_VERSION,
        "stages": {},
        "result": {"classification": None, "coverage": None, "flags": [], "justification": ""},
        "errors": [],
    }


def save_state(results_root, st):
    p = state_path(results_root, st["skill"])
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(st, indent=1))


def save_raw(results_root, sid, name, payload):
    d = raw_dir(results_root, sid)
    d.mkdir(parents=True, exist_ok=True)
    (d / name).write_text(json.dumps(payload, indent=1) if not isinstance(payload, str) else payload)


# --------------------------------------------------------------------------
# Pipeline
# --------------------------------------------------------------------------

def load_prompt(name):
    return (HERE / "prompts" / f"{name}.md").read_text()


def fill(template, **kw):
    for k, v in kw.items():
        template = template.replace("{{" + k + "}}", v)
    return template


def frontmatter_description(skill):
    text = skill.path.read_text(errors="replace")
    m = re.search(r"^description:\s*(.+)$", text, re.M)
    return m.group(1).strip() if m else skill.sid


def workflow_heavy(text):
    return text.count("AskUserQuestion") >= 2 or len(re.findall(r"^#{2,3} Step \d", text, re.M)) >= 5


def validate_quotes(claims, content):
    """Keep only claims whose quote is a (whitespace-normalized) substring."""
    norm_content = normalize(content)
    valid, dropped = [], []
    for c in claims:
        (valid if normalize(c.get("quote", "")) in norm_content else dropped).append(c)
    return valid, dropped


def validate_evidence(grades, answers_text):
    """Evidence must be a substring of the stored answers, else claim is
    ungradable (covered/partial/contradicted without evidence is untrustable)."""
    norm_answers = normalize(answers_text)
    out = []
    for g in grades:
        if g.get("verdict") in ("covered", "partial", "contradicted"):
            if normalize(g.get("evidence", "")) not in norm_answers or not g.get("evidence"):
                g = dict(g, verdict="ungradable")
        out.append(g)
    return out


def coverage_of(grades):
    gradable = [g for g in grades if g.get("verdict") in ("covered", "partial", "missed", "contradicted")]
    if not gradable:
        return None, 0
    score = sum(1.0 if g["verdict"] == "covered" else 0.5 if g["verdict"] == "partial" else 0.0
                for g in gradable)
    return score / len(gradable), len(gradable)


def analyze_grades(grades, manifest, policed, os_gen):
    """Shared verdict math for both tracks (grader never classifies)."""
    cov, n_gradable = coverage_of(grades)
    contradictions = [g for g in grades if g.get("verdict") == "contradicted"]
    model_right_high = [g for g in contradictions
                        if g.get("who_is_right") == "model" and g.get("confidence") == "high"]
    unclear = [g for g in contradictions if g.get("who_is_right") == "unclear"]
    suspects = [g for g in grades if g.get("suspect")]
    confirmed, unverified = [], []
    for s in suspects:
        s["cross_check"] = cross_check_suspect(s, manifest, policed, os_gen)
        (confirmed if s["cross_check"] != "unverified" else unverified).append(s)
    return {
        "coverage": cov, "n_gradable": n_gradable,
        "contradictions": contradictions, "model_right_high": model_right_high,
        "unclear": unclear, "suspects_confirmed": confirmed, "suspects_unverified": unverified,
    }


def classify_track_a(a, th):
    if a["suspects_confirmed"] or a["model_right_high"]:
        return "FIX"
    cov = a["coverage"]
    if cov is None:
        return "SKIPPED-error"
    if cov >= th["delete_coverage"] and not a["contradictions"] and not (
            a["suspects_confirmed"] or a["suspects_unverified"]):
        return "DELETE-pending-escalation"
    if cov >= th["trim_coverage"]:
        return "TRIM"
    return "KEEP"


def classify_track_b(a, th):
    if a["suspects_confirmed"] or a["model_right_high"]:
        return "FIX"
    cov = a["coverage"]
    if cov is None:
        return "SKIPPED-error"
    if cov >= th["delete_coverage"] and not a["contradictions"]:
        return "TRIM(prose)"
    return "KEEP"


def review_flags(a, th, text):
    flags = []
    cov = a["coverage"]
    if cov is not None:
        for boundary in (th["delete_coverage"], th["trim_coverage"]):
            if abs(cov - boundary) <= th["review_band"]:
                flags.append("human-review:borderline")
                break
    if a["unclear"]:
        flags.append("human-review:unclear-contradiction")
    if a["suspects_unverified"]:
        flags.append("human-review:unverified-suspect")
    if workflow_heavy(text):
        flags.append("workflow-heavy")
    return flags


def build_transcript(questions, answers):
    parts = []
    for q in questions:
        a = answers.get(q["id"], "")
        parts.append(f"{q['id']}: {q['text']}\nANSWER {q['id']}:\n{a}\n---")
    return "\n".join(parts)


def process_skill(skill, results_root, cfg, budget, manifest, policed, os_gen, log):
    st = load_state(results_root, skill)
    res = st["result"]
    cls = res.get("classification")
    if cls == "SKIPPED-error":
        res["classification"] = None  # errored: retry from last completed stage
    elif cls and not cls.startswith("DELETE-pending"):
        return st  # already finished
    tmp = results_root / "tmp-cwd"
    th = cfg["thresholds"]
    text = skill.path.read_text(errors="replace")

    try:
        if skill.is_router:
            res.update(classification="SKIPPED-router",
                       justification="category index (## Available Skills) — navigation, not knowledge")
            save_state(results_root, st)
            return st

        if skill.track == "A":
            content, truncated = assemble_content(skill, cfg)
            if truncated and "truncated" not in res["flags"]:
                res["flags"].append("truncated")

            # DERIVE
            if st["stages"].get("derive", {}).get("status") != "done":
                log(f"{skill.sid}: derive")
                prompt = fill(load_prompt("derive"), SKILL_ID=skill.sid, CONTENT=content)
                derived = None
                for _ in range(2):  # one retry if too many hallucinated quotes
                    obj = run_claude(prompt, cfg["baseline_model"], cfg, tmp, budget, DERIVE_SCHEMA)
                    cand = extract_structured(obj)
                    valid, dropped = validate_quotes(cand.get("claims", []), content)
                    if len(valid) >= 3 and len(dropped) <= len(valid):
                        derived = {"claims": valid, "questions": cand.get("questions", []),
                                   "dropped_claims": len(dropped)}
                        break
                if derived is None:
                    raise CallError("derive failed: too few claims with verifiable quotes")
                valid_ids = {c["id"] for c in derived["claims"]}
                for q in derived["questions"]:
                    q["claim_ids"] = [i for i in q.get("claim_ids", []) if i in valid_ids]
                # Cap the answer-call budget: if the model overshot, greedily
                # keep the questions that cover the most not-yet-covered claims.
                if len(derived["questions"]) > 5:
                    chosen, covered = [], set()
                    pool = list(derived["questions"])
                    while pool and len(chosen) < 5:
                        best = max(pool, key=lambda q: len(set(q["claim_ids"]) - covered))
                        pool.remove(best)
                        chosen.append(best)
                        covered.update(best["claim_ids"])
                    derived["questions"] = chosen
                save_raw(results_root, skill.sid, "derive.json", derived)
                st["stages"]["derive"] = {"status": "done"}
                st["stages"]["answers"] = [{"qid": q["id"], "status": "pending"}
                                           for q in derived["questions"]]
                save_state(results_root, st)

            derived = json.loads((raw_dir(results_root, skill.sid) / "derive.json").read_text())
            questions = derived["questions"]

            # ANSWER (per-question resume granularity)
            answers = {}
            for slot in st["stages"]["answers"]:
                qid = slot["qid"]
                q = next(q for q in questions if q["id"] == qid)
                raw_file = raw_dir(results_root, skill.sid) / f"answer-{qid}.json"
                if slot["status"] != "done":
                    log(f"{skill.sid}: answer {qid}")
                    obj = run_claude(fill(load_prompt("answer"), QUESTION=q["text"]),
                                     cfg["baseline_model"], cfg, tmp, budget)
                    save_raw(results_root, skill.sid, raw_file.name, {"question": q["text"],
                                                                      "answer": result_text(obj)})
                    slot["status"] = "done"
                    save_state(results_root, st)
                answers[qid] = json.loads(raw_file.read_text())["answer"]

            # GRADE (judge sees claims + answers only, never the skill)
            if st["stages"].get("grade", {}).get("status") != "done":
                log(f"{skill.sid}: grade")
                transcript = build_transcript(questions, answers)
                prompt = fill(load_prompt("grade"),
                              CLAIMS_JSON=json.dumps(derived["claims"], indent=1),
                              TRANSCRIPT=transcript)
                answers_text = "\n".join(answers.values())
                grades = None
                for _ in range(2):  # one regrade if evidence validation rejects
                    obj = run_claude(prompt, cfg["baseline_model"], cfg, tmp, budget, GRADE_SCHEMA)
                    cand = validate_evidence(extract_structured(obj).get("grades", []), answers_text)
                    if sum(1 for g in cand if g["verdict"] == "ungradable") <= len(cand) // 3:
                        grades = cand
                        break
                    grades = cand
                save_raw(results_root, skill.sid, "grade.json", {"grades": grades})
                st["stages"]["grade"] = {"status": "done"}
                save_state(results_root, st)

            grades = json.loads((raw_dir(results_root, skill.sid) / "grade.json").read_text())["grades"]
            by_id = {c["id"]: c for c in derived["claims"]}
            for g in grades:  # attach claim text for cross-checks + report
                c = by_id.get(g.get("claim_id"), {})
                g.setdefault("text", c.get("text", ""))
                g.setdefault("quote", c.get("quote", ""))

            analysis = analyze_grades(grades, manifest, policed, os_gen)
            verdict = classify_track_a(analysis, th)

            # DELETE escalation: opus second opinion on the same transcript
            if verdict == "DELETE-pending-escalation":
                esc_file = raw_dir(results_root, skill.sid) / "escalation.json"
                if esc_file.exists():
                    og = json.loads(esc_file.read_text())["grades"]
                else:
                    log(f"{skill.sid}: opus escalation")
                    transcript = build_transcript(questions, answers)
                    prompt = fill(load_prompt("grade"),
                                  CLAIMS_JSON=json.dumps(derived["claims"], indent=1),
                                  TRANSCRIPT=transcript)
                    obj = run_claude(prompt, cfg["escalation_model"], cfg, tmp, budget, GRADE_SCHEMA)
                    og = validate_evidence(extract_structured(obj).get("grades", []),
                                           "\n".join(answers.values()))
                    save_raw(results_root, skill.sid, "escalation.json", {"grades": og})
                oa = analyze_grades(og, manifest, policed, os_gen)
                if (oa["coverage"] or 0) >= th["delete_coverage"] and not oa["contradictions"]:
                    verdict = "DELETE-candidate"
                else:
                    verdict = "TRIM"
                    res["flags"].append("judge-disagreement")
                st["stages"]["escalate"] = {"status": "done"}

            if verdict == "DELETE-candidate":
                refs = swiftship_references(skill, cfg)
                if refs:
                    res["flags"].append("swiftship-referenced")
                    res["swiftship_refs"] = refs

            failed_qids = sorted({q["id"] for g in grades
                                  if g.get("verdict") in ("missed", "contradicted")
                                  for q in questions
                                  if g.get("claim_id") in q.get("claim_ids", [])})
            res.update(classification=verdict,
                       coverage=analysis["coverage"],
                       failed_questions=failed_qids,
                       justification=justify(verdict, analysis, grades))
            res["flags"] = sorted(set(res["flags"] + review_flags(analysis, th, text)))

        else:  # Track B
            answers_stage = st["stages"].get("answers")
            if not answers_stage or answers_stage[0].get("status") != "done":
                desc = frontmatter_description(skill)
                probe = (f"I'm adding this to my SwiftUI Apple-platform app: {desc}. "
                         "Before writing code: what design principles, current framework APIs, "
                         "and common pitfalls should guide the implementation? "
                         "Be specific with numbers and API names.")
                log(f"{skill.sid}: probe answer")
                obj = run_claude(fill(load_prompt("answer"), QUESTION=probe),
                                 cfg["baseline_model"], cfg, tmp, budget)
                save_raw(results_root, skill.sid, "answer-probe.json",
                         {"question": probe, "answer": result_text(obj)})
                st["stages"]["answers"] = [{"qid": "probe", "status": "done"}]
                save_state(results_root, st)
            answer = json.loads((raw_dir(results_root, skill.sid) / "answer-probe.json").read_text())["answer"]

            if st["stages"].get("grade", {}).get("status") != "done":
                log(f"{skill.sid}: generator grade")
                prose = collapse_code_blocks(strip_frontmatter(text))
                prompt = fill(load_prompt("generator-grade"), SKILL_ID=skill.sid,
                              CONTENT=prose, ANSWER=answer)
                obj = run_claude(prompt, cfg["baseline_model"], cfg, tmp, budget,
                                 GENERATOR_GRADE_SCHEMA)
                claims = extract_structured(obj).get("claims", [])
                claims, _ = validate_quotes(claims, prose)
                claims = validate_evidence(claims, answer)
                save_raw(results_root, skill.sid, "grade.json", {"grades": claims})
                st["stages"]["grade"] = {"status": "done"}
                save_state(results_root, st)

            grades = json.loads((raw_dir(results_root, skill.sid) / "grade.json").read_text())["grades"]
            analysis = analyze_grades(grades, manifest, policed, os_gen)
            verdict = classify_track_b(analysis, th)
            res.update(classification=verdict,
                       coverage=analysis["coverage"],
                       failed_questions=[],
                       justification=justify(verdict, analysis, grades) +
                       " Templates NOT assessed (Track B).")
            res["flags"] = sorted(set(res["flags"] + review_flags(analysis, th, text)))

    except CallError as e:
        st["errors"].append({"at": time.strftime("%H:%M:%S"), "error": str(e)[:300]})
        if not res.get("classification"):
            res.update(classification="SKIPPED-error", justification=str(e)[:160])
    save_state(results_root, st)
    return st


def justify(verdict, a, grades):
    cov = a["coverage"]
    covp = f"{cov:.2f}" if cov is not None else "n/a"
    missed = [g for g in grades if g.get("verdict") in ("missed", "contradicted")][:2]
    if verdict == "FIX":
        src = (a["suspects_confirmed"] or a["model_right_high"])[0]
        return f"suspect/contradicted claim confirmed: {src.get('text', '')[:100]}"
    if verdict.startswith("DELETE"):
        return f"bare model covered {covp} of claims with no contradictions"
    if verdict.startswith("TRIM"):
        return f"coverage {covp}; keep only the missed deltas"
    if verdict == "KEEP":
        hint = "; ".join(m.get("text", "")[:70] for m in missed)
        return f"coverage {covp}; bare model failed: {hint}" if hint else f"coverage {covp}"
    return ""


# --------------------------------------------------------------------------
# Report
# --------------------------------------------------------------------------

def load_all_states(results_root):
    states = []
    for p in sorted((results_root / "state").rglob("*.json")):
        states.append(json.loads(p.read_text()))
    return states


def load_grades_with_claims(results_root, sid):
    """Grades joined with derive.json claim text (grade.json rows only carry
    claim_id; Track B rows already embed text/quote)."""
    gfile = raw_dir(results_root, sid) / "grade.json"
    if not gfile.exists():
        return []
    grades = json.loads(gfile.read_text())["grades"]
    dfile = raw_dir(results_root, sid) / "derive.json"
    by_id = {}
    if dfile.exists():
        by_id = {c["id"]: c for c in json.loads(dfile.read_text())["claims"]}
    for g in grades:
        c = by_id.get(g.get("claim_id"), {})
        if not g.get("text"):
            g["text"] = c.get("text", "")
        if not g.get("quote"):
            g["quote"] = c.get("quote", "")
    return grades


def write_report(results_root, model_id, skills, cfg):
    states = {s["skill"]: s for s in load_all_states(results_root)}
    th = cfg["thresholds"]
    n_a = sum(1 for s in skills if s.track == "A" and not s.is_router)
    n_b = sum(1 for s in skills if s.track == "B" and not s.is_router)
    pf = results_root / "preflight.json"
    pf_status = "PASS" if pf.exists() else "NOT RUN"

    counts = {}
    for st in states.values():
        v = st["result"].get("classification") or "PENDING"
        key = "DELETE-candidate" if v.startswith("DELETE") else v
        counts[key] = counts.get(key, 0) + 1

    lines = [
        f"# Blind-Test Skill Audit — {model_id} — {time.strftime('%Y-%m-%d')}",
        "",
        f"Harness v{HARNESS_VERSION} · {len(skills)} entries ({n_a} Track A, {n_b} Track B, "
        f"{sum(1 for s in skills if s.is_router)} routers skipped) · isolation preflight: {pf_status}",
        "",
        "Scope: complements the structural auditor (skills/shared/skill-auditor, C-01…L-03) and the",
        "CI tripwires (check-freshness.sh, check-api-symbols.sh). This report judges CONTENT",
        "redundancy/staleness only. Track B (generators + spec-document skills) can never emit",
        "DELETE — templates are not assessed here (compilability is owned by check-swift-templates.sh).",
        "**Nothing is deleted without human approval of the rows below.**",
        "",
        "## Summary",
        "",
        "| Verdict | Count |",
        "|---|---|",
    ]
    for v in ("DELETE-candidate", "TRIM", "TRIM(prose)", "KEEP", "FIX",
              "SKIPPED-router", "SKIPPED-error", "PENDING"):
        if counts.get(v):
            lines.append(f"| {v} | {counts[v]} |")
    lines.append("")

    by_cat = {}
    for s in skills:
        by_cat.setdefault(s.category, []).append(s)
    fix_rows, delete_rows, error_rows = [], [], []

    for cat in sorted(by_cat):
        lines += [f"## {cat}", "",
                  "| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |",
                  "|---|---|---|---|---|---|---|"]
        for s in sorted(by_cat[cat], key=lambda x: x.sid):
            st = states.get(s.sid)
            if not st:
                lines.append(f"| {s.sid} | {s.track} | — not run — | | | | |")
                continue
            r = st["result"]
            v = r.get("classification") or "PENDING"
            cov = f"{r['coverage']:.2f}" if r.get("coverage") is not None else "—"
            fq = ",".join(r.get("failed_questions", [])) or "—"
            flags = ", ".join(r.get("flags", [])) or "—"
            lines.append(f"| {s.sid} | {s.track} | {v} | {cov} | {fq} | "
                         f"{r.get('justification', '')} | {flags} |")
            if v == "FIX":
                fix_rows.append((s, st))
            if v.startswith("DELETE"):
                delete_rows.append((s, st))
            if v == "SKIPPED-error":
                error_rows.append((s, st))
        lines.append("")

    lines += ["## Appendix A — FIX detail", ""]
    for s, st in fix_rows:
        lines.append(f"### {s.sid}")
        for c in load_grades_with_claims(results_root, s.sid):
            if c.get("suspect") or (c.get("verdict") == "contradicted"):
                lines.append(f"- `{c.get('verdict')}` {c.get('text', '')[:160]}")
                if c.get("suspect_reason"):
                    lines.append(f"  - suspect: {c['suspect_reason'][:160]} "
                                 f"(cross-check: {c.get('cross_check', 'n/a')})")
        lines.append("")

    lines += ["## Appendix B — DELETE dossiers (the rows requiring human approval)", ""]
    for s, st in delete_rows:
        lines.append(f"### {s.sid}")
        refs = st["result"].get("swiftship_refs", [])
        if refs:
            lines.append(f"- ⚠️ referenced by SwiftShip: {', '.join(refs)} — deletion blocked until paired")
        for c in load_grades_with_claims(results_root, s.sid):
            ev = (c.get("evidence") or "")[:120]
            lines.append(f"- {c.get('verdict')}: {c.get('text', '')[:120]}"
                         + (f"\n  - evidence: “{ev}”" if ev else ""))
        lines.append("")

    lines += ["## Appendix C — errors / truncations", ""]
    for s, st in error_rows:
        lines.append(f"- {s.sid}: {st['errors'][-1]['error'] if st['errors'] else 'unknown'}")
    for st in states.values():
        if "truncated" in st["result"].get("flags", []):
            lines.append(f"- {st['skill']}: supporting files truncated to outline (content budget)")
    lines.append("")

    (results_root / "AUDIT-REPORT.md").write_text("\n".join(lines))
    summary = [{"skill": st["skill"], "track": st["track"],
                "verdict": st["result"].get("classification"),
                "coverage": st["result"].get("coverage"),
                "flags": st["result"].get("flags", [])}
               for st in sorted(states.values(), key=lambda x: x["skill"])]
    (results_root / "summary.json").write_text(json.dumps(summary, indent=1))
    return len(states), counts


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

def resolve_results_root(cfg, model_id=None):
    base = HERE / "results"
    if model_id:
        return base / model_id
    dirs = [d for d in base.glob("*") if d.is_dir() and not d.name.startswith(".")]
    if len(dirs) == 1:
        return dirs[0]
    if not dirs:
        sys.exit("No results dir yet — run preflight/run first.")
    sys.exit("Multiple results dirs: pass --model-id. Have: " + ", ".join(d.name for d in dirs))


def cmd_preflight(cfg, args):
    tmp_root = HERE / "results" / ".preflight-tmp"
    model_id, report = preflight(cfg, tmp_root)
    results_root = HERE / "results" / model_id
    results_root.mkdir(parents=True, exist_ok=True)
    (results_root / "tmp-cwd").mkdir(exist_ok=True)
    (results_root / "preflight.json").write_text(json.dumps(report, indent=1))
    # migrate tmp dir
    print(f"✓ preflight PASS — model {model_id}, {report['claude_version']}")
    print(f"  results dir: {results_root.relative_to(ROOT)}")
    return model_id


def select_skills(skills, args):
    if getattr(args, "all", False):
        sel = skills
    elif getattr(args, "category", None):
        sel = [s for s in skills if s.category == args.category]
    elif getattr(args, "skill", None):
        sel = [s for s in skills if s.sid in args.skill]
    else:
        sys.exit("run: pass --all, --category <cat>, or --skill <cat/skill> …")
    if not sel:
        sys.exit("no skills matched the selection")
    if getattr(args, "limit", None):
        sel = sel[: args.limit]
    return sel


def cmd_run(cfg, args):
    skills = enumerate_skills(cfg)
    sel = select_skills(skills, args)
    if args.dry_run:
        for s in sel:
            print(f"{s.sid:55s} track {s.track}" + ("  [router-skip]" if s.is_router else ""))
        print(f"-- {len(sel)} skills selected (dry run, no calls)")
        return

    model_id = cmd_preflight(cfg, args)
    results_root = HERE / "results" / model_id
    budget = Budget(cfg["max_calls_per_run"])
    manifest, policed = load_api_manifest()
    os_gen = current_os_gen()
    lock = threading.Lock()

    def log(msg):
        with lock:
            print(f"  [{budget.calls:4d} calls] {msg}", flush=True)

    done = 0
    if getattr(args, "force", False):
        for s in sel:
            sp = state_path(results_root, s.sid)
            if sp.exists():
                sp.unlink()

    with concurrent.futures.ThreadPoolExecutor(max_workers=cfg["concurrency"]) as ex:
        futs = {ex.submit(process_skill, s, results_root, cfg, budget,
                          manifest, policed, os_gen, log): s for s in sel}
        for fut in concurrent.futures.as_completed(futs):
            s = futs[fut]
            try:
                st = fut.result()
                v = st["result"].get("classification")
                done += 1
                log(f"{s.sid} → {v}  ({done}/{len(sel)})")
            except Exception as e:  # noqa: BLE001
                log(f"{s.sid} → EXCEPTION {e}")

    n, counts = write_report(results_root, model_id, skills, cfg)
    print(f"\n✓ run complete — {done}/{len(sel)} processed, {budget.calls} calls, "
          f"{n} skills in report")
    print(f"  verdicts so far: {json.dumps(counts)}")
    print(f"  report: {(results_root / 'AUDIT-REPORT.md').relative_to(ROOT)}")


def cmd_list(cfg, args):
    skills = enumerate_skills(cfg)
    n_a = sum(1 for s in skills if s.track == "A" and not s.is_router)
    n_b = sum(1 for s in skills if s.track == "B" and not s.is_router)
    for s in skills:
        size = s.path.stat().st_size
        print(f"{s.sid:55s} track {s.track}  {size:6d}B"
              + ("  [router-skip]" if s.is_router else ""))
    print(f"-- {len(skills)} entries: {n_a} Track A, {n_b} Track B, "
          f"{sum(1 for s in skills if s.is_router)} router-skips")


def cmd_report(cfg, args):
    results_root = resolve_results_root(cfg, args.model_id)
    skills = enumerate_skills(cfg)
    n, counts = write_report(results_root, results_root.name, skills, cfg)
    print(f"✓ report regenerated for {n} skills — {json.dumps(counts)}")
    print(f"  {(results_root / 'AUDIT-REPORT.md').relative_to(ROOT)}")


def cmd_diff(cfg, args):
    new_root = resolve_results_root(cfg, args.model_id)
    old = json.loads((HERE / "results" / args.against / "summary.json").read_text())
    new = json.loads((new_root / "summary.json").read_text())
    old_by = {r["skill"]: r for r in old}
    changed = 0
    for r in new:
        o = old_by.get(r["skill"])
        if o and o["verdict"] != r["verdict"]:
            print(f"{r['skill']:55s} {o['verdict']} → {r['verdict']}")
            changed += 1
    print(f"-- {changed} verdict changes vs {args.against}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("preflight")
    sub.add_parser("list")
    p = sub.add_parser("run")
    p.add_argument("--all", action="store_true")
    p.add_argument("--category")
    p.add_argument("--skill", action="append")
    p.add_argument("--limit", type=int)
    p.add_argument("--force", action="store_true", help="discard existing state for selection")
    p.add_argument("--dry-run", action="store_true")
    p = sub.add_parser("report")
    p.add_argument("--model-id")
    p = sub.add_parser("diff")
    p.add_argument("--against", required=True)
    p.add_argument("--model-id")
    args = ap.parse_args()
    cfg = load_config()
    {"preflight": cmd_preflight, "list": cmd_list, "run": cmd_run,
     "report": cmd_report, "diff": cmd_diff}[args.cmd](cfg, args)


if __name__ == "__main__":
    main()

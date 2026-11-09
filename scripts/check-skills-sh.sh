#!/bin/bash
# skills.sh.json must list every category folder (skills/<cat>/ with a SKILL.md).
#
# The `npx skills` installer (vercel-labs/skills) stops descending once it
# finds a SKILL.md, so our category index files hide every sub-skill below
# them. skills.sh.json lists each category as an extra search container so
# the sub-skills are discovered. A new category that isn't listed would be
# invisible to that installer: this check catches it.
#
# Usage: ./scripts/check-skills-sh.sh

set -u
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$REPO_DIR/skills.sh.json"

[ -f "$CONFIG" ] || { echo "✗ skills.sh.json missing"; exit 1; }

expected=$(cd "$REPO_DIR" && for d in skills/*/; do [ -f "$d/SKILL.md" ] && echo "./${d%/}"; done | sort)
listed=$(grep -oE '"\./skills/[^"]+"' "$CONFIG" | tr -d '"' | sort)

missing=$(comm -23 <(echo "$expected") <(echo "$listed"))
extra=$(comm -13 <(echo "$expected") <(echo "$listed"))

status=0
[ -n "$missing" ] && { echo "✗ categories missing from skills.sh.json:"; echo "$missing" | sed 's/^/    /'; status=1; }
[ -n "$extra" ] && { echo "✗ skills.sh.json lists paths that are not categories:"; echo "$extra" | sed 's/^/    /'; status=1; }
[ $status -eq 0 ] && echo "✓ skills.sh.json lists all $(echo "$expected" | wc -l | tr -d ' ') categories"
exit $status

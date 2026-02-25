#!/usr/bin/env bash
# check-template-version.sh
# Implements catchup Step 1: compare project CLAUDE.md template version against
# the installed template at ~/.claude/templates/CLAUDE.template.md.
#
# Exit codes:
#   0 — versions match, or template file missing (skip)
#   1 — version mismatch (migration required)
#   2 — no CLAUDE.md found in current directory
set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly TEMPLATE_FILE="$HOME/.claude/templates/CLAUDE.template.md"
readonly MIGRATE_SKILL="$HOME/.claude/skills/migrate-project-template/SKILL.md"
readonly PROJECT_CLAUDE="./CLAUDE.md"

# Extracts N from <!-- project-template: N --> in a single line.
# Outputs "0" if no marker is found.
extract_version() {
    local line="$1"
    if [[ "$line" =~ \<!--[[:space:]]*project-template:[[:space:]]*([0-9]+)[[:space:]]*--\> ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0"
    fi
}

main() {
    # Step 1a: Read project CLAUDE.md first line
    if [[ ! -f "$PROJECT_CLAUDE" ]]; then
        echo "[$SCRIPT_NAME] No CLAUDE.md found in current directory — skipping template version check." >&2
        exit 2
    fi

    local project_first_line
    project_first_line=$(head -n 1 "$PROJECT_CLAUDE")

    local project_version
    project_version=$(extract_version "$project_first_line")

    # Step 1b: Read installed template first line
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        echo "[$SCRIPT_NAME] Template file not found at $TEMPLATE_FILE — skipping."
        exit 0
    fi

    local template_first_line
    template_first_line=$(head -n 1 "$TEMPLATE_FILE")

    local template_version
    template_version=$(extract_version "$template_first_line")

    # Step 1c: Compare versions
    if [[ "$project_version" == "$template_version" ]]; then
        echo "[$SCRIPT_NAME] Template version OK (both at v${project_version})."
        exit 0
    fi

    # Step 1d: Versions differ — show migration instructions
    echo "[$SCRIPT_NAME] Template version mismatch: project=v${project_version}, template=v${template_version}" >&2
    echo "" >&2
    echo "Migration required. Follow the steps in:" >&2
    echo "  $MIGRATE_SKILL" >&2
    echo "" >&2

    if [[ -f "$MIGRATE_SKILL" ]]; then
        echo "=== Migration Instructions ===" >&2
        cat "$MIGRATE_SKILL" >&2
        echo "==============================" >&2
    else
        echo "[$SCRIPT_NAME] WARNING: migrate-project-template skill not found at $MIGRATE_SKILL" >&2
    fi

    exit 1
}

main "$@"

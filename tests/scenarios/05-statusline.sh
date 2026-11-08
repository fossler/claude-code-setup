#!/bin/bash

# Scenario: Status line configuration (bundled statusline.sh)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
# shellcheck source=../helpers.sh
source "$SCRIPT_DIR/../helpers.sh"

# Setup test environment
setup_test_env
trap cleanup_test_env EXIT

STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"

scenario "Status line enabled when user accepts (Y)"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    accept_statusline
    decline_agent_teams
' > /dev/null

assert_file_exists "$CLAUDE_DIR/settings.json" "settings.json created"
assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine field exists"
assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine.type" "command" "statusLine type is command"
assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine.command" "$STATUSLINE_SCRIPT" "statusLine points at bundled script"
assert_file_exists "$STATUSLINE_SCRIPT" "statusline.sh installed"
if [[ -x "$STATUSLINE_SCRIPT" ]]; then
    pass "statusline.sh is executable"
else
    fail "statusline.sh is not executable"
fi

scenario "Status line skipped when user declines (n)"

rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null 2>&1

if [[ -f "$CLAUDE_DIR/settings.json" ]] && jq -e '.statusLine' "$CLAUDE_DIR/settings.json" > /dev/null 2>&1; then
    fail "statusLine should not be configured when declined"
else
    pass "statusLine not configured when declined"
fi

if [[ -f "$STATUSLINE_SCRIPT" ]]; then
    fail "statusline.sh should not be installed when declined"
else
    pass "statusline.sh not installed when declined"
fi

scenario "Custom statusLine preserved"

rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
echo '{"statusLine":"custom-command"}' > "$CLAUDE_DIR/settings.json"

output=$(run_add_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_agent_teams
' 2>&1)

assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine" "custom-command" "existing statusLine preserved"
if echo "$output" | grep -q "already configured"; then
    pass "Shows 'already configured' message"
else
    fail "Should show 'already configured' message"
fi
if [[ -f "$STATUSLINE_SCRIPT" ]]; then
    fail "statusline.sh should not be installed when a custom statusLine exists"
else
    pass "statusline.sh not installed for custom statusLine"
fi

scenario "Bundled script refreshed when already configured"

rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
jq -n --arg cmd "$STATUSLINE_SCRIPT" '{statusLine: {type: "command", command: $cmd}}' > "$CLAUDE_DIR/settings.json"
echo "#!/bin/bash
echo stale" > "$STATUSLINE_SCRIPT"

run_add_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_agent_teams
' > /dev/null 2>&1

if cmp -s "$STATUSLINE_SCRIPT" "$PROJECT_DIR/statusline/statusline.sh"; then
    pass "Stale statusline.sh replaced with bundled version"
else
    fail "statusline.sh was not refreshed"
fi

scenario "ccstatusline migrated to bundled script (--add)"

for old_statusline in \
    '{"type": "command", "command": "npx -y ccstatusline@latest"}' \
    '"npx -y ccstatusline@latest"' \
    '{"enabled": true, "command": ["npx", "-y", "ccstatusline"]}'; do
    rm -rf "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR"
    echo "{\"content_version\":2,\"mcp\":[],\"skills\":[]}" > "$INSTALLED_FILE"
    jq -n --argjson sl "$old_statusline" '{statusLine: $sl, keep: "me"}' > "$CLAUDE_DIR/settings.json"

    output=$(run_add_expect '
        deselect_all_mcp
        deselect_all_skills
        decline_agent_teams
    ' 2>&1)

    assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine.command" "$STATUSLINE_SCRIPT" "Migrated: $old_statusline"
    assert_json_eq "$CLAUDE_DIR/settings.json" ".keep" "me" "Other settings kept: $old_statusline"
done
assert_file_exists "$STATUSLINE_SCRIPT" "statusline.sh installed by migration"
if echo "$output" | grep -q "migrated from ccstatusline"; then
    pass "Shows migration message"
else
    fail "Should show migration message"
fi

scenario "ccstatusline migrated to bundled script (--update)"

rm -rf "$CLAUDE_DIR" "$TEST_DIR/.config"
mkdir -p "$CLAUDE_DIR" "$TEST_DIR/.config/ccstatusline"
run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    decline_statusline
    decline_agent_teams
' > /dev/null 2>&1
jq '.statusLine = {"type": "command", "command": "npx -y ccstatusline@latest"}' "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp"
mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
jq '.content_version = 0' "$INSTALLED_FILE" > "$INSTALLED_FILE.tmp"
mv "$INSTALLED_FILE.tmp" "$INSTALLED_FILE"

output=$(run_update_expect '
    confirm_update
    decline_agent_teams
' 2>&1)

assert_json_eq "$CLAUDE_DIR/settings.json" ".statusLine.command" "$STATUSLINE_SCRIPT" "statusLine migrated during update"
assert_file_exists "$STATUSLINE_SCRIPT" "statusline.sh installed during update"
if echo "$output" | grep -q "ccstatusline is no longer used"; then
    pass "Hints that ~/.config/ccstatusline can be deleted"
else
    fail "Should hint that ~/.config/ccstatusline can be deleted"
fi

scenario "Default to yes with empty input (pressing Enter)"

rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    # Press Enter (default is Y)
    expect {Enable context status line} { send "\r" }
    decline_agent_teams
' > /dev/null

assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine enabled with empty input (default Y)"
assert_file_exists "$STATUSLINE_SCRIPT" "statusline.sh installed with empty input"

scenario "Recovery from corrupted settings.json"

rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "this is not valid json {{{" > "$CLAUDE_DIR/settings.json"

output=$(run_install_expect '
    deselect_all_mcp
    deselect_all_skills
    accept_statusline
    decline_agent_teams
' 2>&1)

if echo "$output" | grep -q "corrupted"; then
    pass "Shows corruption warning"
else
    fail "Should show corruption warning"
fi
assert_json_exists "$CLAUDE_DIR/settings.json" ".statusLine" "statusLine configured after recovery"

# ============================================
# statusline.sh output
# ============================================

scenario "statusline.sh output"

SL="$PROJECT_DIR/statusline/statusline.sh"
REPO_DIR="$TEST_DIR/repo"
mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q -b test-branch

# Strip ANSI color codes for comparisons; separate TMPDIR for the Total cache
run_sl() { HOME="$TEST_DIR" TMPDIR="$TEST_DIR/tmp" "$SL" | sed $'s/\033\\[[0-9;]*m//g'; }
check() { [[ "$2" == $3 ]] && pass "$1" || fail "$1 (got: $2)"; }

out=$(echo "{\"model\":{\"display_name\":\"Opus 5.5\"},\"workspace\":{\"current_dir\":\"$REPO_DIR\"},\"context_window\":{\"used_percentage\":42.6}}" | run_sl)
check "Model, ~, branch and rounded used_percentage" "$out" "Opus 5.5 | *@* ~/repo (test-branch) | Ctx: 43%"

out=$(echo "{\"workspace\":{\"current_dir\":\"$REPO_DIR\"},\"context_window\":{\"context_window_size\":200000,\"current_usage\":{\"input_tokens\":5000,\"output_tokens\":900,\"cache_read_input_tokens\":120000,\"cache_creation_input_tokens\":1000}}}" | run_sl)
check "Ctx tokens and percentage from current_usage" "$out" "*| Ctx: 126k (63%)"

transcript="$TEST_DIR/transcript.jsonl"
cat > "$transcript" << 'EOF2'
{"type":"assistant","message":{"id":"m1","usage":{"input_tokens":10,"cache_read_input_tokens":20000,"cache_creation_input_tokens":0}}}
{"type":"assistant","message":{"id":"m1","usage":{"input_tokens":10,"cache_read_input_tokens":20000,"cache_creation_input_tokens":0}}}
{"type":"assistant","isSidechain":true,"message":{"id":"s1","usage":{"input_tokens":190000}}}
{"type":"assistant","message":{"id":"m2","usage":{"input_tokens":100,"output_tokens":500,"cache_read_input_tokens":59900,"cache_creation_input_tokens":0}}}
{"type":"user","message":{"content":"hi"}}
EOF2
out=$(echo "{\"workspace\":{\"current_dir\":\"$REPO_DIR\"},\"transcript_path\":\"$transcript\"}" | run_sl)
check "Transcript fallback: Total deduplicated per message, Ctx from last main-thread usage" "$out" "*| Total: 270.5k | Ctx: 60k (30%)"

echo '{"type":"assistant","message":{"id":"m3","usage":{"input_tokens":1000000}}}' >> "$transcript"
out=$(echo "{\"workspace\":{\"current_dir\":\"$REPO_DIR\"},\"transcript_path\":\"$transcript\"}" | run_sl)
check "Total recomputed after transcript grows" "$out" "*| Total: 1.2M | *"

echo "a" > "$REPO_DIR/f.txt"
git -C "$REPO_DIR" add f.txt
git -C "$REPO_DIR" -c user.name=t -c user.email=t@t commit -q -m init
printf 'b\nc\n' > "$REPO_DIR/f.txt"
out=$(echo "{\"workspace\":{\"current_dir\":\"$REPO_DIR\"}}" | run_sl)
check "Git line changes shown" "$out" "*~/repo (test-branch) +2,-1"

out=$(echo "{\"workspace\":{\"current_dir\":\"$TEST_DIR\"}}" | run_sl)
check "No branch, changes or Ctx when unavailable" "$out" "*@* ~"

out=$(echo '{}' | "$SL")
[[ -n "$out" ]] && pass "Produces output with empty JSON input" || fail "No output with empty JSON input"

print_summary

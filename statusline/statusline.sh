#!/bin/bash

# Claude Code status line (installed by claude-code-setup to ~/.claude/statusline.sh)
#
# Output: Model | user@host ~/path (branch) +ins,-del | Total: 2.4M | Ctx: 86.2k (43%)
#
#   Model      model.display_name
#   +ins,-del  staged + unstaged line changes (hidden when there are none)
#   Total      all tokens of the session (input + output + cache), summed over the transcript
#   Ctx        tokens in the context window and percentage used
#              (grey < 60%, yellow >= 60%, red >= 80% = time for /wrapup)
#
# Claude Code runs this on every status line refresh and passes the session
# as JSON on stdin; the first line printed becomes the status line.
# Requires: jq; git (optional, for branch and changes)

input=$(cat)
field() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

# Format a token count: 950, 86.2k, 2.4M (jq, so it does not depend on the locale)
fmt_tokens() {
    jq -rn --argjson n "$1" '
        if $n >= 1000000 then (($n / 100000 | floor) / 10 | tostring) + "M"
        elif $n >= 1000 then (($n / 100 | floor) / 10 | tostring) + "k"
        else ($n | tostring) end'
}

model=$(field '.model.display_name')
transcript=$(field '.transcript_path')
[[ -f "$transcript" ]] || transcript=""

# Working directory, with $HOME shortened to ~
cwd=$(field '.workspace.current_dir // .cwd')
[[ -z "$cwd" ]] && cwd=$PWD
display_dir=$cwd
if [[ -n "${HOME:-}" && ( "$cwd" == "$HOME" || "$cwd" == "$HOME"/* ) ]]; then
    display_dir="~${cwd#"$HOME"}"
fi

# Git branch and line changes (staged + unstaged, like `git diff --shortstat`)
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
changes=""
if git -C "$cwd" --no-optional-locks rev-parse --verify -q HEAD > /dev/null 2>&1; then
    read -r ins del < <(
        { git -C "$cwd" --no-optional-locks diff --numstat; git -C "$cwd" --no-optional-locks diff --cached --numstat; } 2>/dev/null |
            awk '$1 ~ /^[0-9]+$/ { i += $1; d += $2 } END { print i + 0, d + 0 }')
    (( ${ins:-0} + ${del:-0} > 0 )) && changes="+$ins,-$del"
fi

# Context: tokens and percentage, rounded in jq
#   1. context_window from Claude Code (used_percentage, current_usage, context_window_size)
read -r ctx_tokens pct < <(jq -r '
    def round_int: . + 0.5 | floor;
    .context_window as $c
    | ($c.current_usage | if type == "object" then
          (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
      else null end) as $tokens
    | (if $c.used_percentage != null then $c.used_percentage | round_int
       elif ($tokens != null and ($c.context_window_size // 0) > 0) then $tokens * 100 / $c.context_window_size | round_int
       else null end) as $pct
    | "\($tokens // "-") \($pct // "-")"' <<<"$input" 2>/dev/null)
[[ "$ctx_tokens" =~ ^[0-9]+$ ]] || ctx_tokens=""
[[ "$pct" =~ ^[0-9]+$ ]] || pct=""

#   2. Older Claude Code versions: last main-thread usage entry in the transcript
if [[ -z "$ctx_tokens" && -n "$transcript" ]]; then
    ctx_tokens=$(tail -n 400 "$transcript" | jq -rs '
        [.[] | select(.message.usage? != null and (.isSidechain // false) == false) | .message.usage]
        | last // empty
        | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)' 2>/dev/null)
    [[ "$ctx_tokens" =~ ^[0-9]+$ ]] || ctx_tokens=""
fi
if [[ -z "$pct" && -n "$ctx_tokens" && "$ctx_tokens" -gt 0 ]]; then
    size=200000
    [[ $(field '.model.id') == *"[1m]"* ]] && size=1000000
    pct=$(( ctx_tokens * 100 / size ))
fi

# Total session tokens: sum over the transcript, one entry per message id
# (a message spans several lines with the same usage). Cached by file size,
# so a long transcript is only re-read when it has grown.
total=""
if [[ -n "$transcript" ]]; then
    size_now=$(wc -c < "$transcript" | tr -d ' ')
    cache_dir="${TMPDIR:-/tmp}/claude-statusline-$(id -u)"
    cache_file="$cache_dir/$(printf '%s' "$transcript" | cksum | cut -d' ' -f1)"
    if [[ -f "$cache_file" ]]; then
        read -r cached_size cached_total < "$cache_file"
        [[ "$cached_size" == "$size_now" ]] && total=$cached_total
    fi
    if [[ -z "$total" ]]; then
        total=$(jq -n '
            reduce (inputs | select(.message.usage? != null)
                    | [(.message.id // .uuid),
                       (.message.usage | (.input_tokens // 0) + (.output_tokens // 0)
                                       + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))]) as [$id, $v]
                ({sum: 0, id: null, v: 0};
                 if $id == .id then .sum += ($v - .v) | .v = $v else .sum += $v | .id = $id | .v = $v end)
            | .sum' "$transcript" 2>/dev/null)
        if [[ "$total" =~ ^[0-9]+$ ]]; then
            mkdir -p "$cache_dir" 2>/dev/null && echo "$size_now $total" > "$cache_file" 2>/dev/null
        else
            total=""
        fi
    fi
fi

# Assemble
SEP=$'\033[90m | \033[00m'
out=""
[[ -n "$model" ]] && out+=$'\033[36m'"$model"$'\033[00m'"$SEP"
out+="$(whoami)@$(hostname -s 2>/dev/null || hostname) "$'\033[32m'"$display_dir"$'\033[00m'
[[ -n "$branch" ]] && out+=$' \033[91m'"($branch)"$'\033[00m'
[[ -n "$changes" ]] && out+=$' \033[33m'"$changes"$'\033[00m'
[[ -n "$total" ]] && out+="$SEP"$'\033[36m'"Total: $(fmt_tokens "$total")"$'\033[00m'
if [[ -n "$ctx_tokens" || -n "$pct" ]]; then
    color=$'\033[90m'                       # grey
    if [[ -n "$pct" ]]; then
        if   (( pct >= 80 )); then color=$'\033[91m'   # red: time for /wrapup
        elif (( pct >= 60 )); then color=$'\033[33m'   # yellow
        fi
    fi
    ctx="Ctx:"
    [[ -n "$ctx_tokens" ]] && ctx+=" $(fmt_tokens "$ctx_tokens")"
    if [[ -n "$pct" && -n "$ctx_tokens" ]]; then ctx+=" ($pct%)"
    elif [[ -n "$pct" ]]; then ctx+=" $pct%"
    fi
    out+="$SEP$color$ctx"$'\033[00m'
fi

printf '%s' "$out"

#!/bin/bash

# Status line configuration
# Installs the bundled statusline/statusline.sh to ~/.claude/statusline.sh
# and points settings.json statusLine at it. No external tool is needed.
# Installs from before content v56 used ccstatusline (npx); those are migrated.

# Copy the bundled status line script into $CLAUDE_DIR
install_statusline_script() {
    cp "$SCRIPT_DIR/statusline/statusline.sh" "$CLAUDE_DIR/statusline.sh"
    chmod +x "$CLAUDE_DIR/statusline.sh"
}

# True if settings.json statusLine points at the bundled script
statusline_uses_bundled_script() {
    local claude_settings="$CLAUDE_DIR/settings.json"
    [[ -f "$claude_settings" ]] || return 1
    jq -e --arg cmd "$CLAUDE_DIR/statusline.sh" \
        '.statusLine | type == "object" and .command == $cmd' "$claude_settings" > /dev/null 2>&1
}

# True if settings.json statusLine runs ccstatusline (string, object or array form)
statusline_uses_ccstatusline() {
    local claude_settings="$CLAUDE_DIR/settings.json"
    [[ -f "$claude_settings" ]] || return 1
    jq -e '.statusLine | if type == "object" then .command else . end | tostring | test("ccstatusline")' \
        "$claude_settings" > /dev/null 2>&1
}

# Install the script and set statusLine to it (settings.json must be valid JSON)
set_statusline_to_bundled_script() {
    local claude_settings="$CLAUDE_DIR/settings.json"
    local tmpfile

    install_statusline_script

    # statusLine must be an object with type and command (not a string)
    tmpfile=$(mktemp)
    if ! jq --arg cmd "$CLAUDE_DIR/statusline.sh" \
        '.statusLine = {"type": "command", "command": $cmd}' "$claude_settings" > "$tmpfile" 2>/dev/null; then
        print_error "Failed to update settings.json"
        rm -f "$tmpfile"
        return 1
    fi
    mv "$tmpfile" "$claude_settings"
}

# Replace a ccstatusline statusLine with the bundled script
migrate_from_ccstatusline() {
    set_statusline_to_bundled_script || return 1
    print_success "Status line migrated from ccstatusline to ~/.claude/statusline.sh"
    if [[ -d "$HOME/.config/ccstatusline" ]]; then
        print_info "~/.config/ccstatusline is no longer used and can be deleted"
    fi
}

# Keep an installer-managed status line current (called by --update):
# migrate ccstatusline, refresh the bundled script, leave custom status lines alone
update_statusline() {
    if statusline_uses_ccstatusline; then
        migrate_from_ccstatusline
    elif statusline_uses_bundled_script; then
        install_statusline_script
        print_success "Status line script updated"
    fi
}

# Configure status line
configure_statusline() {
    local claude_settings="$CLAUDE_DIR/settings.json"

    # Already configured: migrate ccstatusline, refresh our script, keep anything else
    if [[ -f "$claude_settings" ]] && jq -e '.statusLine' "$claude_settings" > /dev/null 2>&1; then
        if statusline_uses_ccstatusline; then
            migrate_from_ccstatusline
        elif statusline_uses_bundled_script; then
            install_statusline_script
            print_info "statusLine already configured (script updated)"
        else
            print_info "statusLine already configured"
        fi
        return 0
    fi

    # Non-interactive mode: auto-enable statusline
    if [[ "$YES_MODE" = "true" ]]; then
        print_info "Enabling status line (non-interactive mode)"
    else
        echo ""
        echo "The status line shows model, directory, git branch and context usage (e.g., Ctx: 42k (21%))"
        echo "Useful to know when to run /wrapup"
        echo ""
        local enable_statusline
        enable_statusline=$(read_input "Enable context status line? (Y/n): ") || enable_statusline="Y"

        if [[ "$enable_statusline" = "n" ]] || [[ "$enable_statusline" = "N" ]]; then
            print_info "Status line skipped"
            return 0
        fi
    fi

    # Validate existing settings.json if present
    if [[ -f "$claude_settings" ]]; then
        if ! jq -e '.' "$claude_settings" > /dev/null 2>&1; then
            print_warning "settings.json appears corrupted, recreating..."
            echo '{}' > "$claude_settings"
        fi
    else
        echo '{}' > "$claude_settings"
    fi

    set_statusline_to_bundled_script || return 1

    print_success "Status line enabled"
    echo "  Customize: edit ~/.claude/statusline.sh"
}

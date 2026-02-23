---
name: catchup
description: Understands recent changes in the project and update context accordingly. This is automatically triggered after `/clear` or when starting a new chat, to ensure CLAUDE has up-to-date context on the project status, recent decisions, and relevant Records.
disable-model-invocation: false
user-invocable: true
---

## Tasks

Copy this checklist and check off items as you complete them:

```
Catchup Progress:
- [ ] 1. Check project template version
- [ ] 2. Read README.md
- [ ] 3. Read changed files
- [ ] 4. Load relevant Records
- [ ] 5. Check Recent Decisions
- [ ] 6. Read open private notes
- [ ] 7. Load context skills
- [ ] 8. Summary
```

1. **Check project template version**
   - Read first line of project CLAUDE.md → extract version from `<!-- project-template: N -->`
   - If no marker found: treat as version `0`
   - Use the Read tool on `~/.claude/templates/CLAUDE.template.md` (expand `~` to absolute path) → extract version from first line
   - If file does not exist (Read returns error) → skip this step
   - If versions match → skip, continue to next task
   - If versions differ → use the Read tool on `~/.claude/commands/migrate-project-template.md` (expand `~` to absolute path) → follow the migration steps inside
   - After migration completes → continue with step 2 (Read project README.md)

2. **Read project README.md**
   - If exists: Read `README.md` in project root
   - Understand project purpose and structure

3. **Read changed files**
   - If Git: `git diff --name-only HEAD~10` (last 10 commits)
   - Or: `git status` for uncommitted changes
   - Read relevant changed files

4. **Load relevant Records**
   - Check "## Current Status" and "## Future" tables in project CLAUDE.md
   - If work is in progress or a next step references a Record → Read that Record
     - Example: Status shows "OAuth2 | In Progress | [Record 019]" → Read `docs/records/019-oauth2-auth.md`
   - Also check for designs ready to implement or in progress:
     - If `docs/records/` exists: `grep -l "^Designing\|^Designed\|^In Progress" docs/records/*.md`
     - If directory doesn't exist: skip
   - If found: Load these Records (user may want to continue /design workflow or start implementing)
   - Only load Records relevant to current/next work, not all

5. **Check Recent Decisions**
   - Read the "## Recent Decisions" table in project CLAUDE.md
   - Note any decisions relevant to current work
   - These are small decisions with reasoning that survived the last `/clear`

6. **Read open private notes**
   - Check for `docs/notes/*.open.md` files
   - If found: Read them (these are active session notes)
   - Summarize key points from open notes
   - These contain context from previous sessions (research, strategies, TODOs)

7. **Load context skills**
   - Check `Tech Stack:` in project CLAUDE.md
   - Load matching skills from `~/.claude/skills/` (see Skill Loading in global CLAUDE.md)
   - Example: Tech Stack includes "Bash" → Read `standards-shell/SKILL.md`

8. **Summary**
   - What was recently changed?
   - What Records were loaded and why?
   - Open notes found? Summarize key points
   - What's the next step according to CLAUDE.md?

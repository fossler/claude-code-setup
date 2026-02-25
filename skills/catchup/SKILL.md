---
name: catchup
description: Orients Claude after `/clear` or a new chat by reading recent git changes, loading relevant Records, and summarizing the current project state. Use at the start of every new session or after clearing context.
disable-model-invocation: true
allowed-tools: git, Bash(grep *), Bash(bash *), Read
---

## Tasks

1. **Read changed files**
   - Git history: !`git log -n 3` to see recent commits
   - Open changes: !`git status` for uncommitted changes

2. **Load relevant Records**
   - Check Current Status and Future tables in project CLAUDE.md
   - If work is in progress or a next step references a Record → Read that Record
     - Example: Status shows "OAuth2 | In Progress | [Record 019]" → Read `docs/records/019-oauth2-auth.md`
   - Also check for designs ready to implement or in progress:
     - !`grep -l "^Designing\|^Designed\|^In Progress" docs/records/*.md`
   - If found: Load these Records (user may want to continue /design workflow or start implementing)
   - Only load Records relevant to current/next work, not all

3. **Summary**
   - What was recently changed?
   - What Records were loaded and why?
   - Open notes found? Summarize key points
   - What's the next step according to CLAUDE.md?

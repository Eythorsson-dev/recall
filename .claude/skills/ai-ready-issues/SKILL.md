---
name: ai-ready-issues
description: List GitHub issues that are ready for an autonomous agent to pick up — open, labeled AI-Ready, not in-progress, and with no unresolved blockers. Use when the user asks "what's ready?", "what can I work on?", "list AI-ready tickets", "show the queue", or similar.
---

# AI-ready issue queue

Lists open GitHub issues that satisfy all of:

- Labeled `AI-Ready` (admitted to the queue, typically by `refine-ticket`).
- Not labeled `in-progress` (not currently claimed by an agent or session).
- No unresolved `#N` blockers in the issue's `## Blocked by` section.

## How to run

The skill bundles a bash script:

```
.claude/skills/ai-ready-issues/ai-ready-issues.sh           # tab-separated text
.claude/skills/ai-ready-issues/ai-ready-issues.sh --json    # JSON array
```

Text format: one row per issue, `#N<TAB>title<TAB>labels`.
JSON format: array of `{ number, title, url, labels }`.

## Output interpretation

If the script prints nothing, the queue is empty — either no tickets carry
`AI-Ready`, or all that do are claimed (`in-progress`) or blocked. To
distinguish:

```
gh issue list --label AI-Ready --state open    # everything labeled AI-Ready
gh issue list --label in-progress --state open # everything currently claimed
```

## How it decides

For each candidate (open + `AI-Ready` + not `in-progress`):

- Parse the body for a `## Blocked by` section.
- Each `- #N` entry is resolved by checking whether issue `N` is still open
  (resolved against the live open-issue set, not a snapshot).
- Free-text entries (e.g. "CloudKit milestone") are treated as unresolved
  because their state isn't programmatically checkable. Use `#N` refs when
  possible.

## Notes

- `AI-Ready` is the queue filter; `in-progress` is the lock. They're added
  and removed by sibling skills:
  - `refine-ticket` adds `AI-Ready` after grilling produces an implementable body.
  - `implement-ticket` adds `in-progress` when it claims a ticket; merging
    the PR (which carries `Closes #N`) auto-clears both the issue and its labels.
- This skill is read-only. It never edits issues or labels.

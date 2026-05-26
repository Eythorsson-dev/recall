---
name: refine-ticket
description: Refine a sparse or ambiguous GitHub issue into one an autonomous implementation agent can pick up. Runs a grilling session against the project's domain model, writes a structured body back to the ticket, and labels it AI-Ready. Use when the user says "refine #N", "prepare ticket N", "make N AI-ready", or similar.
---

# Refine a GitHub ticket for autonomous implementation

Given a ticket that's too sparse or ambiguous for an agent to pick up, run a
focused grilling session to surface the missing context, write the
refined understanding back to the ticket body, and admit it to the AI-Ready
queue.

This skill is the **queue admission** counterpart to `implement-ticket`:
refine-ticket adds the `AI-Ready` label, implement-ticket consumes it.

## Inputs

A single GitHub issue number, provided by the user. If they didn't include
one in the invocation, ask — do not guess and do not pick from the queue.

## Steps

### 1. Fetch the ticket

```
gh issue view <N> --json number,title,state,body,labels,url
```

Stop and tell the user if:

- `state` is `CLOSED`.
- `labels` contains `in-progress` — someone is already working on it; refining
  underneath them would clobber their context.
- `labels` already contains `AI-Ready` — ask whether to re-refine (the ticket
  was previously deemed ready) or skip.

### 2. Grill against the domain

Invoke the `grill-with-docs` skill. The grilling session walks the design tree
question-by-question, sharpens terminology against `CONTEXT.md` and ADRs,
stress-tests scenarios, and writes resolved terms / decisions inline to the
project's docs as it goes.

Treat the ticket's title and existing body (if any) as the seed plan. Continue
until either:

- the user signals they're satisfied, or
- there are no more meaningful questions to ask.

Do **not** write to the ticket during grilling — capture decisions in
`CONTEXT.md` / ADRs (per grill-with-docs's native behavior) and in your own
working notes. The ticket update is a single atomic step at the end.

### 3. Synthesize the refined ticket body

Draft a structured body in this shape:

```markdown
## Problem
<the bug, desired behavior, or capability, in plain language>

## Acceptance criteria
- [ ] <concrete, testable outcome>
- [ ] <...>

## Implementation context
- Key files: `path/to/foo.swift`, `path/to/bar.swift`
- Relevant terms: <link to or quote CONTEXT.md entries that matter>
- Relevant ADRs: <link to any ADR the implementer must respect>

## Out of scope
- <what NOT to change in this ticket>

## Blocked by
- <#M references for prerequisite tickets, or omit the section entirely>

## Open questions
- <ideally none — every remaining question is a risk to the implementer>
```

Omit any section that has no content (e.g. drop `## Blocked by` if there are
no dependencies). Keep `## Open questions` only if there are genuinely
unresolved items — an AI-Ready ticket should have none.

Show the draft to the user. Iterate until they approve. Do **not** push to
GitHub on your own judgement.

### 4. Write the body back

```
gh issue edit <N> --body "$DRAFT"
```

**Verify by reading it back** — `gh issue edit` has been observed to return a
success-looking URL while silently no-op'ing:

```
gh issue view <N> --json body -q '.body' | head -20
```

Confirm the first lines match the draft. If not, retry once; if it still
doesn't stick, stop and surface to the user.

### 5. Label `AI-Ready`

```
gh issue edit <N> --add-label AI-Ready
gh issue view <N> --json labels -q '[.labels[].name]'
```

Confirm `AI-Ready` is in the returned list. Retry once if missing; stop and
surface if it still isn't there. (Same silent-no-op failure mode as the body
write.)

### 6. Report

Return the issue URL and a one-line summary of what was refined.

## Notes

- The grilling step writes to `CONTEXT.md` / `docs/adr/` as decisions
  crystallise — that's grill-with-docs's job, and those changes should be
  committed normally. The refine-ticket skill itself doesn't touch project
  files; it only edits the GitHub issue.
- Don't add `AI-Ready` until the body has been successfully written. The
  label is a promise that the ticket is implementable; an empty or stale
  body would break that promise.
- If grilling surfaces that the work is actually a PRD (multiple slices),
  stop refining and tell the user. PRD-level tickets aren't AI-Ready — the
  slices are.

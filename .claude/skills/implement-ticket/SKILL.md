---
name: implement-ticket
description: Given a GitHub issue number, claim it with the in-progress label, create an isolated worktree, implement the work, and open a draft PR. Use when the user asks to "implement #N", "work on ticket N", "start on issue N", or similar.
---

# Implement a GitHub ticket end-to-end

Given an issue number, claim it, do the work in an isolated worktree, and hand
back a draft PR ready for review.

## Inputs

A single GitHub issue number, provided by the user. If they did not include
one in the invocation, ask which ticket — do not guess and do not pick from
the AI-Ready queue.

## Steps

### 1. Validate eligibility

Fetch the issue details:

```
gh issue view <N> --json state,labels,body
```

Stop and tell the user if any of these hold:

- `state` is `CLOSED`.
- `labels` contains `in-progress` — already claimed by another agent or session.
- The body has a `## Blocked by` section with unresolved entries. For each
  `#M` reference, check `gh issue view <M> --json state` and treat it as a
  blocker if still `OPEN`. Free-text entries (no `#M` ref) count as
  unresolved on their own — surface them to the user.

This skill does **not** look at the `AI-Ready` label or run
`scripts/ai-ready-issues.sh`. Those belong to the queue filter that *picks*
which ticket to work on next. Once a caller has invoked this skill on a
specific ticket, the only question is whether that ticket itself is
implementable right now.

### 2. Claim the ticket

Add the `in-progress` label so other agents and this script skip it, then
**verify by reading the labels back** — `gh issue edit` has been observed to
return a success-looking URL while silently no-op'ing:

```
gh issue edit <N> --add-label in-progress
gh issue view <N> --json labels -q '[.labels[].name]'
```

Confirm `in-progress` is in the returned list. If it isn't, retry once; if it
still isn't, stop and tell the user — without a confirmed claim there is no
lock and a parallel agent could pick up the same ticket.

### 3. Create an isolated worktree

Use the **EnterWorktree** tool with `name: "issue-<N>"`. This branches from
`origin/main` and switches the session into the new worktree.

Do **not** use `git worktree add` from the shell — EnterWorktree integrates
with the session and the harness's cleanup flow.

### 4. Read the ticket

```
gh issue view <N> --json title,body,labels
```

Read the body carefully. Note acceptance criteria, design constraints,
referenced files, and any cross-links. If the ticket is a PRD or umbrella
issue (label `prd`, or body lists multiple "Slice" sub-issues), stop and ask
the user which slice to implement — do not attempt the whole PRD in one PR.

### 5. Implement

Do the work described in the ticket. Default rules:

- For non-trivial logic, follow the project's TDD pattern (see the `tdd` skill).
- Run the build and any relevant tests before declaring done.
- Make atomic commits with messages explaining the *why*. Reference the issue
  with `Refs #<N>` in commit bodies (reserve `Closes #<N>` for the PR).
- Respect the conventions in `CONTEXT.md` and any nearby code.

### 6. Push the branch

```
git push -u origin HEAD
```

### 7. Open a draft PR

```
gh pr create --draft --title "<short imperative title>" --body "$(cat <<'EOF'
## Summary
- <1–3 bullets describing what changed and why>

## Test plan
- [ ] <how to verify, step by step>

Closes #<N>
EOF
)"
```

Use `--draft` — the work shows as in-flight; the user marks it ready when
they've reviewed. `Closes #<N>` in the body wires GitHub's auto-close so the
issue (and its `in-progress` label) is cleared when the PR merges.

### 8. Report

Return the PR URL to the user, plus a one-line summary of what was changed.

## On failure or partial work

If you hit a blocker you cannot resolve (missing context, unclear requirement,
external dependency), **do not remove the `in-progress` label**:

- Leave the worktree as-is so work can resume.
- Explain the blocker to the user.
- Let them decide whether to release the claim (`gh issue edit <N>
  --remove-label in-progress`) or keep it while they unblock you.

This protects against an agent crash leaving the queue empty *and* the work
unfinished.

## Notes

- `in-progress` is the lock; `AI-Ready` is the queue filter. Both labels are
  intentional — see `scripts/ai-ready-issues.sh`.
- Branch and worktree name are both `issue-<N>` for traceability.
- The PR is draft-by-default. Reviewers (or the user) mark it ready.

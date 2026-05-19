// Sequential Reviewer — implement-then-review loop
//
// This template drives a two-phase workflow per issue:
//   Phase 1 (Implement): A sonnet agent picks an open GitHub issue, works on it
//                        on a dedicated branch, commits the changes, and signals
//                        completion.
//   Phase 2 (Review):    A second sonnet agent reviews the branch diff and either
//                        approves it or makes corrections directly on the branch.
//
// The outer loop repeats up to MAX_ITERATIONS times, processing one issue per
// iteration. This is a middle-complexity option between the simple-loop (no review
// gate) and the parallel-planner (concurrent execution with a planning phase).
//
// Usage:
//   npx tsx .sandcastle/main.mts
// Or add to package.json:
//   "scripts": { "sandcastle": "npx tsx .sandcastle/main.mts" }

import * as sandcastle from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";
import { execSync } from "node:child_process";
import { writeFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// ---------------------------------------------------------------------------
// Credentials — extract OAuth token from macOS Keychain and write to a temp
// file that Docker can mount. On Linux inside Docker there is no Keychain, so
// Claude Code falls back to reading ~/.claude/.credentials.json.
// ---------------------------------------------------------------------------

const credDir = join(tmpdir(), "sandcastle-claude-creds");
mkdirSync(credDir, { recursive: true });
const credFile = join(credDir, ".credentials.json");

try {
  const raw = execSync(
    "security find-generic-password -s 'Claude Code-credentials' -w",
    { encoding: "utf8" }
  ).trim();
  writeFileSync(credFile, raw, { mode: 0o600 });
} catch (e) {
  throw new Error(
    "Could not read Claude Code credentials from Keychain. Make sure you are logged in (`claude /login`)."
  );
}

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

// Maximum number of implement→review cycles to run before stopping.
// Each cycle works on one issue. Raise this to process more issues per run.
const MAX_ITERATIONS = 1;

const hooks = {};

const copyToWorktree: string[] = [];

const sandbox = () =>
  docker({
    mounts: [
      // Host ~/.claude (settings, plugins, etc.) minus credentials
      { hostPath: "~/.claude", sandboxPath: "/home/agent/.claude" },
      // Credentials extracted from Keychain, placed where Claude Code expects them
      { hostPath: credFile, sandboxPath: "/home/agent/.claude/.credentials.json" },
    ],
  });

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

for (let iteration = 1; iteration <= MAX_ITERATIONS; iteration++) {
  console.log(`\n=== Iteration ${iteration}/${MAX_ITERATIONS} ===\n`);

  // -------------------------------------------------------------------------
  // Phase 1: Implement
  // -------------------------------------------------------------------------
  const implement = await sandcastle.run({
    hooks,
    copyToWorktree,
    sandbox: sandbox(),
    branchStrategy: { type: "merge-to-head" },
    name: "implementer",
    maxIterations: 100,
    agent: sandcastle.claudeCode("claude-opus-4-6"),
    promptFile: "./.sandcastle/implement-prompt.md",
  });

  const branch = implement.branch;

  if (!implement.commits.length) {
    console.log("Implementation agent made no commits. Skipping review.");
    continue;
  }

  console.log(`\nImplementation complete on branch: ${branch}`);
  console.log(`Commits: ${implement.commits.length}`);

  // -------------------------------------------------------------------------
  // Phase 2: Review
  // -------------------------------------------------------------------------
  await sandcastle.run({
    hooks,
    copyToWorktree,
    sandbox: sandbox(),
    branchStrategy: { type: "head" },
    name: "reviewer",
    maxIterations: 1,
    agent: sandcastle.claudeCode("claude-opus-4-6"),
    promptFile: "./.sandcastle/review-prompt.md",
    promptArgs: {
      BRANCH: branch,
    },
  });

  console.log("\nReview complete.");
}

console.log("\nAll done.");

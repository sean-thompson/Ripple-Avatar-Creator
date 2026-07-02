---
description: Pick up the next task from PLAN.md, plan it, review it (Codex if available, Claude sub-agent otherwise), implement, hand back for testing, mark done
allowed-tools: Bash(find, cat, grep, ls, command, which, mktemp, rm, codex, codex exec, codex exec resume), Read, Write, Edit, Glob, Agent, AskUserQuestion
model: sonnet
---

I'll work the next uncompleted task from a feature's `PLAN.md` through the full loop: plan → review → implement → test → mark done. Review runs against Codex if you have the CLI installed, otherwise falls back to a Claude sub-agent as adversarial reviewer.

Run this once per task. Clearing context between tasks keeps each invocation self-contained — but if you keep context (e.g. the window still has plenty of room), **Step 0** first reconciles the plan with what was just done before moving on.

## Reference Files

Read by the planning sub-agent in Step 2:

- `README.md` — architecture overview
- `CONTROLLER_GUIDE.md`, `MODEL_GUIDE.md`, `VIEW_GUIDE.md`, `SERVICES_GUIDE.md`, `CONFIG_GUIDE.md` — MVC patterns
- `BOLT_API.md` — networking library
- `features/<slug>/SPEC.md` — the spec for acceptance criteria cross-check
- `features/<slug>/PLAN.md` — the task list, to find the next `[TODO]` / `[PARTIAL]` task

## Interactive Flow

### Step 0: Reconcile the plan with retained context (only when context carried over)

This skill is normally run once per task with a cleared context. But the user will often invoke it **without clearing** when the context window still has room — so the conversation may already hold the just-completed task's implementation, its bug-fix detours, and decisions made along the way. Use that retained context before picking the next task:

- If the context is **fresh** — no prior work on this feature in the conversation — skip this step silently and go to Step 1.
- Otherwise, do a quick reconciliation of `features/<slug>/PLAN.md` against what actually happened in the conversation, looking for:
  - **Status drift** — a task completed in-conversation but not yet marked `[DONE]`, or sub-task states that changed.
  - **Hard-won learnings** — if the current step took significant back-and-forth or detours to nail, a short implementation note on that task (like the existing `>` notes) can save the next session from repeating the pain. Consider a memory too, per the memory guidance.
  - **Scope changes** — work added, dropped, deferred, or re-ordered during implementation; dependencies that shifted.
  - **New follow-ups** — bugs or polish deliberately deferred that belong as a future task or sub-task.
- If you find something worth changing, **propose the specific edits and wait for the user's confirmation before editing `PLAN.md`.** Never rewrite it silently. If nothing's warranted, say so in one line and move on.

Keep this lightweight — it's a reconciliation, not a re-plan. Then continue to Step 1.

### Step 1: Identify the next task

- If multiple `features/*/` folders exist and no slug was passed as an argument, ask which feature.
- Open `features/<slug>/PLAN.md`. Find the first task whose status is not `[DONE]`.
- If every task is `[DONE]`, tell the user the feature is complete and stop.
- Announce:

```
Starting Task N: <Task Name>
Status: [TODO] | [PARTIAL]
```

Show the user the task's acceptance criteria and sub-tasks before proceeding.

### Step 2: Plan the task (sub-agent)

Launch a planning sub-agent (`Agent` tool, `Plan` subagent type, or general-purpose) with a self-contained brief that includes:

- The full architecture reading order above
- Instruction to explore `Source/` fully for existing patterns
- The task section from `features/<slug>/PLAN.md` (acceptance criteria, refs, sub-tasks)
- The relevant sections from `features/<slug>/SPEC.md` (the Refs pointers in the task)
- Any previously `[DONE]` tasks' acceptance-criteria summaries, so the sub-agent knows what's already built
- Instruction to produce a **concrete, file-level implementation plan** — not architectural choices, because those are settled by the existing patterns

The sub-agent returns the plan as text. Capture it for Step 3.

### Step 3: Plan review (inline, Codex-or-Claude)

Detect whether Codex CLI is available:

```bash
command -v codex >/dev/null 2>&1 && echo HAVE_CODEX || echo NO_CODEX
```

Tell the user which reviewer is running.

#### Step 3a: Codex path (if available)

Write the plan to a temp file and run Codex in read-only sandbox mode. This follows the same protocol as the existing `/codex-review` skill — keep the two consistent.

```bash
REVIEW_DIR=$(mktemp -d)
# Write plan to $REVIEW_DIR/claude-plan.md including any
# project-specific review instructions at the top.
codex exec -m gpt-5.3-codex -s read-only -o "$REVIEW_DIR/codex-review.md" \
  "<review prompt — see below>"
```

**Capture the Codex session id** from the output line `session id: <uuid>` — needed for `codex exec resume` on subsequent rounds. Do not use `--last`.

Read `$REVIEW_DIR/codex-review.md`. If verdict is `APPROVED`, go to Step 4. If `REVISE`, revise the plan based on feedback, rewrite the temp file, resume the Codex session:

```bash
codex exec resume "$CODEX_SESSION_ID" \
  "I've revised the plan. The updated plan is in $REVIEW_DIR/claude-plan.md.
   Here's what changed: <list>.
   Re-review. APPROVED or REVISE." 2>&1 | tail -80
```

Iterate up to 5 rounds. Show each round's feedback and revisions to the user. At round 5, pause and ask whether to continue or stop.

Cleanup: `rm -rf "$REVIEW_DIR"` after the loop exits.

#### Step 3b: Claude fallback (if Codex absent or errors)

Tell the user: *"Codex not available — falling back to a Claude sub-agent reviewer."*

Spawn an `Agent` (general-purpose subagent) with a self-contained adversarial-reviewer brief:

```
You are reviewing a task implementation plan. Be a sceptical,
thorough, second-opinion reviewer — actively try to find issues
the author may have missed. You have read-only access to the
codebase for context.

## Plan under review

<insert the plan content>

## Review criteria

### Correctness
- Will this plan achieve the task's acceptance criteria?
- Are there logic errors, off-by-one mistakes, or incorrect assumptions?
- Does it match the SPEC's design tensions and resolutions?

### Code quality
- DRY — any duplicated logic that should be shared?
- Separation of concerns — responsibilities in the right layer
  (Model / Controller / View / Service / Config)?
- Reuse of existing utilities and patterns rather than reinventing.

### Consistency with codebase
- Does the plan follow this repo's Models-are-authoritative,
  intents-via-Network, syncState-on-every-mutation conventions?
- Naming consistent with existing code?
- No new patterns introduced where existing ones would work?

### Security
- User input validated at system boundaries?
- Any client data trusted without server-side validation?
- Race conditions, ordering dependencies, or data-leakage concerns?

### Risks & edge cases
- What could go wrong? Data loss, corruption, undefined states?
- Boundary conditions handled (empty lists, max values, concurrency)?

### Completeness
- Every acceptance criterion has a corresponding plan step?
- Sub-tasks concrete enough to implement without guessing?
- Anything forgotten or left vague?

## Architecture docs to read for context

- README.md
- CONTROLLER_GUIDE.md, MODEL_GUIDE.md, VIEW_GUIDE.md
- SERVICES_GUIDE.md, CONFIG_GUIDE.md
- BOLT_API.md

## Output

Be specific and actionable. If you find substantive issues,
list them numbered with suggested fixes. If the plan is solid
and ready to implement, end your review with exactly:

VERDICT: APPROVED

If changes are needed, end with exactly:

VERDICT: REVISE
```

Parse the verdict from the sub-agent's returned text. If `REVISE`, revise the plan based on feedback, then launch a fresh sub-agent with the revised plan and the prior round's feedback included for context:

```
## Prior round's feedback
<previous reviewer's findings>

## Changes made in response
<list>

## Revised plan
<insert>
```

Iterate up to 5 rounds. Show each round to the user. Pause at round 5 with summary.

#### Review prompt — shared text for both paths

```
Review the implementation plan for Task N (<task name>) of the
"<feature name>" feature.

## Default review criteria

<the same six criteria blocks — correctness, code quality,
consistency, security, risks, completeness>

## Project context to read

- README.md
- CONTROLLER_GUIDE.md, MODEL_GUIDE.md, VIEW_GUIDE.md
- SERVICES_GUIDE.md, CONFIG_GUIDE.md
- BOLT_API.md
- features/<slug>/SPEC.md — design tensions & resolutions section
- Source/ — existing patterns

## Acceptance criteria this plan must satisfy

<copy from the task section of PLAN.md>

## Plan under review

<insert plan>

If solid, end with: VERDICT: APPROVED
If changes needed, end with: VERDICT: REVISE
```

### Step 4: User approval

Present the approved plan with:

- Brief summary of the task and what it achieves
- Implementation steps, numbered
- Any trade-offs or concerns the reviewer raised
- Any open questions needing user input before implementation

Wait for an explicit go-ahead before implementing. Don't accept silence as approval.

### Step 5: Implement

Implement the approved plan in the main context (not a sub-agent). Keep the full plan + reviewer feedback + implementation in one conversation for coherence.

- Write code in `Source/`.
- Follow the patterns in the architecture guides.
- Use `Network.Actions.*` constants, never magic strings.
- Models are authoritative — never trust client data.
- A **moving / position-critical object** (ball, projectile, vehicle, moving platform) is **server-Workspace-authoritative**: the server moves the real Part, with network ownership handed to the most relevant player. NEVER reconstruct its motion on the client from replicated model state — that fights Roblox's own Workspace replication and causes lag/teleporting. Follow the task's **Replication** line; if it's an OPEN QUESTION, resolve it with the user before building. (Cosmetic/non-critical things — particles, trailing pets, local feedback — are the opposite: model + client view.)
- Call `syncState()` after every state mutation.
- Use `/create-controller`, `/create-model`, `/create-view`, `/create-service`, `/create-config` to scaffold new components where the plan suggests them.
- If Studio MCP tools are available and the plan requires Workspace objects, tags, or attributes, use them. Do NOT deploy code modules via MCP — code syncs through Rojo.

### Step 6: Hand back for testing

After implementation, tell the user in this exact shape:

```
**What was implemented:**
- <files created / modified, one bullet per file>

**How to test:**
1. <specific step in Roblox Studio>
2. <next step>
3. <...>

**What you should see:**
- Step 1 → <expected behaviour>
- Step 2 → <expected behaviour>
- <...>

**What to watch for:**
- <edge case worth manually checking>
- <potential regression in adjacent features>
```

Ask the user to confirm it works as expected.

### Step 7: Bug-fix loop (if bugs reported)

Stay in the same session:

1. Ask what went wrong (what they did, what they expected, what happened).
2. Use `get_console_output` via Studio MCP if available.
3. Diagnose and fix. Follow the same architecture rules.
4. Tell the user what changed, ask for re-test.
5. Repeat until confirmed.

Do NOT mark the task `[DONE]` while bugs are unresolved. Do NOT suggest clearing context mid-fix.

### Step 8: Mark complete

Once the user confirms:

1. Edit `features/<slug>/PLAN.md`: change the task's status to `[DONE]`, update sub-task statuses.
2. Tell the user:

```
Task N: <Task Name> is complete and marked [DONE] in features/<slug>/PLAN.md.

Next task: Task M: <Next Task Name> (or: "All tasks complete.")

Please /clear and run /next-task when you're ready for the next one.
```

---

## Implementation Details (Internal)

### Codex detection

Use `command -v codex` (POSIX) — works on Git Bash under Windows. Do not rely on `which`. If the binary exists but `codex exec --help` fails (auth issue, outdated), fall back to Claude reviewer rather than looping on a broken CLI.

### Codex session id capture

From Codex's stdout, the session id appears on a line like `session id: <uuid>`. Grep for it once and store in a shell variable. Required for `codex exec resume` on rounds 2+.

### Fallback reviewer independence

The Claude reviewer sub-agent must not be seeded with the author's (this session's) reasoning beyond the plan and the criteria. The goal is independent adversarial review — letting the sub-agent critique the plan fresh is the whole point. Don't paste the planning sub-agent's reasoning into the reviewer brief.

### Iteration cap

Both paths cap at 5 rounds. At round 5, pause and surface to user:

```
Plan review has gone 5 rounds. Current state:

**Resolved:** <substantive issues fixed>
**Remaining:** <what's still flagged>

The remaining items are <architectural / minor>. Options:
- Continue iterating (if remaining items are structural)
- Stop here and handle during implementation (if detail-level)
- Abort this task entirely
```

### When revisions between rounds are cosmetic

If Codex or the Claude reviewer starts suggesting variable-name tweaks, comment wording, or minor reorderings, those are implementation-time concerns. Acknowledge them as notes and stop iterating — don't loop on style.

### Revision discipline

Between rounds, **actively revise the plan**. Don't pass the reviewer's complaints back as-is — integrate the feedback into a changed plan. Each round should show the user what specifically changed.

If a revision would contradict the user's explicit requirements from the SPEC or earlier conversation, skip that revision and note it to the user.

### Task identification — parse PLAN.md

Look for lines matching `^### Task N:` and the `**Status:**` line below. The first task whose status is `[TODO]` or `[PARTIAL]` is the next task. If multiple `[PARTIAL]` exist, take the earliest (sequential order matters).

### Marking [DONE] in PLAN.md

Use `Edit` tool, not `Write`. Replace the task's `**Status:** [TODO]` or `**Status:** [PARTIAL]` with `**Status:** [DONE]`. Also update sub-task `[TODO]` markers to `[DONE]` as appropriate — only for sub-tasks that were actually completed.

### Slug resolution

- If user passed a slug as argument: use it. Verify `features/<slug>/PLAN.md` exists.
- If not, list subdirectories under `features/` via `Bash(ls)`. If one, use it. If multiple, ask via `AskUserQuestion`.
- If none, tell the user to run `/create-spec` and `/create-plan` first, then stop.

### What I do NOT do

- I do not modify `SPEC.md`. If implementation reveals the spec was wrong, I surface this to the user and ask them to edit the spec + re-run `/create-plan`.
- I do not skip the review step. Even if the plan looks obvious, the second opinion catches things.
- I do not mark tasks `[DONE]` without user confirmation. Ever.
- I do not clear context mid-task. That's a post-completion action, user-initiated.

---

## Let's Start!

**Which feature slug?** (The folder under `features/`. If there's only one, I'll use it automatically.)

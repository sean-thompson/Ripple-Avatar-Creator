---
description: Generate PLAN.md for a feature from its SPEC.md, with tasks ordered by the spec's chosen build approach
allowed-tools: Bash(find, cat, grep, ls), Read, Write, Edit, Glob, Agent
model: sonnet
---

I'll generate an implementation plan for a feature from its `SPEC.md`. Output lands at `features/<slug>/PLAN.md`.

This is the middle step: `/create-spec` produced the spec, and `/next-task` will execute the plan. Run this once per feature. Re-run if the spec changes substantively — existing `[DONE]` markers are preserved where tasks match.

## Reference Files

The planning sub-agent will read these, in this order, before touching the plan:

1. `README.md` — architecture overview
2. `CONTROLLER_GUIDE.md`, `MODEL_GUIDE.md`, `VIEW_GUIDE.md`, `SERVICES_GUIDE.md`, `CONFIG_GUIDE.md` — MVC patterns
3. `BOLT_API.md` — networking library
4. `SLASH_COMMANDS.md` — what scaffolders exist so the plan can suggest them
5. `features/<slug>/SPEC.md` — the full spec

## Interactive Wizard

### Step 1: Slug

What feature are we planning? Provide the slug (the folder name under `features/`). If you ran `/create-spec` just now, it told you the slug at the end.

I'll verify `features/<slug>/SPEC.md` exists. If it doesn't, I'll stop and tell you to run `/create-spec` first.

### Step 2: Regeneration check

If `features/<slug>/PLAN.md` already exists, I'll ask whether to:
- **Regenerate** — re-run the planning agent; preserve `[DONE]` markers for tasks whose name/acceptance-criteria match
- **Abort** — leave the existing PLAN.md alone

### Step 3: Launch planning sub-agent

I'll launch a planning agent (`Agent` tool, `Plan` subagent type) with a self-contained brief that includes:
- The full architecture reading order above
- Explicit instruction to list and read every production source file under `Source/`
- The path to `features/<slug>/SPEC.md`
- The **build order** from the SPEC so tasks are ordered by the user's chosen approach, not defaulted to technical dependency
- Existing PLAN.md's `[DONE]` markers (if regenerating) so the agent preserves them

### Step 4: Write PLAN.md

The sub-agent writes `features/<slug>/PLAN.md` directly. I'll then summarise the tasks produced — count, first few task names, the ordering approach used — and confirm the file location.

---

## Implementation Details (Internal)

### Sub-agent brief template

The planning agent is `general-purpose` subagent. Brief structure (self-contained, since the sub-agent has no access to this conversation):

```
You are producing an implementation plan for the feature defined in
features/<slug>/SPEC.md. Output path: features/<slug>/PLAN.md.

## Architecture reading order (read in full before planning)

1. README.md
2. CONTROLLER_GUIDE.md
3. MODEL_GUIDE.md
4. VIEW_GUIDE.md
5. SERVICES_GUIDE.md
6. CONFIG_GUIDE.md
7. BOLT_API.md
8. SLASH_COMMANDS.md

## Codebase exploration (required)

List every directory and file under Source/. Read every production source
file (not Packages/). You need to understand:
- Existing Models — what's persisted, what scopes, how syncState is used
- Existing Controllers — validation patterns, ACTIONS table shape
- Network.luau — existing intents, states, actions
- Existing Views — observation patterns, CollectionService tags
- Existing Services — loop vs event-driven patterns
- Configs — what's already configurable

Never introduce a new pattern when an existing one covers the need.

## Entity replication strategy (Roblox-specific — decide for EVERY entity the feature adds)

This is a first-class planning decision, not an implementation detail. Getting it
wrong is expensive and hard to unwind later.

Key fact most Roblox tutorials/forums get wrong: **the server's Workspace is itself
replicated to every client automatically.** It is a SOURCE OF TRUTH you work WITH, not
against. Roblox's built-in replication of object position and motion is genuinely good —
especially for physics — PROVIDED you:
  (a) change/move the object in the SERVER Workspace (server-authoritative), and
  (b) set network ownership to the most relevant player so THAT player gets the
      lowest-latency feel.

Our MVC models are a SECOND, separate source of truth. They are the right tool for
logical/persistent state and for things that don't need exact position replication —
NOT for reproducing the motion of a physical object (that fights Roblox and causes lag
and teleporting).

For EACH entity the feature introduces, classify it and STATE the chosen strategy in the
plan (in the relevant task's notes):

- **Moving / position-critical / physics** (ball, projectile, vehicle, moving platform,
  sliding door): the SERVER moves the real Part in Workspace; network ownership is handed
  to the most relevant client (e.g. the receiver) for feel. Do NOT store its position in a
  model and reconstruct its motion in a client-side View — that re-implements replication
  Roblox already does, and produces lag/teleporting. This is the default for anything that
  moves continuously, and it is easy to get wrong by pattern-matching to a static entity.

- **Cosmetic / not position-critical** (particle effects, a trail of pets following a
  player, purely local feedback, decorative props): the model holds logical state and a
  client-side View (local script) renders/animates it per client. This IS the correct use
  of the model + View pattern — there is absolutely a right time for it.

- **Tradeoff case**: occasionally one client's low-latency FEEL matters more than the
  server holding authority. This is unusual. Do NOT decide it silently — flag it in the
  plan as an OPEN QUESTION for the user, explaining the options (server-authoritative +
  network ownership vs client-driven feel) and the tradeoff, because whoever runs this
  skill may not know Roblox's replication model.

Pattern-matching trap to avoid: this template's existing entities (e.g. Candles) are
STATIC — spawned, positioned once, then despawned — so they correctly use model + client
View. A continuously-moving object is a different problem; do not copy that pattern onto
it just because it's the only one in the codebase.

## The spec

Read features/<slug>/SPEC.md in full. Pay particular attention to:
- Integration points — what existing systems this touches
- Build order — the ordering approach you MUST use for tasks
- Success criteria — the plan must demonstrably reach these
- Design tensions & resolutions — respect decisions already made

## Preserved [DONE] markers (if regenerating)

<list of task names or IDs previously marked DONE; preserve if the
regenerated plan has matching tasks>

## What to produce

Write features/<slug>/PLAN.md with the following structure:

# <Feature Name> — Implementation Plan

## Build order
**Approach:** <from SPEC>
**Rationale:** <one line on why this ordering for this feature>

## Tasks

### Task 1: <Name>
- **Status:** [TODO] | [PARTIAL] | [DONE]
- **Why here:** <dependency rationale — what must exist first>
- **Depends on:** <earlier task numbers, or "none">
- **Refs:** <SPEC section numbers this task covers>
- **Acceptance criteria:**
  - <verifiable statement from the spec>
  - <...>
- **Associated UI:** <from the spec, if any>
- **Replication:** <only if this task adds an entity — one of: "server Workspace + network ownership" (moving/position-critical/physics) | "model + client View" (cosmetic / not position-critical) | "OPEN QUESTION: server-authority vs client feel — needs user decision">
- **Sub-tasks:**
  - [TODO] 1.1 <what to build / where — e.g. "Model: Source/ServerScriptService/models/user/CurrencyModel.luau — consider /create-model">
  - [TODO] 1.2 <...>

### Task 2: <Name>
<...>

## Rules the plan must follow

- Cover every acceptance criterion from SPEC.md. Nothing can be missed.
- Order tasks by the SPEC's build-order approach. If it's "vertical slice",
  the first task is a complete thin slice. If it's "5-loop inside-out",
  the first task is the dance layer. If "onboarding-first", the first task
  is the first five minutes. Etc.
- Sub-tasks describe WHAT to build and WHERE (file paths, module names),
  not HOW. Implementation details are decided at /next-task time by
  matching existing codebase patterns.
- Where a sub-task would scaffold a new component, explicitly suggest
  the relevant existing slash command — "/create-controller",
  "/create-model", "/create-view", "/create-service", "/create-config".
- Each task is self-contained enough to be implemented and verified
  before moving to the next.
- Sub-tasks get their own [DONE]/[PARTIAL]/[TODO] markers.
- For every entity the feature adds, classify it (moving/position-critical
  vs cosmetic) and state its replication strategy per "Entity replication
  strategy" above. Moving/physics objects are server-Workspace-authoritative
  with network ownership — NEVER a model + client-View reconstruction of motion.
  Surface any server-authority-vs-feel tradeoff to the user as an open question.
- Honour the SPEC's integration-point constraints as HARD requirements — if the
  SPEC says where an object lives or how it replicates (e.g. "lives in the server
  Workspace, network ownership to the receiver"), the plan must conform. Do not
  silently reinterpret a stated architecture into a different one.

This is a scope document, not a technical design. No pseudocode, no
function signatures, no line-by-line steps.
```

### Build-order → task-ordering translation

When the planning agent reads the SPEC's build order, it uses these heuristics:

- **Vertical slice** → first task is one complete end-to-end flow at minimum fidelity; subsequent tasks expand breadth or fidelity.
- **Core-loop first** → first task is the innermost loop (moment-to-moment); subsequent tasks wrap outward.
- **Lovell's Pyramid (base-up)** → tasks ordered by pyramid layer: core mechanic → progression → social → spend.
- **Onboarding-first** → first task is the first-five-minutes flow; subsequent tasks are expansion beyond that.
- **Risk-first** → first task is the highest-uncertainty element, even if not needed first in play.
- **Pillars-driven** → no fixed order, but every task's description names which pillars it serves.
- **5-loop (inside-out)** → tasks ordered dance → risk → mode → retention 1 → retention 2, with layers skippable or combined per the spec.

If the SPEC's build order is ambiguous or missing, default to **vertical slice** and note this in the PLAN's "Rationale" line.

### [DONE] preservation on regeneration

- Parse existing PLAN.md, extract task names and their statuses.
- In the new plan, mark any task `[DONE]` if a task with the same name (or same acceptance criteria set) was `[DONE]` before.
- For `[PARTIAL]`, preserve only if sub-task names match closely — otherwise demote to `[TODO]` and note in the plan.
- On ambiguity, flag to the user in the summary rather than silently deciding.

### Sub-agent returns text

The `Agent` tool returns a final text message. I'll use that summary to confirm to the user. The sub-agent writes the PLAN.md file directly — don't wait for the sub-agent's text and then write it ourselves.

### Failure handling

- If `features/<slug>/SPEC.md` doesn't exist: tell the user to run `/create-spec` first, stop.
- If the sub-agent fails or hits a limit: surface the error, don't retry silently.

---

## Let's Start!

**1. What's the feature slug?** (The folder name under `features/`. If you just ran `/create-spec`, use the slug it gave you.)

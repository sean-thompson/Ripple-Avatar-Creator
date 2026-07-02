---
description: Turn a game idea or brief into a structured SPEC.md through a design-framework-driven interview
allowed-tools: Bash(find, cat, grep, ls), Read, Write, Edit, Glob, WebFetch, AskUserQuestion
model: sonnet
---

I'll turn a game idea, a client brief, or a loose concept into a structured `SPEC.md` by interviewing you, applying your chosen game-design frameworks as evaluation lenses, and selecting a build order. Output lands at `features/<slug>/SPEC.md`.

This is the upstream step before `/create-plan` and `/next-task`. Run this once per new feature or game.

## Reference Files

Before writing the spec I may consult, depending on the project shape:

- `README.md` — project overview and architecture at a glance
- `CONTROLLER_GUIDE.md`, `MODEL_GUIDE.md`, `VIEW_GUIDE.md`, `SERVICES_GUIDE.md`, `CONFIG_GUIDE.md` — MVC patterns for integration-point analysis
- `BOLT_API.md` — networking library
- Any file the user points me at via argument (e.g. `/create-spec Refs/client-brief.md`)

## Project architecture context (background for me, not user-facing)

This is an MVC-based Roblox game template. New games express gameplay by adding to it, not changing it — so when discussing integration points I frame in *what to add*, not in plumbing. New games add **Models** (server-authoritative state in five auto-registered scopes — `User` per-player persistent, `UserSession` per-player ephemeral, `Server` shared ephemeral, `UserEntity` per-player persistent multiple-instance, `ServerEntity` shared ephemeral multiple-instance), **Controllers** (validate player intents and update models; ACTIONS table dispatches `Network.Actions.*` constants to handlers), **Views** (client-side, mount on CollectionService-tagged Studio instances, observe `Network.State.*` and send `Network.Intent.*`), **Services** (background tasks, loop or event-driven), and **Configs** (static tunable data; types synced via Rojo, data module created in Studio). All networking flows through `Network.luau` over Bolt. Persistence is built into Models with persistent scopes — a model's `syncState()` queues a DataStore write *and* broadcasts new state to clients in a single call, so games almost never talk to `PersistenceService` directly. An analytics pipeline ships events to BigQuery. The architecture itself is stable; integration questions for a new game are about *which scoped models, which controller actions, which views* — not about persistence/network plumbing, which is handled.

## Argument

- **Optional:** a path to a brief/doc, or a URL. If provided, I read it first and summarise back before asking follow-ups. If absent, I start in interview mode.

## Flow (Six Phases)

### Phase 1: Intake

**Step 0 — references check.** Before anything else, I ask whether you have any documents or images that would help me understand the idea — a brief, mood-board screenshots, reference videos, sketches, prior notes, anything. Three ways to share them:
- **Drop them directly in the chat** (images, pasted text)
- **Link to them** (URLs, or a path to a file in the project)
- **Place them in `refs/`** in the project folder — that path is `.gitignore`-d so client/private material won't get committed — and tell me they're there

I read whatever you provide before moving on. If there's nothing, we go straight to the pitch.

**Step 1 — pitch & framing.**

**If a brief/doc is in scope** (via argument or via the references step above), I read it, summarise what I understood back to you in 3–5 bullets, and ask focused follow-ups on anything ambiguous or unstated.

**If no brief**, I interview you open-ended:
- What's the idea? Give me the pitch in one or two sentences.
- Who is it for? (Age, platform familiarity, session length expectations)
- What's the feeling you want the player to walk away with?
- Any reference games — "it's like X meets Y"?
- Is this a net-new game, a feature inside an existing game, or a prototype?

I keep this phase loose and conversational — no checklist pressure.

### Phase 2: Margins

Before touching design frameworks I pin down the practical margins:

- **Success criteria** — when will you know this was worth building? (Retention, conversion, a fun-test going well, shipping at all, a client signing off)
- **Non-goals** — what are we explicitly NOT doing?
- **Integration points** — does this interact with existing Models/Controllers/persistence/currency/analytics in the project? What's the hook?
- **Moving objects & replication** — does the game have any object whose **position/motion must look right on every client** (a ball, projectile, vehicle, moving platform)? If so, record that it is **server-Workspace-authoritative with network ownership to the most relevant player** — NOT a model whose position is rebuilt by a client view. (Roblox replicates the server Workspace for free and does it well when you move the object server-side + assign network ownership; reproducing motion through models fights that and causes lag/teleporting.) Purely cosmetic things (particles, trailing pets, local feedback) are the opposite — model + client view. If low-latency feel for one client might matter more than server authority, flag it as a decision for later. Capture the chosen strategy per object so the plan can't silently reinterpret it.
- **Known unknowns** — things you already know you're unsure about

I ask these one or two at a time, not as a drill.

### Phase 3: Evaluation framework selection

I offer a list of game-design frameworks you can apply as evaluation lenses. You pick one or more (multiple is fine — design frameworks are models, all have limits, worth testing against more than one when the design has unusual dimensions). I'll suggest defaults based on the shape of the game.

Use `AskUserQuestion` with `multiSelect: true`:

- **MDA** (Mechanics / Dynamics / Aesthetics — Hunicke, LeBlanc, Zubek). Academic default. Tests whether mechanics produce the dynamics that produce the intended feeling.
- **Schell's Elemental Tetrad** — aesthetics / story / mechanics / technology balance. Good at catching "we've over-indexed on X, starved Y."
- **Koster's Theory of Fun** — fun as the process of mastering novel patterns. Tests learning curve and exhaustion point.
- **Flow channel** (Csíkszentmihályi) — challenge vs. skill over time. Tests whether difficulty scales keep players in flow.
- **Self-Determination Theory / PENS** (Rigby & Ryan) — competence / autonomy / relatedness. Strong for live-service and social games.
- **Bartle player types / Quantic Foundry motivations** — who is this game *for*, does the design serve them.
- **Lovell's Pyramid** (as eval lens) — is each layer present? Is spend well-motivated by progression?
- **5-loop model** (in-house) — five concentric loops: **dance** (moment-to-moment input feel and rhythm), **risk** (per-encounter stakes and consequence), **mode** (the formal structure of play — what a rulebook for the game would contain), **retention 1** (day-over-day reasons to return), **retention 2** (long-arc identity and loyalty). Tests whether each loop is present, coherent, and interlocking.

Suggested defaults:
- Single-session competitive → **MDA + Flow**
- Live-service / retention-heavy → **SDT + Lovell + 5-loop**
- Narrative-driven → **Schell's Tetrad + Koster**
- Unsure / prototype → **MDA + 5-loop** (safe two-angle starter)

### Phase 4: Framework pass

For each selected framework, I run it independently and summarise findings in plain terms. Then I diff the findings:

- **Agreement** — where frameworks converge, I note it briefly.
- **Tension** — where frameworks conflict, I surface the conflict, propose a resolution with reasoning, and name which framework I'm leaning toward and why.
- **Escalation** — if my confidence on a resolution is low, I stop and ask you to make the call. I frame this as "Framework A says X, Framework B says Y, here's my read but it's your call" — never as "I can't decide, help."

Resolutions get written into the SPEC under "Design tensions & resolutions" so the reasoning survives into implementation.

### Phase 5: Build-order selection

Now that we know what the thing is, I ask how you want to sequence construction. Offer via `AskUserQuestion`:

- **Vertical slice** — one complete end-to-end cut, then expand. "Does this feel good when assembled?"
- **Core-loop first** — dance/risk innermost loop before anything wraps it.
- **Lovell's Pyramid (base-up)** — core mechanic → progression → social/meta → spend.
- **Onboarding-first / "first five minutes"** — build the new-player experience first. Strong for Roblox where early drop-off is brutal.
- **Risk-first / de-risk hardest problem** — tackle the highest-uncertainty element first.
- **Pillars-driven** — define 3–5 design pillars, filter every decision through them. More cross-cutting discipline than sequence.
- **5-loop (inside-out)** — dance → risk → mode → retention 1 → retention 2, layers skippable or combinable.

I suggest a default based on game shape. If the user selected the 5-loop framework in Phase 3, I lean toward the 5-loop build order too, but it's not automatic.

### Phase 6: Confirm and write

I summarise the spec back to you (title, pitch, frameworks applied, build order, first-playable description, biggest risks). Then I offer **3–5 slug candidates** — kebab-case, used as the folder name under `features/` — covering a few different angles (the central mechanic, the differentiating gimmick, a generic vibe word). I nominate **one as the default** and tell you I'll use it unless you pick a different option or supply your own. If you say nothing about the slug, I go with the default rather than blocking on confirmation.

Then write `features/<slug>/SPEC.md` with this structure:

```markdown
# <Game / Feature Name>

## Overview
<one-paragraph pitch>

## Success criteria
<from Phase 2>

## Non-goals & constraints
<from Phase 2>

## Integration points
<existing Models/Controllers/Network entries this touches — empty if net-new>

### Replication strategy (per object)
<for each notable object, state its source of truth so the plan can't drift:
 - moving / position-critical / physics → "server Workspace, network ownership to <whom>"
 - cosmetic / not position-critical → "model + client view"
 - undecided server-authority-vs-feel tradeoff → flag as an open decision
 Omit only if the feature has no world objects at all.>

## Design frameworks applied

### <Framework name>
<findings>

### <Other framework>
<findings>

## Design tensions & resolutions
<where frameworks disagreed + how it was resolved + who decided>

## Build order
**Approach:** <selected build-order name>

**First-playable slice:** <description of what we're building first and what it proves>

**Subsequent layers:** <short ordered list>

## Risks & open questions
<things we already know we don't know>

## Provenance
- Source brief: <path or "interview only">
- Interviewed: <date>
- Frameworks selected: <list>
- Build order: <selection>
```

Confirm the file was written and tell the user the next step is `/create-plan` to produce the task-ordered `PLAN.md`.

---

## Implementation Details (Internal)

### Argument handling

- If `$ARGUMENTS` is a file path that exists: `Read` it, use it as the brief.
- If `$ARGUMENTS` looks like a URL: `WebFetch` it, use the content as the brief.
- If `$ARGUMENTS` is empty or unresolvable: interview mode. Do NOT error on missing arg.

### Framework pass — depth guidance

- For each selected framework, produce **3–6 findings**, not an essay. Pithy beats exhaustive.
- Each finding should be actionable — either affirms a design choice or flags a concern with "what to change" implied.
- If a framework has nothing useful to say about this specific game, say so explicitly rather than padding. E.g., "Flow channel doesn't bite on a turn-based single-decision game — skipping."

### Framework conflict resolution — decision pattern

1. Name the conflict concretely: "MDA says X → Y → Z feeling; SDT says the reward cadence undermines autonomy."
2. Note what's at stake: which framework's finding, if wrong, costs more to discover late?
3. Propose a resolution: "I'd lean MDA here because 'tense urgency' is the named aesthetic and autonomy can be preserved by keeping choice-density high between rewards."
4. Self-assess confidence: if anything below "reasonably sure", escalate with `AskUserQuestion`.
5. Write the decision and reasoning into the SPEC's "Design tensions & resolutions" section.

### Slug generation

- Offer **3–5 kebab-case candidates**, 2–4 words each. Cover different angles where the game shape supports it (mechanic-focused, gimmick-focused, generic vibe).
- Strip articles and filler ("the", "a", "game").
- Nominate one candidate as **my favourite and the default** — bias toward the slug that captures the clearest differentiator without over-claiming a finalised game name. Tell the user I'll use the default unless they say otherwise.
- Don't block on confirmation. If the user doesn't push back on the default, proceed with it.
- Verify `features/<slug>/` doesn't already exist. If it does, ask whether to overwrite SPEC.md or pick a different slug.

### SPEC.md file creation

- If `features/` doesn't exist, create it. If `features/<slug>/` doesn't exist, create it.
- Write the SPEC.md in full — no placeholders except where the user deferred a decision.
- After writing, show the user the file path and a one-line summary of what's inside.

### Interview style

- Ask 1–2 questions at a time, not a firehose.
- Let the user wander — if they mention something off-brief that's interesting, follow it.
- Push back gently if the pitch is vague. Ask for concrete examples, reference games, or a specific moment of play.
- Mirror terminology the user uses, don't impose jargon.

### What I do NOT do

- I do not estimate effort, hours, days, or any other budget. AI training is calibrated on human-pace work; with these tools the same job is much faster, so my numbers would be misleading. Budget calls are yours.
- I do not design the UI. That's a plan-time concern.
- I do not pick tech. That's a plan-time concern.
- I do not write task lists. `/create-plan` does that.

---

## Let's Start!

If a brief or doc path was passed as an argument, I'll read it now and come back with what I understood.

Otherwise, **before we get into the pitch — any documents, images, or reference material I should look at first?**

- Drop them in the chat (images, pasted text)
- Link to them (URLs, or a path inside the project)
- Place them in `refs/` in the project folder (gitignored, so safe for client/private material) and tell me they're there
- Or just say "no, let's go" and I'll open with the pitch question

# CLAUDE.md

Guidance for Claude Code when working in this repository. This is **Ripple Avatar
Creator** — our take on Roblox's Catalog Avatar Creator, with a points/UGC-auction
economy, item recommendations from an external service, and diegetic "monolith"
interactables in place of a crowded HUD. **Read `docs/PROJECT_BRIEF.md` for the
vision and workstreams**; per-feature specs and plans live in `features/<slug>/`.

It's built on Dubit's MVC-based Roblox template (Rojo-synced Luau). For depth, see
`README.md` and the per-layer guides in `docs/` (MODEL, CONTROLLER, VIEW, SERVICES,
CONFIG, BOLT_API), and the scaffolding skills in `.claude/commands/`. Each feature
has a `SPEC.md` and a task-ordered `PLAN.md` in `features/<slug>/`; work it task
by task with `/next-task`.

## Conventions

### Finding instances & requiring modules — default to `WaitForChild`

Reach for `parent:WaitForChild("X")` for any instance or module you expect to
exist. Prefer it over direct indexing (`parent.X`) and over `FindFirstChild`.

- **Why:** startup and replication order are not guaranteed. `WaitForChild`
  tolerates that ordering, and if the thing is *genuinely* missing it surfaces a
  loud "Infinite yield possible" warning that points at the real problem —
  whereas `FindFirstChild` silently returns `nil` (a bug that detonates later,
  far from the cause) and direct indexing throws intermittently depending on
  timing.

- **Required on the client and in `ReplicatedFirst`, and for anything reading
  `ReplicatedStorage` from the client.** `ReplicatedStorage` replicates to the
  client in an unguaranteed order, so `ReplicatedStorage.Foo` throws an
  intermittent *"Foo is not a valid member of ReplicatedStorage"* when `Foo`
  hasn't replicated yet. (This exact class of bug hit us: `ReplicatedFirst` →
  `require(...Network)` → `Network` indexed `script.Parent.Bolt` directly and
  failed on startup. Fixed by `WaitForChild`.)

- **Also use it for Studio-authored instances** — Configs under
  `ReplicatedStorage`/`ServerScriptService`, and tagged Workspace hierarchy —
  since they may not exist at the moment Rojo-synced code first runs.

- **Server-side requires of Rojo-synced modules** (e.g. a controller requiring
  `script.Parent.AbstractController`) are safe with direct indexing, because the
  server's DataModel is fully built before any server script runs. Existing
  server code uses direct indexing and that's fine; `WaitForChild` is a
  harmless, consistent default if you prefer it. Don't churn existing server
  requires just to convert them.

- **`FindFirstChild` is for genuinely optional / dynamic instances only** —
  something whose absence is a valid state you explicitly branch on (the classic
  case is `character:FindFirstChild("Humanoid")` during respawn, or an optional
  child you handle when `nil`). It should be rare. Never use it for something you
  expect to be there.

## See also

- `README.md` — architecture overview and setup.
- `docs/*_GUIDE.md` — per-layer patterns (models, controllers, views, services, configs).
- `.claude/commands/` — scaffolding skills (`/create-model`, `/create-controller`, etc.).

---
description: List all available Claude slash commands for this project
---

This project includes several slash commands to scaffold code quickly. Here's an overview of what's available:

---

## Scaffolding Commands

### `/create-model`

Scaffolds a server-side `AbstractModel` file.

- **Location:** `Source/ServerScriptService/models/<scope>/`
- **Wizard covers:** Model name, scope, properties, and methods
- **Scopes:**
  - `User` — per-player, persistent (e.g. InventoryModel)
  - `UserSession` — per-player, ephemeral/session-only (e.g. ManaModel)
  - `Server` — shared across all players, ephemeral (e.g. ShrineModel)
  - `UserEntity` — per-player, persistent, multiple instances (e.g. PetModel)
  - `ServerEntity` — shared, ephemeral, multiple instances; predefined or dynamic variants (e.g. DrawbridgeModel, CandlesModel)
- Also updates `Network.luau` with state definition and type export.

---

### `/create-controller`

Scaffolds a server-side `AbstractController` file.

- **Location:** `Source/ServerScriptService/controllers/`
- **Wizard covers:** Controller name, actions, model interactions, validation strategy, and Network.luau wiring
- **Pattern:** ACTIONS lookup table maps `Network.Actions.*` constants to handler functions
- Also updates `Network.luau` with controller config and action type export.

---

### `/create-service`

Scaffolds a server-side service for background tasks.

- **Location:** `Source/ServerScriptService/services/game/`
- **Wizard covers:** Service name and pattern selection
- **Patterns:**
  - `Loop-based` — runs on a timer (e.g. cleanup, regeneration)
  - `Event-driven` — reacts to system events (e.g. PlayerAdded, PlayerRemoving)
- Auto-discovered by ServiceRunner via `init()` function — no registration needed.

---

### `/create-view`

Scaffolds a client-side `AbstractView` file.

- **Location:** `Source/ReplicatedFirst/views/`
- **Wizard covers:** View name, CollectionService tag, instance type, user actions, state observation, and immediate feedback
- **Patterns** (auto-detected from your answers):
  - `A` — pure client-side feedback (particles, sounds, animations)
  - `B` — intent-based (sends actions to a controller via `Network.Intent.*`)
  - `C` — state observation (observes model state via `Network.State.*`)
  - `B+C` — combination of B and C

---

### `/create-config`

Scaffolds a config types file under `ReplicatedStorage/Config/ConfigTypes/`.

- **Location:** `Source/ReplicatedStorage/Config/ConfigTypes/`
- **Wizard covers:** Config name, description, properties, and example data
- **Pattern:** Two-part — a types file (synced via Rojo) paired with a data module created manually in Studio
- Outputs the config module code to paste directly into Studio.

---

## Maintenance Note

If you add a new command to `.claude/commands/`, update this file to document it.

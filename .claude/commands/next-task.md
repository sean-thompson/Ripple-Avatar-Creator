---
description: Work the next task in a feature's PLAN.md — build it, verify it in Studio, hand back for testing, mark it done once confirmed
---

Work the next task from `features/<slug>/PLAN.md`. Argument: the feature slug (optional if only one `features/*/` folder exists — otherwise ask).

1. **Reconcile first (only if this conversation already holds work on the feature).** Compare PLAN.md with what actually happened: status drift, decisions or hard-won lessons worth an **Outcome** note, scope changes, deferred follow-ups. Propose the edits and wait for a yes — never rewrite the plan silently.

2. **Pick the task.** The first `### Task N` whose status isn't `[DONE]`. Say which task it is and show its acceptance criteria. If every task is done, say so and stop.

3. **Understand it.** Read the task, the SPEC sections it references, the relevant `docs/*_GUIDE.md`, and the code it touches. If one of PLAN.md's open questions belongs to this task, get the user's call before building. For anything non-trivial, outline the approach in a few lines and get a nod (use plan mode for big ones).

4. **Build it** on a branch off `development` (e.g. `feature/<slug>-t<N>-<short-name>`), following `CLAUDE.md` and the guides. Scaffold with `/create-model`, `/create-controller`, `/create-service`, `/create-config`, `/create-view`; translate designs with `/html-to-react-luau`. Honour the task's **Replication** line.

5. **Verify it yourself where you can.** With Roblox Studio MCP connected and `rojo serve` running: play, check the console for errors and warnings, screen-capture, drive the UI with mouse input, read state with `execute_luau`. Leave `rojo serve` running — stopping it disconnects the user's Studio plugin and they have to reconnect. If it crashes (it can when a branch switch or deletion removes a folder it's watching), restart it and say so. Say plainly what you verified and what you didn't.

6. **Hand back** with: what changed (one line per file), how to test it, what they should see, what to watch for.

7. **Fix what they report** until they confirm it works. Never mark a task done without that confirmation.

8. **Close it out.** Mark the task and its finished sub-tasks `[DONE]`, add an **Outcome** note (decisions made, lessons learned the hard way), and commit. Merge into `development` and push when the user asks.

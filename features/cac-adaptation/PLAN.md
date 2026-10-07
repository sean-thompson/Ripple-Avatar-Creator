# Phase 1 — Catalog Avatar Creator adaptation — Implementation Plan

## Build order

**Approach:** feel-first, top-down (custom). Get the skin, motion and sound right before the heavy technical lifts. The first task is the first-playable slice (HUD shell in the final skin, full panel with tabs/breadcrumbs on placeholder content, toasts, buy-prompt frame, springs/tweens and UI sounds, and the relative-vs-absolute sizing decision). Then the layers in the SPEC's order: World options, Avatar core, Catalogue, Basket and buying, Outfits, Sharing, Community outfits, Stores. Large layers are split into several tasks; the layer order is never broken.

**Rationale:** the design is settled and the riskiest things to get wrong late are look, feel and sizing across iPad/desktop/phone. Proving those first means every later layer (data, APIs, cross-server storage) plugs into a UI that already feels right, and the unresolved technical risks (catalogue limits, cross-server data, deep links, store model) each get an explicit investigation sub-task at the top of the task that depends on them rather than being assumed.

**Cross-cutting rules applied to every task**
- Template architecture only: Models / Controllers / Views / Services / Configs per `docs/*_GUIDE.md`. New intents/states are added to `Source/ReplicatedStorage/Network.luau` (NetworkConfig plus type exports) before the controller/model/view that use them. No new pattern where an existing one fits.
- HUD state flows through `HudApp` (`useBoltState` subscriptions, props/callbacks down, no BindableEvents). Navigation/UI-only state (open panel, tab, breadcrumb stack, toasts, buy prompt) is React state in `HudApp`, the same way `activeModal` is today.
- HUD tasks translate the design with `/html-to-react-luau` (structure and styling), then wire state with `/create-view`. Each HUD sub-task names the design frame it implements. Visual divergences from the design (for example glass blur, which Roblox UI cannot do) are listed explicitly, never silent.
- Slash commands are auto-discovered from model methods and controller actions, so testing hooks need no extra work beyond naming methods well.
- Config modules are Studio-created (types under `Source/ReplicatedStorage/Config/ConfigTypes/` via `/create-config`); each task that adds one includes the Studio step.
- Instances found with `WaitForChild` (CLAUDE.md convention); `FindFirstChild` only for genuinely optional ones.
- Controller handlers validate everything from the client (item ids against the catalogue, list sizes, rate limits) and follow the ACTIONS-table / `dispatchAction` shape of the existing controllers. Analytics for controller actions is automatic; custom events use `AnalyticsService:trackEvent` as each task lands.
- Each task ends with a Play-mode playtest on desktop and a touch device emulation (iPad and phone) before the next task starts.

---

## Tasks

### Task 1: Skin foundation and sizing decision
- **Status:** [DONE]
- **Why here:** The whole spec is judged on feel. Tokens, fonts, icons and the base component kit must exist before any screen is built, and the sizing decision (relative vs absolute) changes how every later component is authored, so it is made first, on real devices.
- **Depends on:** none
- **Refs:** Constraints (Template architecture, Devices); Build order (first-playable slice: final skin, "settles the sizing approach"); Risks (Sizing: relative vs absolute); Success criteria (It feels good)
- **Acceptance criteria:**
  - A throwaway component gallery in the final skin (glossy black/orange split-gradient pills, Nunito 600-900, icons, glass panels, hover glow, 0.94 press scale) renders correctly on desktop, iPad and phone emulation.
  - The sizing approach is decided and recorded (relative scale + `useViewportScale`, or authoring at 1180x820 under one UIScale), with evidence from all three device classes, including how Roblox-native fixed-size UI (top bar) coexists.
  - Fonts and icons render with no placeholder glyphs; any divergence from the design is listed.
- **Associated UI:** Design tokens and chrome across all frames (5a to 5h); pills (tabs, Basket, Create avatar, Save to Roblox, Reset), glass panels, badges.
- **Sub-tasks:**
  - [DONE] 1.1 Investigate and decide font and icon delivery. Nunito is available as a Roblox font family (evaluate `FontFace` weights 600-900); Material Symbols Rounded is not a Roblox font, so evaluate a white-fill PNG sprite sheet or per-icon images tinted with `ImageColor3` (per the skill's Phase 3 asset flow). Produce the upload checklist for the icons the design uses (apparel, storefront, checkroom, shopping cart variants, flight, restart_alt, cloud_upload, person_add, etc.). Record as an open question for sign-off.
  - [DONE] 1.2 Create a shared design-tokens module under `Source/ReplicatedFirst/views/` (colours incl. the BK and OR gradient stops, radii, strokes, type scale, spring presets, glow/press values) so no screen holds magic numbers. Follow the skill's guidance to centralise repeated values.
  - [DONE] 1.3 Build the base skin components in `Source/ReplicatedFirst/views/components/` with `/html-to-react-luau`, reusing the template hooks: glossy pill button (reshaping `HudButton`; black default, orange active, hover glow, 0.94 press scale via `useSpring`), icon component, glass panel (translucent fill + stroke), badge, text tab (underline active), chip. `UIGradient` on white-BG frames (skill pitfall 1).
  - [DONE] 1.4 Decide how "glass" is rendered, since UI blur is unsupported: translucent fill only, or evaluate a client-side Lighting `BlurEffect`/`DepthOfField` while the full panel is open. List the divergence either way (open question).
  - [DONE] 1.5 Sizing spike: author the gallery both ways (per-element `UDim2.fromScale` + `useViewportScale`; and a 1180x820 canvas under one `UIScale` per the skill's Pattern 2), test on desktop, iPad and phone emulation (including narrow-aspect and notch/safe-area cases), pick one per ScreenGui root, record the decision and reasons in the open questions section and in `docs/VIEW_GUIDE.md` "Responsive Scaling".
  - [DONE] 1.6 Reserve the top-left system-bar area per device (design shows a 160x36 placeholder) and verify nothing overlaps Roblox's native top bar on any device.
  - [DONE] 1.7 Playtest checkpoint: gallery open on three device classes; sign-off on look before the shell is built.
- **Outcome:**
  > Sizing: `fill` (design px under one UIScale, canvas stretched to the screen's aspect) scaled by viewport **height**. Glass: **blur** (scene blur behind full-screen panels, design alphas). Icons: one 128px white PNG per Material Symbols glyph (IDs in `SkinAssets`). Learned the hard way: React clears its container's children on first render (never `createRoot(PlayerGui)`); `AutomaticSize` text mis-sizes under the canvas UIScale (use `useTextWidth`); a text shadow must be a lower-ZIndex sibling, not a child; clamp spring alphas used for glow/hover (overshoot flashes). The gallery's control strip was dropped; `HudApp` now mounts the gallery HUD mock as the interim HUD (pulled forward from Task 2), and the template HUD is no longer mounted.

### Task 2: HUD shell and full-panel frame (placeholder content)
- **Status:** [TODO]
- **Why here:** First half of the first-playable slice. The shell and panel frame are the container every later screen lives in; building them on placeholder content proves tabs, breadcrumbs and open/close without any backend.
- **Depends on:** 1
- **Refs:** Scope > HUD (world view); Scope > Full panel (shared frame); Integration points (HudApp / HUD components replaced); Success criteria (fewer clicks, nothing hidden; state stays small)
- **Acceptance criteria:**
  - World HUD shows: three pill tabs top centre (Catalogue, Stores, Outfits); bottom-left a large Basket button with a Robux-total badge plus Create avatar, Save to Roblox, Reset; bottom-right World options toggle; reserved top-left space.
  - Each tab opens the full panel on that tab; switching tabs inside the panel works; close returns to the world.
  - Breadcrumbs and back appear once navigation goes deeper than a tab (for example Outfits > X > Y) and each crumb pops to that level.
  - The panel left column shows an avatar-preview placeholder with Undo, a "Wearing - N" bar (opens Wearing) and a Basket card with count and CTA; Basket and Wearing open as list screens.
  - Wearing and basket state appear as badges/counts only, no always-on panels.
  - The template StatusBar, Favours and Candles HUD are gone and `HudApp` no longer reads Inventory/Favours state.
- **Associated UI:** 5a HUD; full-panel frame of 5b, 5f, 5g (left column, tabs, breadcrumb bar); World options toggle (side panel opens in Task 4).
- **Replication:** UI-only state (open panel, tab, breadcrumb stack). No world entity. Client React state in `HudApp`; nothing replicated.
- **Sub-tasks:**
  - [TODO] 2.1 Rewrite `Source/ReplicatedFirst/views/HudApp.client.luau`: world HUD, full-panel host, navigation state (tab + breadcrumb stack, push/pop/popTo, close). Mount into its own ScreenGui inside a `SkinRoot` — NOT `createRoot(PlayerGui)`: React clears its container's children on first render, which deleted other ScreenGuis in Task 1. Consider a navigation hook in `views/hooks/`. Use `/create-view`.
  - [TODO] 2.2 World HUD view (`/html-to-react-luau`, frame 5a): tab pills, Basket button with badge, action pills, World options toggle, system-bar reservation. Placeholder badge value from local state until Task 10.
  - [TODO] 2.3 Full-panel frame component (`/html-to-react-luau`, frames 5b/5f/5g chrome): left column (preview placeholder, Undo, Wearing bar, Basket card), right content area, breadcrumb/back row, close. Reuse `useTransition`/`AnimatedModal` shape; reshape `ModalWindow` rather than adding a parallel frame.
  - [TODO] 2.4 Placeholder screens for Catalogue, Stores, Outfits, Basket, Wearing and one deeper level per tab to exercise breadcrumbs.
  - [TODO] 2.5 Remove the template HUD examples in this task: `StatusBarView.luau`, `FavoursView.luau`, `CandlesView.luau`, `components/FavourTile.luau`, `components/HudButton.luau` (superseded by `PillButton` in Task 1), the Task 1 `views/gallery/` folder, and `CurrencyChip.luau` unless reshaped into the Robux/count chip; strip the Favours/Candles configs from `AnimatedModal`. Update `docs/VIEW_GUIDE.md` (HUD file structure, Props/Modal examples, StatusBarView example), `README.md` (view examples), `.claude/commands/create-view.md` and `.claude/commands/html-to-react-luau.md` references to point at the new shell components.
  - [TODO] 2.6 Playtest checkpoint on desktop, iPad and phone emulation: every tab, breadcrumb depth, close, and no overlap with the Roblox top bar.

### Task 3: Motion, sound, toasts and buy-prompt frame
- **Status:** [TODO]
- **Why here:** Second half of the first-playable slice. Motion and sound are the product's differentiator and are tuned on placeholder content before real data makes iteration slower. Completes the slice, so this task ends with a feel review.
- **Depends on:** 2
- **Refs:** Scope > HUD (toasts); Scope > Buy prompt; Success criteria (It feels good, State stays small); Risks (Sound direction)
- **Acceptance criteria:**
  - Every open/close, tab change, breadcrumb pop, press, toast and badge change has considered motion (springs/tweens via the template hooks) and, where it helps, a UI sound.
  - Toasts appear, stack/replace sensibly and dismiss (about 1.8 s in the prototype) with entrance/exit motion; a toast queue copes with rapid repeat actions.
  - The buy-prompt frame (single item or bundle total, Free state) opens and closes with motion and has the Roblox hand-off slot, without faking a Roblox purchase UI.
  - Basket badge and count changes animate (number roll via `useSpringNumber`).
  - Motion never reads as clutter and holds frame rate on a phone emulation.
- **Associated UI:** Toast (bottom-centre in the frames), buy prompt (`buyOpen` in 5b/5f/5d), panel/tab/badge transitions across 5a to 5h.
- **Replication:** UI-only; client sounds are local. No world entity.
- **Sub-tasks:**
  - [TODO] 3.1 Decide sound direction and asset source (open question): style, whether assets are authored, bought or generated, and licence. List the sound slots needed (tab, open, close, press, toast, add to basket, try on/take off, purchase success, error). Studio step: create the Sound instances/assets under SoundService.
  - [TODO] 3.2 Add a small client UI-sound helper in `views/hooks/` (a `useSound`-style hook alongside the existing hooks) so components trigger sounds declaratively; honour volume/mute. Use `/create-view`.
  - [TODO] 3.3 Toast host and queue component (`/html-to-react-luau`), driven by `HudApp` React state, with a `showToast` callback passed down; spring in/out.
  - [TODO] 3.4 Buy-prompt frame component (`/html-to-react-luau`): title, text, price or Free, tint swatch, Cancel/Confirm, with the confirm callback left as a stub for Task 11.
  - [TODO] 3.5 Motion pass over the shell from Task 2 using `useSpring`, `useTransition`, `useSpringNumber`, `useDrag` where it fits; record the spring presets in the tokens module; add the press/hover states to every interactive component.
  - [TODO] 3.6 Feel review and playtest on three device classes. Tune; capture phone-tightness issues for later tasks.

### Task 4: World options (client rendering, persistence) and double-jump flight
- **Status:** [TODO]
- **Why here:** First layer in the SPEC order. It is the lowest-risk real feature: one persisted per-player model, purely client rendering, and it exercises the whole intent / model / state / view loop and the persistence round trip for the first time.
- **Depends on:** 2, 3
- **Refs:** Scope > World options (side panel); Replication strategy (World options; Flight); Integration points (persistent user state: World options preferences); Risks (Flight in a shared world)
- **Acceptance criteria:**
  - World options panel opens from the bottom-right toggle: time of day 0-24 h slider, sky preset (Clear / Clouds / Studio / Void), floor colour (5 swatches), floor pattern (Grid / Checker / Plain), brightness 50-150 %, shadows toggle, and the hint "Double-jump to fly. Use it to find a quiet spot."
  - Time of day drives sky colour, sun/moon position and stars; changes apply instantly while dragging.
  - Settings are private: another player in the same server does not see your sky, floor, brightness or shadows.
  - Settings persist per player and are restored on rejoin.
  - Double-jump makes the player's own character fly using normal Roblox client-owned movement.
- **Associated UI:** World options panel (frame 5a side panel / `worldOpen`); sky, floor, orb, stars and haze behaviour in `logic.js` `renderVals`.
- **Replication:**
  - World options: **cosmetic / not position-critical**. The `WorldOptionsModel` holds the saved preference (logical, persisted). Each client renders its own sky/lighting/floor locally (Lighting and local changes to a tagged floor part are not replicated, so they are private by construction). No server Workspace change.
  - Flight: **moving / position-critical**. It is the player's own character; physics stays client-owned (default network ownership of the player's character). The server holds no flight model and reconstructs nothing. Do not mirror flight state into a model.
- **Sub-tasks:**
  - [TODO] 4.1 Config: world options ranges, presets, floor swatches, pattern list, flight tuning (speed, double-jump window). Use `/create-config`, then create the Studio config module.
  - [TODO] 4.2 Network: add a `WorldOptions` controller (actions such as SetOptions/Reset, validated ranges and enums) and a `WorldOptions` state in `Network.luau`.
  - [TODO] 4.3 Model: `Source/ServerScriptService/models/user/WorldOptionsModel.luau` (User scope; persisted via `syncState`). Use `/create-model`. Note PersistenceService debounces writes, but the view should still commit on release, not per drag tick.
  - [TODO] 4.4 Controller: `Source/ServerScriptService/controllers/WorldOptionsController.luau` with validation and ACTIONS table. Use `/create-controller`.
  - [TODO] 4.5 View, panel: World options side panel (`/html-to-react-luau`) with sliders, swatches, segmented pills, switch; local draft state applies immediately, intent fires on release/selection; observes the saved state on join.
  - [TODO] 4.6 View, world renderer: a client renderer that applies the options to Lighting (ClockTime/brightness/shadows, sky objects and presets), sun/moon/stars equivalent, and the floor (colour and pattern). The floor is a Studio-authored, CollectionService-tagged part; per the skill, mount the renderer from `HudApp` as an effect on props (no BindableEvent bridge), or as a tagged-instance workspace view if no HUD coupling is needed. Studio step: tag the floor part, add Sky/atmosphere instances.
  - [TODO] 4.7 Flight: client double-jump flight view (`.client.luau`, `/create-view`, Pattern A) using Humanoid state/jump request; configurable via 4.1. No server component.
  - [TODO] 4.8 Open question handling: flight in a shared world (collisions, griefing, "quiet spots" depend on world layout, which is not designed). Implement flight with the simplest safe defaults (no player collision change, config switch to disable) and flag the layout dependency.
  - [TODO] 4.9 Analytics: world-options changes tracked via controller auto-instrumentation; confirm they show in GA4 debug.
  - [TODO] 4.10 Playtest: two clients, change settings on one, confirm the other is unaffected; rejoin to confirm persistence; fly on touch device.

### Task 5: Avatar core, server-side try-on
- **Status:** [TODO]
- **Why here:** Everything after this (catalogue, basket, outfits) calls "try on". It must exist as a validated, server-authoritative service with slot rules and Undo before any UI browsing depends on it.
- **Depends on:** 3, 4
- **Refs:** Scope > Catalogue (wearing rules); Scope > Full panel (Undo); Scope > HUD (Reset); Replication strategy (Player avatar); Integration points (Avatar); Risks (Undo semantics)
- **Acceptance criteria:**
  - Try on and take off change the player's real character on the server, and other players in the server see it.
  - Same-slot items replace each other (one hair, one top and so on); accessories and emotes stack.
  - Undo reverses the last avatar change; Reset returns to the player's own avatar; Take everything off works.
  - Appearance survives character respawn.
  - Rapid or malformed requests are rejected (rate limit, id validation).
- **Associated UI:** Undo button and "Wearing - N" bar in the panel's left column (frame 5g); toasts "Trying on X" / "Took off X" / "Reset to your avatar".
- **Replication:**
  - **Player avatar (try-on): server Workspace is the source of truth.** The server applies the change to the real character (HumanoidDescription application is a candidate API to evaluate) and Roblox replicates it to everyone. No client reconstruction of the character.
  - Logical worn list and undo history: a session model feeds the HUD badges/counts and the Wearing screen. It never carries position or appearance data.
- **Sub-tasks:**
  - [TODO] 5.1 Investigate and decide (open questions): which item types can be applied without owning them (accessories, classic clothing, bundles/hair combos, animation packs, emotes, faces/heads), failure behaviour for off-sale/unloadable items, how emotes (not appearance) are handled, and the scope of Undo (avatar changes only, or basket/outfit actions too). Document findings in the open questions section.
  - [TODO] 5.2 Config: slot rules (Hair; Clothing/sub-slot; Face; Head; Animation pack; stackable types), rate limit and undo depth. `/create-config` plus Studio module.
  - [TODO] 5.3 Network: `Avatar` controller actions (TryOn, TakeOff, TakeOffAll, Undo, Reset) and `Avatar` state.
  - [TODO] 5.4 Model: `models/userSession/AvatarModel.luau` (UserSession scope: resets each join; holds worn item ids, slot map, undo stack). Use `/create-model`. Open point: restore last look on rejoin is not in the spec; confirm before adding persistence.
  - [TODO] 5.5 Service: a game service (`services/game/AvatarService.luau`, event-driven) that applies the worn list to the character on server, re-applies on `CharacterAdded`/respawn, and resolves "Reset" from the player's own saved description. Use `/create-service`.
  - [TODO] 5.6 Controller: `controllers/AvatarController.luau` with validation (asset id type/shape, catalogue type check, cooldown), slot-rule application via config. Use `/create-controller`.
  - [TODO] 5.7 Wire HUD: Undo, Reset, Take everything off, and the Wearing count badge to the new state/intents (preview and Wearing screen follow in Task 6). Toasts via the Task 3 toast host.
  - [TODO] 5.8 Analytics: custom `try_on`, `take_off`, `reset` events with item id/type (feeds phase 3 signals).
  - [TODO] 5.9 Playtest with two clients: try on from a debug trigger/slash command, verify the other client sees the change, slot replacement, undo, respawn.

### Task 6: Avatar preview, Wearing screen and tap-avatar-to-open-Wearing
- **Status:** [TODO]
- **Why here:** Gives the try-on state its UI (preview, Wearing list) so catalogue browsing in Task 8 has a visible result for every tap.
- **Depends on:** 5
- **Refs:** Scope > Full panel (live avatar preview, Wearing bar); Scope > Wearing; Scope > HUD (tap avatar opens Wearing); Replication strategy (Avatar preview)
- **Acceptance criteria:**
  - The panel's left column shows a live preview of what the player is currently wearing and updates as items change.
  - Wearing screen lists worn items with owned or price per item; Take off per item; Add unowned items to basket; Save as outfit; Take everything off.
  - Tapping your own avatar in the world (mouse or touch) opens Wearing.
  - Preview never moves or alters the real character.
- **Associated UI:** 5g Wearing; panel left column in 5b/5f/5g; 5a ("Tap your avatar in the world").
- **Replication:** **Cosmetic / not position-critical.** The panel preview is a client-only cosmetic copy of the current look (clone/rig rendered in a ViewportFrame; evaluate cloning the character vs building a rig from the description). It is derived from the real character in server Workspace; the server never knows about it. The preview is not stored in any model.
- **Sub-tasks:**
  - [TODO] 6.1 Avatar preview component (`/html-to-react-luau` for the frame, `/create-view` for the rig logic): client-only rig in a ViewportFrame, rotates/spring-settles, updates on Avatar state changes. Studio-free.
  - [TODO] 6.2 Wearing screen (`/html-to-react-luau`, frame 5g): rows with owned/price, Take off, Add to basket, Save as outfit (stub until Task 12), Take everything off, empty state.
  - [TODO] 6.3 Tap-own-avatar hook in `views/hooks/` (input raycast against the local character, mouse and touch) calling `HudApp`'s open-Wearing callback, so no new cross-script bridge pattern is introduced.
  - [TODO] 6.4 Item data the screens need (name, price, owned) come from a small client lookup keyed by asset id; stub with the Task 7 shape until the catalogue lands, and note the dependency.
  - [TODO] 6.5 Playtest on touch: tapping the avatar while the camera moves and while the panel is open.

### Task 7: Catalogue data layer
- **Status:** [TODO]
- **Why here:** The browse UI depends on what Roblox's in-experience catalogue can actually provide. This is the largest unresolved technical risk in the spec, so it is investigated and the data path is built before the UI that consumes it.
- **Depends on:** 5
- **Refs:** Scope > Catalogue (categories, search, filters); Risks (Catalogue data source and rate limits); Integration points
- **Acceptance criteria:**
  - Open questions on catalogue data are answered with evidence and recorded: what search/category/price facets the API exposes, colour as a facet or not, rate limits, caching, and where Featured/Halloween/New/Trending come from.
  - The server can return a page of items (id, name, type/sub-type, price, creator, favourites count) for a category/sub-category/search/price/colour query, within agreed limits.
  - Results for a given player's query are delivered to that player only.
- **Associated UI:** none yet (data layer); shapes follow `logic.js` ITEMS (name, main category, sub-category, price, colour, creator, favourites, flags).
- **Replication:** **Cosmetic / not position-critical.** Catalogue results are logical per-player data, not world entities. Delivery follows the existing intent/state pattern (candidate: a per-player session model holding the latest result page) unless the investigation chooses client-direct calls (see Open questions).
- **Sub-tasks:**
  - [TODO] 7.1 Investigation spike: evaluate `AvatarEditorService` catalogue search and item-details calls, `MarketplaceService` product info, thumbnail services, and any other in-experience catalogue API for: query facets, page size, rate limits, caching windows, and availability from client vs server. Decide server-proxied vs client-direct, and how colour and price filters are applied (server facet vs client filter over fetched pages). Write findings into the open questions.
  - [TODO] 7.2 Investigation: curation source for Featured, seasonal (Halloween), New, Trending, and any items outside the live catalogue. Do not invent one; present options (config-curated lists, a catalogue query heuristic, an external list) for the user to choose.
  - [TODO] 7.3 Config: `CatalogueConfig` (categories, sub-categories, price presets, colour swatches, page size, cache lifetimes, curated lists as decided). `/create-config` plus Studio module.
  - [TODO] 7.4 Service: `services/game/CatalogueService.luau` (event-driven with an in-memory cache; add a loop only if cache expiry demands it) wrapping the API with throttling and retry/backoff. `/create-service`.
  - [TODO] 7.5 Network/Model/Controller: `Catalogue` controller (Search, LoadMore, GetDetails) and a `CatalogueModel` (UserSession) that syncs the latest page to the owner. If 7.1 chooses client-direct, replace this with a client Pattern A module plus a server validation hook for try-on (Task 5 already validates ids). `/create-model`, `/create-controller`.
  - [TODO] 7.6 Slot/type mapping: map catalogue asset types to the slot config from Task 5.2 so browse, wear and the Wearing screen share one definition.
  - [TODO] 7.7 Server-side playtest via slash commands: query each category, apply price/colour filters, observe cache hits and rate-limit behaviour.

### Task 8: Catalogue browsing UI
- **Status:** [TODO]
- **Why here:** First real content in the panel. With the data layer in place, build the screen that most of the experience is spent in.
- **Depends on:** 3, 6, 7
- **Refs:** Scope > Catalogue; Success criteria (fewer clicks for try on / take off / find an item; nothing hidden)
- **Acceptance criteria:**
  - Category tabs (Featured, Halloween, Hair, Clothing, Accessories, Head & Body, Animations, Emotes) with per-category sub-category chips; the grid updates live.
  - Search box; paste an item link or ID resolves to that item; colour filter popover; price filter popover with two-handle min/max slider and presets (Free, Under 50, 50-100, 100+); the grid updates live as filters change; empty state and match count.
  - Item cards show an orange "wearing" badge, a white "in basket" badge, and price/Free/Owned.
  - Tapping a card opens the menu: Try / Take off, Add/Remove basket, Buy/Get, View.
  - Trying an item on and taking it off takes one tap from the menu, with toast and preview feedback.
- **Associated UI:** 5b Catalogue (badges and price range); colour and price popovers; card menu.
- **Replication:** **Cosmetic.** Card images are client-rendered thumbnails or viewports, not world entities. Open question: thumbnails vs 3D viewports on cards (cost on phones).
- **Sub-tasks:**
  - [TODO] 8.1 Decide card imagery (open question): static thumbnail images vs ViewportFrame previews, with a phone performance check.
  - [TODO] 8.2 Catalogue screen (`/html-to-react-luau`, frame 5b): category tabs, sub-chips, search, colour and price popovers (two-handle slider component, new in `components/`, justified by reuse in Stores), grid with staggered entrance (`useTransition` list mode), empty state.
  - [TODO] 8.3 Item card component with badges and the tap menu; menu actions wired to Avatar intents (Task 5), basket callbacks (stubbed to local state until Task 10) and buy-prompt frame (Task 3, confirm stubbed until Task 11).
  - [TODO] 8.4 Paste link/ID: parse catalogue URLs and bare IDs client-side, resolve the item through the Task 7 path, open the item page (Task 9) or show a not-found toast.
  - [TODO] 8.5 Wire `HudApp` subscription to `Catalogue` and `Avatar` states; debounce search; pagination/load more on scroll.
  - [TODO] 8.6 Analytics: search, filter and view events (item id, category) via the controller or `trackEvent`.
  - [TODO] 8.7 Playtest: find an item in fewer taps than CAC (record the count), filter combos, rapid try-on/take-off, phone layout.

### Task 9: Item page, favourites and More like this
- **Status:** [TODO]
- **Why here:** The first persisted per-user collection after World options; item pages are the destination of View from cards, Wearing, Basket, outfit rows and stores, so they come before those.
- **Depends on:** 8
- **Refs:** Scope > Item page; Integration points (persistent user state: favourite items); Out of scope (More like this is same-category rule only)
- **Acceptance criteria:**
  - Large preview; name, type, creator, colour, favourites count.
  - Try on / Take off, Add to basket, Buy / Get free; favourite toggle (persists across sessions); More like this row (same category, same sub-category first).
  - Breadcrumbs show the path and back works (for example Catalogue > Item).
- **Associated UI:** Item page (opened from 5b View; shown inside 5d/5c breadcrumbs).
- **Replication:** Large preview is **cosmetic**: client-only rig/viewport of the item on a copy of the current look, not a server object. Favourites are logical persisted state.
- **Sub-tasks:**
  - [TODO] 9.1 Model: `models/user/FavouritesModel.luau` (User scope) holding favourite item ids (and, later, favourite store ids for Task 18). `/create-model`; note index size limits.
  - [TODO] 9.2 Network/Controller: `Favourites` controller (ToggleItem), validated against catalogue ids, rate-limited. `/create-controller`.
  - [TODO] 9.3 Item page screen (`/html-to-react-luau`): preview (reuse Task 6 rig), details, action row, favourite toggle with count, More like this row (same-category rule as a client/server query over cached results).
  - [TODO] 9.4 Hook up breadcrumbs for deep pushes from any source (catalogue, basket, wearing, outfit rows, stores) via the navigation hook from Task 2.
  - [TODO] 9.5 Playtest persistence of favourites across rejoin and the More like this row.

### Task 10: Basket model and Basket screen
- **Status:** [TODO]
- **Why here:** Basket persistence and the screen are the first half of the "Basket and buying" layer; buying (Task 11) needs a real basket to buy from.
- **Depends on:** 9
- **Refs:** Scope > Basket; Scope > HUD (Basket button badge); Integration points (persistent: basket)
- **Acceptance criteria:**
  - Add/remove from basket works from the card menu, item page, Wearing and outfit screens (outfit sources follow in later tasks); the Basket button badge shows the Robux total of unowned basket items, and the panel Basket card shows count and CTA ("Open basket - N R$").
  - Basket persists across sessions.
  - Basket screen: rows with Try on / Remove, summary (items, already owned, total), Try on everything, "pull in what you're wearing".
  - Counts and badges animate; no always-on basket panel.
- **Associated UI:** 5f Basket; basket button and card in 5a and the panel.
- **Replication:** logical persisted state (**cosmetic / not position-critical**): model plus client view, per the template pattern.
- **Sub-tasks:**
  - [TODO] 10.1 Config: basket size limit. `/create-config`.
  - [TODO] 10.2 Model: `models/user/BasketModel.luau` (User scope). `/create-model`.
  - [TODO] 10.3 Network/Controller: `Basket` controller (Add, Remove, Clear, AddWorn, TryAll), validated; `TryAll` reuses the Avatar service's slot-aware apply rather than duplicating it. `/create-controller`.
  - [TODO] 10.4 Replace the local-state stubs from Tasks 2, 6, 8 and 9 with real Basket intents/state in `HudApp`.
  - [TODO] 10.5 Basket screen (`/html-to-react-luau`, frame 5f): rows, summary, actions, empty state, list animations.
  - [TODO] 10.6 Price/ownership display uses the lookup shape from Task 7; the "already owned" count is finalised in Task 11.
  - [TODO] 10.7 Analytics: `basket_add`, `basket_remove` events.
  - [TODO] 10.8 Playtest: add from every entry point, rejoin persistence, basket badge sums.

### Task 11: Buying through Roblox prompts, ownership awareness, Save to Roblox, Create avatar
- **Status:** [TODO]
- **Why here:** Completes layer 4. Needs the basket and the buy-prompt frame, and finishes the "Owned" labels used by cards, Wearing, Basket and outfits.
- **Depends on:** 3, 10
- **Refs:** Scope > Buy prompt; Scope > Basket (Buy all); Scope > HUD (Create avatar, Save to Roblox); Constraints (Roblox-native surfaces stay native); Integration points (analytics: purchase)
- **Acceptance criteria:**
  - Buy / Get on an item, and Buy all on the basket or outfit selection, show our confirmation frame (single item or bundle total) then hand off to Roblox's own purchase prompt. We never fake the Roblox UI.
  - Ownership is known per item (cards, item page, Wearing, Basket, outfit rows show Owned; Buy is disabled/relabelled when owned; summaries exclude owned items from totals).
  - Purchased items leave the basket and become Owned after confirmed purchase; cancel or failure leaves everything unchanged with a toast.
  - Save to Roblox uses Roblox's own avatar-editor save prompt for the current look.
  - Create avatar does what is decided in the open question.
- **Associated UI:** Buy prompt frame (Task 3), 5f Basket (Buy all), Item page Buy, 5a action pills Create avatar and Save to Roblox.
- **Replication:** Purchases and avatar saves are Roblox-native and server-confirmed; ownership cache is logical (**cosmetic / not position-critical**), a session model.
- **Sub-tasks:**
  - [TODO] 11.1 Investigation (open questions): candidate APIs to evaluate for catalogue purchases (`MarketplaceService` single and bulk purchase prompts, purchase-finished signals), ownership checks (`MarketplaceService` ownership calls, `AvatarEditorService` inventory-access prompt), bundle vs asset handling, free-item "Get", and what confirms success. Also candidate for Save to Roblox: `AvatarEditorService` save-avatar prompt. Confirm bulk "Buy all" is possible or define a sequential fallback.
  - [TODO] 11.2 Decide Create avatar semantics (open question): its behaviour is not specified in the design beyond a toast. Options include start a blank avatar, open Roblox's avatar-creation prompt, or reset to a default. Await the user's choice before building.
  - [TODO] 11.3 Service/Model: `services/game/OwnershipService.luau` plus `models/userSession/OwnershipModel.luau` caching owned item ids per player with refresh after purchases. `/create-service`, `/create-model`.
  - [TODO] 11.4 Network/Controller: `Purchase` controller (RequestBuy for ids, RequestSaveToRoblox) validating ids, deduplicating owned items and enforcing size limits; handles purchase-finished results and updates Basket and Ownership models. `/create-controller`.
  - [TODO] 11.5 Wire the Task 3 buy-prompt frame to real confirm/cancel; wire Buy all, outfit-selection Buy, item Buy/Get to it; toasts for success/cancel/failure; purchase sound.
  - [TODO] 11.6 Wire Save to Roblox and Create avatar pills.
  - [TODO] 11.7 Analytics: `purchase_prompted`, `purchase_completed`, `purchase_cancelled` with item ids and Robux total (phase 3 signal).
  - [TODO] 11.8 Playtest in a published test place with real (cheap/free) items; Studio purchase prompts are limited, so record anything that can only be verified live.

### Task 12: Outfits, Mine and the outfit screen
- **Status:** [TODO]
- **Why here:** First layer-5 task. Saving a look and wearing it again is the most-used core job after try-on; the outfit screen (with partial wear) is shared by Mine, Community and Roblox sources, so it is built once here.
- **Depends on:** 9, 10, 11
- **Refs:** Scope > Outfits (Mine, outfit screen, ring highlight); Scope > Wearing (Save as outfit); Integration points (persistent: saved outfits)
- **Acceptance criteria:**
  - Outfits tab, source Mine: "New outfit" saves what you're wearing; outfits can be renamed and deleted; the outfit you are currently wearing is ring-highlighted.
  - Search filters outfits by name.
  - Outfit screen: large preview, Wear all, every item with checkboxes (Select all/none), Wear selected, Add to basket, Buy selected (cost label for unowned selection); tapping a row opens the item page; breadcrumb shows Outfits > Name > Item.
  - Save as outfit from the Wearing screen works and shows a toast.
  - Names are filtered through Roblox text filtering.
- **Associated UI:** 5d Outfit screen; Outfits root (source tabs Mine/Community/Roblox, cards, "New outfit" card); 5g Save as outfit.
- **Replication:** saved outfits are logical persisted data (**cosmetic / not position-critical**). Outfit preview is a client-only rig (reuse Task 6); "Wear all" goes through the server-applied Avatar path from Task 5.
- **Sub-tasks:**
  - [TODO] 12.1 Decide outfit data shape and limits (UserEntity per outfit, following the FavoursModel pattern with an index in a User model, vs a single User model list). Note DataStore key length for UserEntity keys (`ModelName_userId_modelId` under 50 chars) and the per-key size cap. Record the decision.
  - [TODO] 12.2 Config: outfit limit per player, name length. `/create-config`.
  - [TODO] 12.3 Model: `OutfitsModel` in the chosen scope (and its index model if UserEntity). `/create-model`.
  - [TODO] 12.4 Network/Controller: `Outfits` controller (Save, Rename, Delete, WearAll, WearSelected), text-filter names with a filtering API (candidate: `TextService:FilterStringAsync`) before storing. `/create-controller`.
  - [TODO] 12.5 Outfits screen root (`/html-to-react-luau`, frame 5d root state and `outfitCards`): source tabs (Mine active, Community and Roblox placeholders until Tasks 13 and 16), search, "New outfit" card, ring highlight when worn items equal the outfit.
  - [TODO] 12.6 Outfit screen (`/html-to-react-luau`, frame 5d): preview, checkbox rows, Wear all/selected, Add to basket, Buy selected via Task 11 flow.
  - [TODO] 12.7 Wire Save as outfit on Wearing (Task 6) and "New outfit".
  - [TODO] 12.8 Analytics: `outfit_save`, `outfit_wear`, `outfit_delete`.
  - [TODO] 12.9 Playtest: save, rejoin, wear partial selection, ring highlight, rename/delete.

### Task 13: Outfits, Roblox username lookup
- **Status:** [TODO]
- **Why here:** Second source of the layer-5 Outfits tab, and it reuses the outfit screen built in Task 12. It has its own API risk, so it is isolated.
- **Depends on:** 12
- **Refs:** Scope > Outfits (Roblox source: search a username to load their saved outfits/current avatar)
- **Acceptance criteria:**
  - On the Roblox source, searching a username loads that user's available outfits (or at minimum their current avatar) into the same card/outfit-screen flow.
  - Not-found, private, banned and rate-limited users show a clear toast/empty state.
  - Wear all and partial wear work on another user's outfit exactly as on Mine.
- **Associated UI:** 5d Outfit screen; Outfits root, Roblox source ("Search a username" placeholder).
- **Replication:** lookups are server-side requests (**cosmetic**); previews are client-only rigs.
- **Sub-tasks:**
  - [TODO] 13.1 Investigation (open question): what the platform exposes for another user's saved outfits vs only their current avatar (candidates: `Players` name/id and appearance lookup methods, `AvatarEditorService` outfit queries). If saved outfits of other users are not retrievable, present the fallback options to the user instead of deciding.
  - [TODO] 13.2 Service: `services/game/RobloxAvatarLookupService.luau` with caching and throttling. `/create-service`.
  - [TODO] 13.3 Network/Model/Controller: `Outfits` actions (LookupUser) and a session model holding the player's last lookup result. `/create-model`, `/create-controller`.
  - [TODO] 13.4 Roblox source tab UI and loading/empty/error states (`/html-to-react-luau`).
  - [TODO] 13.5 Playtest with real usernames including nonexistent and private cases.

### Task 14: Sharing, cross-server storage decision and outfit share codes
- **Status:** [TODO]
- **Why here:** Layer 6. Share codes need a lookup that works across servers, which is the first place we need storage beyond per-user DataStore. The decision made here is reused by community outfits (Task 16) and stores (Task 17), so it is made now, deliberately, before building on it.
- **Depends on:** 12
- **Refs:** Scope > Share (outfit or store); Risks (Cross-server data; moderation); Integration points (Shared/global state beyond one server)
- **Acceptance criteria:**
  - Share on an outfit screen > Reveal code produces a short, copyable `OUT-XXXXXX` code; the code resolves to that outfit from any server.
  - Entering a code in the Outfits search opens that outfit.
  - Codes are stable per outfit, collision-safe, and revocable if the outfit is deleted.
  - The share dialog (code, copy, reveal-blur) has motion and sound.
  - User-supplied names that are shown to others pass through text filtering.
- **Associated UI:** 5e Share (Reveal code, copy, QR slot); Outfits search accepting codes.
- **Replication:** shared lookup data is logical, cross-server, not position-critical (**cosmetic**). No world entity.
- **Sub-tasks:**
  - [TODO] 14.1 Investigation and decision (open question): cross-server storage options for code lookup, community content and stores (candidates: a global DataStore, OrderedDataStore for rankings, MemoryStore for short-lived lookups, an external service via HttpService; consider `MessagingService` only for cache invalidation). Compare consistency, size limits, request budgets, cost, and moderation hooks. Do not pick on the user's behalf.
  - [TODO] 14.2 Decide code format and generation (6 characters of the design's alphabet, collision handling, deterministic vs random) and moderation/takedown approach.
  - [TODO] 14.3 Service: `services/framework` or `services/game` `SharedContentService` (decide placement: it is a dependency of several services, so framework placement may fit; justify) exposing publish/lookup/delete with throttling. `/create-service`.
  - [TODO] 14.4 Network/Controller: `Share` controller (RevealCode, ResolveCode) with validation and rate limits. `/create-controller`.
  - [TODO] 14.5 Share dialog (`/html-to-react-luau`, frame 5e): reveal with blur-to-clear on the code, copy-to-clipboard behaviour (evaluate what Roblox allows on a client), QR slot placeholder. Roblox's clipboard limitations mean the "Copy" affordance may need an alternative (select-and-show); record as a divergence if so.
  - [TODO] 14.6 Wire code entry in the Outfits search to resolve and push to the outfit screen.
  - [TODO] 14.7 Analytics: `share_reveal`, `share_copy`, `code_resolve`.
  - [TODO] 14.8 Playtest across two servers (Studio server test, then live) for code lookup.

### Task 15: QR deep links
- **Status:** [TODO]
- **Why here:** Isolated because it depends on unresolved platform support (experience launch data/deep links) and on a QR encoder. Codes already work without it, so a failure here does not block Sharing's core value.
- **Depends on:** 14
- **Refs:** Scope > Share (QR deep-links back to that screen); Risks (Deep links from QR)
- **Acceptance criteria:**
  - The share dialog shows a real, scannable QR whose link lands a joining player on that specific outfit (and later store) screen.
  - A player already in the experience who opens the same link is taken to the same screen without disruption.
  - Existing acquisition attribution through LaunchData in analytics is not corrupted.
- **Associated UI:** 5e Share (QR tile, blurred until revealed).
- **Replication:** logical data; no world entity.
- **Sub-tasks:**
  - [TODO] 15.1 Investigation (open question): what launch-data/deep-link route Roblox supports for landing a joiner in a specific experience with a payload (candidates: experience join URL with launch data, `Players:GetJoinData`, `TeleportService` and `MessagingService` for already-in-experience cases); what a QR scanned by a phone camera can open; size limits of the payload.
  - [TODO] 15.2 Integration risk: `AnalyticsService` stores `LaunchData` as the `launch_data` acquisition property and treats untagged joins as `organic`. Decide how deep-link payloads coexist (namespace the payload, or separate analytics handling); update `AnalyticsService` accordingly and note it in `docs/CONFIG_GUIDE.md`.
  - [TODO] 15.3 QR encoder: evaluate a Luau QR library already usable in the repo (check `Packages/`) vs adding one; render modules as a client component (pixels as frames or an image).
  - [TODO] 15.4 Join-time handler: a service (`services/game/DeepLinkService.luau`, event-driven on player join) that reads the launch data and tells the client which screen to open via a state/intent, honoured by `HudApp` navigation. `/create-service`.
  - [TODO] 15.5 Playtest on a phone scanning a QR shown on another device, in a live published place.

### Task 16: Community outfits
- **Status:** [TODO]
- **Why here:** Layer 7. Reuses the cross-server store and share codes from Task 14 and the outfit screen from Task 12.
- **Depends on:** 12, 14
- **Refs:** Scope > Outfits (Community source); Risks (Cross-server data; moderation); Integration points
- **Acceptance criteria:**
  - A player can publish one of their outfits to Community; others (in any server) can browse and open it on the Community source.
  - Community cards show name and creator ("by pixelfox"); search by name or code works.
  - The creator can unpublish; moderation (name filtering, report or takedown path) is in place per the decision.
  - Browsing stays responsive (paged results, cached).
- **Associated UI:** 5d Outfit screen (Community source); Outfits root cards.
- **Replication:** logical cross-server data (**cosmetic**); outfit preview is a client-only rig.
- **Sub-tasks:**
  - [TODO] 16.1 Decisions (open questions): publishing rules (who can publish, limits, edit-after-publish), discovery/ordering (newest, most worn, curated), and moderation workflow. Present options; do not decide for the user.
  - [TODO] 16.2 Extend `SharedContentService` with community publish/list/unpublish and paging; add a Community browse model (UserSession) delivering pages to the requester. `/create-model`.
  - [TODO] 16.3 Controller actions (Publish, Unpublish, BrowseCommunity, Report) in `Outfits`/`Community` controller. `/create-controller`.
  - [TODO] 16.4 Community source UI (`/html-to-react-luau`): grid, paging, publish toggle on Mine outfit cards/outfit screen.
  - [TODO] 16.5 Analytics: `community_publish`, `community_open`.
  - [TODO] 16.6 Playtest across servers, moderation edge cases (blocked names), unpublish.

### Task 17: Stores data and backend
- **Status:** [TODO]
- **Why here:** Layer 8. Stores add a new cross-server entity with ratings/visits and codes, plus several unresolved business questions, so the data model and backend are agreed and built before the UI.
- **Depends on:** 9, 14
- **Refs:** Scope > Stores (Home carousels, Store page, My stores); Scope > Share (store codes); Risks (What a store is; cross-server data); Integration points (favourite stores, owned stores)
- **Acceptance criteria:**
  - A store is persisted as a curated set of catalogue items with name, creator, rating and visits, published/unpublished, readable across servers.
  - Visits and rating update when players open or like a store; counts are bounded against abuse.
  - Store codes (`STR-XXXXXX`) resolve a store from any server.
  - Home categories (Sponsored, Popular, Top rated, Favourites, My stores) can be queried.
- **Associated UI:** none yet; data follows `logic.js` STORES (name, rating %, visits, sponsored flag) and the store-page sections.
- **Replication:** logical cross-server data (**cosmetic**); no world entity.
- **Sub-tasks:**
  - [TODO] 17.1 Decisions (open questions): what "Sell your own items" means commercially (any creator revenue share is a business question, not assumed); how sponsored placement is sourced (candidate: config-curated list for phase 1); how ratings and visits are defined and protected from abuse; and the moderation approach for user-named stores. Present options and wait.
  - [TODO] 17.2 Config: `StoresConfig` (limits per player, section sizes, collection rules such as Under 50). `/create-config`.
  - [TODO] 17.3 Extend `SharedContentService` with store publish/list/rank/visit/rate operations (OrderedDataStore-style ranking candidate from the Task 14 decision) and store codes.
  - [TODO] 17.4 Model: `models/user/MyStoresModel.luau` (User, owned store ids and favourite store ids may live in `FavouritesModel` from Task 9) and a Stores browse model (UserSession). `/create-model`.
  - [TODO] 17.5 Controller: `Stores` controller (BrowseCategory, OpenStore, Favourite, Rate, ResolveCode). `/create-controller`.
  - [TODO] 17.6 Collections derivation (Bestsellers, New arrivals, rule-based collections) computed server-side from store items and cached.
  - [TODO] 17.7 Slash-command playtest: seed stores, query categories, check rate limits.

### Task 18: Stores UI, home, store page, collections, favourites, store share
- **Status:** [TODO]
- **Why here:** The browsing half of layer 8, once the backend returns real data. It reuses the item card, carousel and share dialog from earlier tasks.
- **Depends on:** 3, 8, 15, 17
- **Refs:** Scope > Stores (Home, Store page); Scope > Share (store); Success criteria (fewer taps, nothing hidden)
- **Acceptance criteria:**
  - Stores home shows Netflix-style carousels per category (Sponsored, Popular, Top rated, Favourites, My stores), each with See all; tapping a category tab shows it as a grid and tapping it again returns home.
  - Search by name, or enter a store code, opens that store.
  - Store page: header with rating and visits, Favourite and Share; featured item viewer with arrows (try, basket, view); Bestsellers and New arrivals carousels with See all; Collections tiles that open their own grid.
  - Share on a store gives a `STR-XXXXXX` code and QR (via Tasks 14 and 15).
  - Favourite stores persist.
- **Associated UI:** 5h Stores home; 5c Store page; 5e Share (store variant); item cards from 5b.
- **Replication:** **Cosmetic**, client-rendered UI; featured item viewer previews are client-only rigs.
- **Sub-tasks:**
  - [TODO] 18.1 Stores home (`/html-to-react-luau`, frame 5h): category tabs toggle, carousels with swipe/scroll (reuse `useDrag` where a drag carousel is wanted), See all grid, search/code entry, empty states.
  - [TODO] 18.2 Store page (`/html-to-react-luau`, frame 5c): header, featured viewer with arrows, carousels, collection tiles, collection grid.
  - [TODO] 18.3 Favourite store toggle (extends the Favourites controller/model); Favourites carousel.
  - [TODO] 18.4 Store share (frame 5e store variant) using the Task 14 dialog.
  - [TODO] 18.5 Item cards inside stores reuse the Task 8 card menu (Try, basket, buy, View).
  - [TODO] 18.6 Analytics: `store_open`, `store_favourite`, `store_share`.
  - [TODO] 18.7 Playtest: browse by every route, tap counts to reach an item vs CAC, phone layouts.

### Task 19: My stores and Create store
- **Status:** [TODO]
- **Why here:** Last feature of layer 8. It has the most open design and business questions, so it is last, built on a fully working store browsing experience.
- **Depends on:** 17, 18
- **Refs:** Scope > Stores (My stores: Create store; own stores published/unpublished); Risks (What a store is)
- **Acceptance criteria:**
  - My stores carousel/grid shows "Create store" and the player's own stores marked Published or Unpublished.
  - A player can create a store (name, a chosen set of items), edit it, publish and unpublish it; a published store appears in browse and resolves via its code.
  - Names are filtered; per-player limits enforced.
- **Associated UI:** 5h "My stores" row and tab ("Create store - Sell your own items"; "My Store - Unpublished"). The create/edit flow is not in the design (gap).
- **Replication:** logical persisted/shared data (**cosmetic**).
- **Sub-tasks:**
  - [TODO] 19.1 Design gap (open question): the store creation/edit/publish screens are not designed. Request a design round or agree a minimal flow before building.
  - [TODO] 19.2 Controller actions (CreateStore, EditStore, Publish, Unpublish, DeleteStore) with name filtering and item validation. `/create-controller`.
  - [TODO] 19.3 Store editor UI (`/html-to-react-luau` once designed), reusing catalogue cards and the item picker.
  - [TODO] 19.4 My stores wiring on Stores home.
  - [TODO] 19.5 Analytics: `store_create`, `store_publish`.
  - [TODO] 19.6 Playtest: create, publish from one server, see it from another.

### Task 20: Retire template example features and refresh docs
- **Status:** [TODO]
- **Why here:** By now our own models, controllers, views, services and configs exist, so the guides can cite them. Removing the examples earlier would have left the docs with nothing to point at; removing them last satisfies "replaced as this work lands" without breaking the guides mid-way.
- **Depends on:** 19
- **Refs:** Constraints (Template example features replaced; doc and skill references updated in the same change); Integration points (HudApp, Analytics); `docs/PROJECT_BRIEF.md` Decisions
- **Acceptance criteria:**
  - Candles, Shrine, Cash Machine, Bazaar, Favours and the gold/treasure Inventory are removed from source (models, controllers, views, services, configs, Network entries), with no dangling references.
  - README, all `docs/*_GUIDE.md`, `docs/SLASH_COMMANDS.md` and `.claude/commands/*.md` examples point to the new in-repo equivalents (or, where no equivalent exists, are retained per the open-question decision) and `docs/PROJECT_BRIEF.md` Decisions is updated.
  - The project loads with no errors; the analytics "gold" dimension is replaced.
- **Replication:** none (removal).
- **Sub-tasks:**
  - [TODO] 20.1 Decide retirement policy (open question): remove every example, or keep one example for any pattern with no in-repo replacement (for instance the dynamic ServerEntity pattern and CollectionService workspace views).
  - [TODO] 20.2 Remove server examples: `models/user/InventoryModel`, `models/server/ShrineModel`, `models/userEntities/FavoursModel`, `models/serverEntities/CandlesModel`; controllers `BazaarController`, `CashMachineController`, `ShrineController`; `services/game/CandleService`; Network entries (Bazaar, CashMachine, Shrine controllers; Candles, Favours, Inventory, Shrine states, types).
  - [TODO] 20.3 Remove client examples: `BazaarView`, `CandleView`, `CashMachineView`, `ShrineView`, and configs `CandlesConfig`, `FavoursConfig` plus their ConfigTypes (and the Studio config modules; note that these are Studio-only).
  - [TODO] 20.4 Replace the `gold` example in `services/game/AnalyticsDimensions.luau` with a real dimension (for example basket count or worn count) and update `AnalyticsConfig.globalParams` (Studio config) and `docs/CONFIG_GUIDE.md`.
  - [TODO] 20.5 Update docs and skills: `README.md`, `docs/MODEL_GUIDE.md`, `docs/CONTROLLER_GUIDE.md`, `docs/VIEW_GUIDE.md`, `docs/SERVICES_GUIDE.md`, `docs/CONFIG_GUIDE.md`, `docs/SLASH_COMMANDS.md`, `docs/BOLT_API.md` if referencing, `.claude/commands/create-model.md`, `create-controller.md`, `create-view.md`, `create-service.md`, `create-config.md`, `create-plan.md`, `help-me.md`, `html-to-react-luau.md`, `docs/PROJECT_BRIEF.md`, `CLAUDE.md` if needed. Keep `/help-me` in sync.
  - [TODO] 20.6 Studio cleanup checklist: tagged Workspace objects (Shrine, Bazaar, CashMachine), `ReplicatedStorage.Assets` Candle, and config modules to be deleted by hand (not Rojo-managed).
  - [TODO] 20.7 Smoke playtest: clean boot with no warnings; all features from Tasks 4 to 19 still work.

### Task 21: Polish, analytics completeness and success-criteria review
- **Status:** [TODO]
- **Why here:** The success criteria are judged side by side with CAC in playtests, not by a metric. This closing task audits against them and fills gaps accumulated during the build.
- **Depends on:** 20
- **Refs:** Success criteria (functional parity; fewer clicks, nothing hidden; state stays small; feels good); Integration points (Analytics); Devices
- **Acceptance criteria:**
  - A side-by-side CAC comparison records: feature parity (what CAC does vs ours or an equivalent), and tap counts for try on, take off, buy what you're wearing, save/load an outfit, find an item. Ours is lower on each.
  - Every feature is reachable from the three tabs, the HUD buttons or the avatar itself. No mode-dependent hidden UI.
  - Wearing and basket state show only as badges and counts, never always-on panels.
  - Every open/close, tab change, press, toast and state change has motion and, where it helps, sound; nothing reads as clutter.
  - iPad and desktop equivalent; phone usable. Analytics covers try-on, basket, purchase, outfit save/share and navigation.
- **Associated UI:** All frames 5a to 5h, World options panel, buy prompt, toasts.
- **Replication:** none new.
- **Sub-tasks:**
  - [TODO] 21.1 Navigation analytics: a navigation intent/controller (or `trackEvent` calls) for tab opens, breadcrumb depth and screen views, validated against a fixed screen list. `/create-controller`.
  - [TODO] 21.2 Verify analytics events from Tasks 4 to 19 reach GA4 with consistent naming; update `bigquery/` notes and `/analytics` references if events need documenting.
  - [TODO] 21.3 CAC side-by-side playtest script: parity checklist plus tap-count table; record results in the feature folder notes (not a new doc unless asked).
  - [TODO] 21.4 Feel pass: audit every interactive element for hover/press states, motion and sounds; remove anything cluttering; tune springs and volumes.
  - [TODO] 21.5 Device pass on desktop, iPad and phone: sizing issues captured in earlier tasks, touch targets, safe areas, performance (frame rate with previews and carousels).
  - [TODO] 21.6 Triage and fix, or log for phase 2, anything found. Confirm with the user that phase 1 is acceptable.

---

## Open questions

Each needs a user decision (or a recorded finding) before or during the named task. None has been decided in this plan.

1. ~~**Sizing (Task 1).**~~ Decided: `fill`, scaled by height.
2. ~~**Fonts and icons (Task 1).**~~ Decided: Nunito (built in); one image per Material Symbols icon.
3. ~~**Glass panels (Task 1).**~~ Decided: blur behind full-screen panels.
4. **Sound direction and asset source (Task 3).** No sound design exists. Needs a style, a source (authored, bought, generated) and licensing.
5. **Flight in a shared world (Task 4).** Collisions, griefing and where "quiet spots" are depend on world layout, which isn't designed. Phase-1 defaults are provisional.
6. **Undo scope (Task 5).** Avatar changes only, or basket and outfit actions too.
7. **Try-on coverage and failure behaviour (Task 5).** Which item types can be tried on without owning them, and what happens for off-sale or unloadable items and emotes.
8. **Restore last look on rejoin (Task 5).** Not in the spec; the avatar model is session-only unless the user wants persistence.
9. **Catalogue data source and limits (Task 7).** What the in-experience APIs expose, rate limits, and whether colour is a facet or a client-side filter.
10. **Catalogue delivery architecture (Task 7).** Server-proxied (per-player session model through the existing intent/state pattern; cacheable, protects rate limits, extra latency) vs client-direct (lower latency, but each client spends its own budget and the server still has to validate try-on ids).
11. **Curation source (Task 7).** Where Featured, seasonal (Halloween), New and Trending come from: config-curated lists, query heuristics, or an external list.
12. **Card imagery (Task 8).** Thumbnails (cheap, static) vs ViewportFrame previews (lively, heavier on phones).
13. **What Create avatar does (Task 11).** The design only shows a toast. Needs a defined behaviour.
14. **Purchase and ownership specifics (Task 11).** Confirm bulk "Buy all" is possible through Roblox prompts or accept sequential prompts; how ownership of bundles is determined.
15. **Roblox username lookup depth (Task 13).** Whether another user's saved outfits are retrievable, or only their current avatar.
16. **Cross-server storage technology (Task 14).** DataStore, OrderedDataStore, MemoryStore, external service, or a mix; consistency, budgets and moderation hooks. Also used by Tasks 16 and 17.
17. **Moderation (Tasks 12, 14, 16, 17, 19).** Approach to user-named outfits and stores, and takedown/report workflow.
18. **Deep links and QR (Task 15).** What launch-data/deep-link route Roblox supports for landing on a specific screen, and how it coexists with the existing LaunchData acquisition attribution.
19. **Community outfits rules (Task 16).** Publishing eligibility, ordering/discovery, edits after publishing.
20. **What a store is commercially (Task 17).** Whether "Sell your own items" implies creator revenue share (a business question), how sponsored placement is sourced, and how ratings and visits are defined and protected from abuse.
21. **Store creation design (Task 19).** The create/edit/publish screens are not in the design.
22. **Retirement policy for template examples (Task 20).** Remove all, or keep one example for patterns with no in-repo replacement.

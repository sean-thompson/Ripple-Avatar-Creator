# Phase 1 — Catalog Avatar Creator adaptation

## Overview

Our take on Roblox's Catalog Avatar Creator (CAC): the UI in
`design/` (the Claude Design "Avatar Creator iPad" mock, round 5) and the
functionality that runs behind it. Players stand in a styleable world, try on
anything from the catalogue for free, gather what they want into a basket, and
buy it through Roblox's own prompts. They save and share outfits, browse
community outfits and other users' avatars, and browse (or create) curated
stores. We keep most of what CAC does, or an equivalent, but present it with
far fewer top-level buttons, nothing hidden behind "the right way in", and
state that doesn't take up the screen. Polished motion and sound make it
stand out without making it look bloated.

This phase is the CAC-equivalent experience only. Points, auctions,
recommendations and monoliths are phases 2 and 3 (see `docs/PROJECT_BRIEF.md`).

## Success criteria

Played side by side with CAC, ours is better. In practice:

- **Functional parity:** most of what CAC lets you do is here, or something
  equivalent.
- **Fewer clicks, nothing hidden:** core jobs (try something on, take it off,
  buy what you're wearing, save or load an outfit, find an item) take fewer
  taps than in CAC. Every feature is reachable from the three tabs, the HUD
  buttons or the avatar itself. No mode-dependent hidden UI.
- **State stays small:** wearing and basket state shows as badges and counts,
  not panels that live on screen.
- **It feels good:** every open/close, tab change, press and state change
  has considered motion (springs/tweens) and, where it helps, sound. The polish
  reads as "nice", never as clutter.

This is a feel/quality bar, judged in playtests, not a metrics gate.

## Non-goals & constraints

**Out of scope for phase 1:**
- Points economy, auctions, UGC minting (phase 2).
- The recommendation engine and its external services (phase 3). The item
  page's "More like this" uses a simple same-category rule for now. It's the
  slot recommendations will fill later.
- Diegetic monoliths. Phase 1 is HUD-led, as in the design.

**Constraints:**
- **Template architecture.** Models / Controllers / Views / Services / Configs per
  `docs/*_GUIDE.md`. The HUD is react-luau under `HudApp`, reusing and extending
  the shared `views/components` and `views/hooks` (springs, transitions, drag).
- **Devices.** iPad and desktop are the design target and are treated as
  equivalent. Phones must work but may feel tighter. Nothing is "secondary".
- **Roblox-native surfaces stay native.** Purchases go through Roblox's purchase
  prompts. Saving to the player's Roblox account goes through Roblox's own
  avatar-editor prompts. We never fake those.
- **Template example features** (Candles, Shrine, Cash Machine, Bazaar,
  Favours, gold/treasure Inventory, StatusBar) get replaced as this work lands.
  The doc and skill references to them are updated in the same change (see
  `docs/PROJECT_BRIEF.md`).

## Scope: what the design covers

Taken from `design/markup.html` + `design/logic.js`:

**HUD (world view)**
- Three pill tabs, top centre: **Catalogue**, **Stores**, **Outfits**. Each opens
  the full-screen panel on that tab.
- Bottom-left: a large **Basket** button with a Robux-total badge, plus
  **Create avatar**, **Save to Roblox** and **Reset** (reset to your own
  avatar).
- Bottom-right: **World options** toggle → side panel.
- Tapping your own avatar in the world opens **Wearing**.
- Space reserved top-left for the Roblox system bar.
- **No toasts.** Actions confirm themselves where the player is already looking
  (the button or item changes state, the avatar changes, a count rolls) plus a
  sound. Errors and empty states show inline, in the place they happen. (Cut
  after Task 3: a pop-up where you're looking is in the way.)

**World options (side panel)**
- Time of day (0–24h slider). Drives sky colour, sun/moon position and stars.
- Sky preset: Clear / Clouds / Studio / Void.
- Floor colour (5 swatches) and pattern (Grid / Checker / Plain).
- Lighting brightness (50–150%) and a shadows toggle.
- Hint: "Double-jump to fly. Use it to find a quiet spot." Flight is part
  of phase 1.

**Full panel (shared frame)**
- Left column: live **avatar preview** with an **Undo** button and a
  "Wearing · N" bar (opens Wearing), and a **Basket** card with count and CTA.
- Right: content area with **breadcrumbs** and back once you go deeper than a
  tab (e.g. Outfits › Neon Rider › Varsity Jacket).
- Close returns to the world.

**Catalogue**
- Category tabs (Featured, seasonal e.g. Halloween, Hair, Clothing, Accessories,
  Head & Body, Animations, Emotes) with sub-category chips per category.
- Search; **paste an item link or ID**; **colour** filter; **price** filter
  (two-handle min/max slider and presets: Free / Under 50 / 50–100 / 100+). The
  grid updates live.
- Item cards show an orange "wearing" badge, a white "in basket" badge and the
  price/Free/Owned. Tap → menu: **Try / Take off · Add/Remove basket · Buy/Get ·
  View**.
- Wearing rules: same-slot items replace each other (one hair, one top…).
  Accessories and emotes stack.

**Item page**
- Large preview; name, type, creator, colour, favourites count; Try on / Take
  off, Add to basket, Buy / Get free; favourite toggle; **More like this** row.

**Stores**
- **Home:** Netflix-style carousels per category (Sponsored, Popular, Top rated,
  Favourites, My stores), each with See all. Tapping a tab shows that category
  as a grid, and tapping it again returns home. Search, or enter a **store
  code**.
- **Store page:** header with rating and visits, Favourite, Share. A featured
  item viewer with arrows (try/basket/view), **Bestsellers** and **New
  arrivals** carousels with See all, and **Collections** tiles that open
  their own grid.
- **My stores:** Create store; own stores (published/unpublished).

**Outfits**
- Sources: **Mine** (saved in-experience; "New outfit" saves what you're
  wearing), **Community**, **Roblox** (search a username to load their saved
  outfits/current avatar). Search, or enter an **outfit code**. The outfit you
  are currently wearing is ring-highlighted.
- **Outfit screen:** large preview, **Wear all**, then every item with
  checkboxes → Wear selected / Add to basket / Buy selected. Tap a row → the
  item page. Share.

**Basket**
- Rows with Try on / Remove. Summary (items, already owned, total). **Buy
  all**, **Try on everything**, pull in what you're wearing.

**Wearing**
- What's on the avatar, with owned/price per item. Take off. Add unowned to
  basket. **Save as outfit**. Take everything off.

**Share (outfit or store)**
- Share → **Reveal code** → copyable short code (`OUT-XXXXXX` / `STR-XXXXXX`)
  plus a **QR** that deep-links back to that screen in the game. Codes also work
  in the Outfits/Stores search.

**Buy prompt**
- Our confirmation step (single item or bundle total), handing off to Roblox's
  purchase flow.

## Integration points

New work almost entirely. It touches:

- **`HudApp` / HUD components:** the template's StatusBar/Favours/Candles HUD is
  replaced by this design's shell. `HudButton`, `ModalWindow`, `AnimatedModal`
  and `CurrencyChip`, and the spring/transition/drag hooks, are reused or reshaped
  into the new skin.
- **Persistent user state** (User-scoped models): saved outfits, basket,
  favourite items, favourite stores, World options preferences, owned stores.
- **Shared/global state beyond one server:** community outfits, stores and their
  ratings/visits, and share-code → outfit/store lookup. These outlive a server
  and are read across servers. That's more than the template's per-user
  persistence gives out of the box (see Risks).
- **Avatar:** try-on changes the player's real character, so others in the
  server see it.
- **Analytics:** the existing GA4/BigQuery pipeline gets events for try-on,
  basket, purchase, outfit save/share and navigation. These signals also feed
  phase 3 recommendations.

### Replication strategy (per object)

- **Player avatar (try-on):** server Workspace. The server applies the
  avatar change to the character and Roblox replicates it to everyone.
- **Flight (double-jump):** the player's own character, client-owned physics
  as with normal Roblox movement.
- **World options (sky, time, floor, lighting, shadows):** private per player
  and client-side only. Each player sees their own settings and others are
  unaffected. Settings persist as a saved preference.
- **Avatar preview in the panel:** client-only cosmetic copy of the player's
  current look.

## Build order

**Approach:** feel-first, top-down (custom). Get the skin, motion and sound
right before the heavy technical lifts. The design is settled enough that
this runs largely as a waterfall, and gaps get picked up as we go. No
change of direction is expected later.

**First-playable slice:** the HUD shell in the final skin (glossy black/orange
pills, Nunito, Material Symbols, glass panels, glow/press states). Tabs,
basket, action buttons and World options toggle are in place. The full panel
opens and closes and tabs change, with breadcrumbs, on placeholder content.
The buy-prompt frame is styled. All of it has tweens/springs and
UI sounds. This proves the look and feel on iPad, desktop and phone, and
settles the sizing approach.

**Subsequent layers:**
1. **World options for real:** time of day, sky presets, floor colour and
   pattern, brightness, shadows, saved per player; double-jump flight.
2. **Avatar core:** try on / take off with slot rules, Undo, Reset, the
   Wearing screen, the avatar preview, and tap-avatar-to-open-Wearing.
3. **Catalogue:** real catalogue browsing, categories/sub-categories, search,
   paste link/ID, colour and price filters, item cards and menu, item page.
4. **Basket and buying:** basket persistence, Buy / Buy all through Roblox
   prompts, owned-state awareness, Save to Roblox, Create avatar.
5. **Outfits:** Mine (save/load/rename), Roblox (username lookup), outfit
   screen with partial wear.
6. **Sharing:** outfit codes, code search, QR deep links.
7. **Community outfits:** publishing and browsing across servers.
8. **Stores:** store home, store page, collections, favourites, ratings/visits,
   Create store / My stores, store codes.

## Risks & open questions

- ~~**Sizing: relative vs absolute.**~~ Decided in Task 1: author at the
  1180×820 design size under one UIScale, canvas stretched to the screen's
  aspect (`fill`), scaled by viewport height. Roblox-native UI stays
  fixed-size; lay out against its measured inset.
- **Catalogue data source and rate limits:** browsing the full Roblox catalogue
  live (search, category, price, colour) depends on what Roblox's in-experience
  catalogue APIs expose and how fast they can be called. Colour isn't
  necessarily a native catalogue facet. The seasonal tab (e.g. Halloween) and
  Featured/New/Trending need a curation source.
- **Cross-server data:** community outfits, stores, ratings/visits and share
  codes need storage and lookup beyond per-user DataStores. Moderation of
  user-named outfits and stores also has to be handled.
- **What a store is:** a curated set of catalogue items made by a player. If
  "Sell your own items" implies creator revenue share, that's an open
  business question. Sponsored placement needs a model too.
- **Deep links from QR:** depends on Roblox's experience launch-data/deep-link
  support for landing on a specific outfit/store.
- **Undo semantics:** undo for avatar changes only, or for basket/outfit
  actions too.
- **Sound direction:** no sound design exists yet. Needs a style and an asset
  source.
- **Flight in a shared world:** collisions, griefing and where "quiet spots" are
  come from world layout, which isn't designed yet.

## Provenance

- Source brief: Claude Design "Avatar Creator iPad.html" (round 5), unpacked to
  `features/cac-adaptation/design/`; `docs/PROJECT_BRIEF.md`; interview.
- Interviewed: 2026-10-07
- Frameworks selected: none (waterfall project; the design is settled
  enough, and gaps get picked up as we go)
- Build order: feel-first, top-down

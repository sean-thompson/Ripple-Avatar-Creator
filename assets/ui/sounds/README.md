# UI sounds

From ObsydianX, [Interface SFX Pack 1](https://obsydianx.itch.io/interface-sfx-pack-1) — **CC0** (public domain; no credit required).
Picked for a bright, soft, simple-arcade feel: the pack's style 3 tones plus two cursor tones.
The pack has no swipes, so the three swipe sounds are synthesised by `tools/build_swipes.py` (ours, no licence).

| File | Slot (`SkinAssets.sounds`) | Pack source |
|---|---|---|
| press.wav | press — generic button tap | Cursor_tones/cursor_style_4 |
| tab.wav | tab — tab / chip / text-tab change | Cursor_tones/cursor_style_5 |
| open.wav | open — full panel opens | Confirm_tones/style3/confirm_style_3_005 |
| close.wav | close — full panel closes | Back_tones/style3/back_style_3_001 |
| back.wav | back — back, crumb, take off, remove | Back_tones/style3/back_style_3_007 |
| confirm.wav | confirm — add to basket | Confirm_tones/style3/confirm_style_3_002 |
| tryOn.wav | tryOn — try an item on, wear all | Confirm_tones/style3/confirm_style_3_003 |
| purchase.wav | purchase — purchase succeeded | Confirm_tones/style3/confirm_style_3_echo_002 |
| error.wav | error — blocked action | Error_tones/style3/error_style_3_002 |
| switch.wav | switch — Catalogue / Stores / Outfits while the panel is open | ours — `tools/build_swipes.py` |
| worldIn.wav | worldIn — World options slides on | ours — `tools/build_swipes.py` |
| worldOut.wav | worldOut — World options slides off | ours — `tools/build_swipes.py` |

Upload each via Studio's Asset Manager (Audio), then put its asset ID in
`Source/ReplicatedFirst/views/SkinAssets.luau` → `SkinAssets.sounds`. Volumes per slot are in `Tokens.sound`.

# Phase 1 design source

Unpacked from the Claude Design bundle `Avatar Creator iPad.html` (round 5:
"Stores, outfit screen, sharing, Basket + Wearing screens"). The bundle itself
stays outside the repo; these are its two meaningful parts, kept as reference
for `/html-to-react-luau` and for planning.

- `markup.html` — the `<x-dc>` template: every screen as inline-styled HTML at a
  1180×820 iPad canvas. Templating: `{{ expr }}` bindings, `<sc-for>` loops,
  `<sc-if>` conditionals, `sc-camel-on-click` handlers, `style-hover` /
  `style-active` pseudo-states. Font-face rules were stripped (they referenced
  bundle-internal blobs): the fonts are **Nunito 600/700/800/900** and
  **Material Symbols Rounded**.
- `logic.js` — the prototype's state and behaviour (mock catalogue, stores,
  outfits, basket/wearing rules, filters, share codes, World options maths).
  Treat it as a behavioural spec, not code to port: the data is fake and the
  share-code/QR generation is a placeholder.

The design renders seven frames (`5a`–`5h`), one per screen state:
HUD, Catalogue (badges + price range), Stores home, Store page, Outfit screen,
Share, Basket, Wearing.

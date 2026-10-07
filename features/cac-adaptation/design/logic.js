class Component extends DCLogic {
  state = {
    time: 13, sky: 'Clear', floor: '#ff7a00', pattern: 'Grid', bright: 100, shadows: true,
    ui: {
      '5a': {}, '5b': { full: 'Catalogue', menu: 'g:8', filt: 'price' },
      '5h': { full: 'Stores' }, '5c': { full: 'Stores', stack: [{ t: 'store', i: 2 }] },
      '5d': { full: 'Outfits', stack: [{ t: 'outfit', src: 'Community', i: 0 }] },
      '5e': { full: 'Outfits', stack: [{ t: 'outfit', src: 'Mine', i: 0 }], share: { kind: 'outfit', src: 'Mine', i: 0 }, revealed: true },
      '5f': { full: 'Basket' }, '5g': { full: 'Wearing' }
    },
    cat: 'Featured', sub: 'All', q: '', colour: 'Any', pmin: '', pmax: '100', sq: '', storeSort: null, oq: '', osrc: 'Mine',
    worn: [5, 12, 25, 33], basket: [8, 30, 22], owned: [], favs: [], favStores: [9, 11],
    mine: [{ n: 'Spooky Halloween', items: [8, 13, 30, 25] }, { n: 'School Day', items: [0, 9, 14, 18] }, { n: 'Beach Fit', items: [3, 10, 17, 21] }, { n: 'Wookie Slayer', items: [4, 11, 16, 31] }]
  };
  BK = 'linear-gradient(180deg,#4a4a4a 0%,#1d1d1d 48%,#050505 52%,#161616 100%)';
  OR = 'linear-gradient(180deg,#ffc27a 0%,#ff8a1a 48%,#ec6500 52%,#ff9a3a 100%)';
  COL = { Orange: '#ff7a00', Black: '#2a2a2a', White: '#d9d9d9', Pink: '#ff5fa8', Blue: '#3b82f6', Green: '#3fbf6a', Purple: '#8b5cf6', Brown: '#8a5a3b' };
  SUBS = { Featured: ['All', 'New', 'Trending'], Halloween: ['All', 'Clothing', 'Accessories', 'Emotes'], Hair: ['All', 'Long', 'Short', 'Curly', 'Updo'], Clothing: ['All', 'Tops', 'Jackets', 'Bottoms', 'Shoes'], Accessories: ['All', 'Hat', 'Face', 'Neck', 'Back'], 'Head & Body': ['All', 'Faces', 'Heads'], Animations: ['All', 'Packs', 'Idle'], Emotes: ['All', 'Dance', 'Gesture', 'Pose'] };
  CREATORS = ['JON.', 'pixelfox', 'mossy_m', 'k4tana', 'nyxie', 'Roblox'];
  ITEMS = [['Wavy Middle Part','Hair','Long',65,'Brown'],['Messy Bob','Hair','Short',65,'Black'],['Long Ponytail','Hair','Long',80,'Orange','n'],['Space Buns','Hair','Updo',70,'Pink','t'],['Curly Afro','Hair','Curly',75,'Black'],['Side Swept','Hair','Short',0,'Brown','o'],['Braided Crown','Hair','Updo',85,'Brown','n'],['Ringlets','Hair','Curly',70,'Purple'],
    ['Pumpkin Hoodie','Clothing','Tops',65,'Orange','ht'],['Striped Knit','Clothing','Tops',70,'Black'],['Cropped Tee','Clothing','Tops',55,'White','o'],['Varsity Jacket','Clothing','Jackets',90,'Blue','t'],['Puffer Vest','Clothing','Jackets',85,'Green'],['Skeleton Tee','Clothing','Tops',65,'Black','h'],['Cargo Pants','Clothing','Bottoms',60,'Green'],['Plaid Skirt','Clothing','Bottoms',55,'Pink'],['Baggy Jeans','Clothing','Bottoms',65,'Blue','n'],['Track Pants','Clothing','Bottoms',0,'Black'],['Chunky Sneakers','Clothing','Shoes',60,'White','t'],['Platform Boots','Clothing','Shoes',75,'Black'],['Canvas High-tops','Clothing','Shoes',55,'Pink','o'],['Fur Boots','Clothing','Shoes',60,'Pink'],
    ['Cat Ears','Accessories','Hat',40,'Black'],['Witch Hat','Accessories','Hat',95,'Purple','h'],['Heart Tiara','Accessories','Hat',95,'Pink','t'],['Sunglasses','Accessories','Face',45,'Black'],['Ghost Mask','Accessories','Face',85,'White','h'],['Scarf','Accessories','Neck',30,'Orange'],['Pearl Necklace','Accessories','Neck',50,'White','n'],['Backpack','Accessories','Back',55,'Blue'],['Bat Wings','Accessories','Back',120,'Black','ht'],
    ['Classic Smile','Head & Body','Faces',0,'White','o'],['Sleepy','Head & Body','Faces',45,'White'],['Freckles','Head & Body','Faces',30,'Brown'],['Round Head','Head & Body','Heads',40,'White','n'],
    ['Floating Pack','Animations','Packs',315,'Purple','t'],['Ninja Pack','Animations','Packs',250,'Black'],['Bubbly Pack','Animations','Packs',250,'Pink','o'],['Cool Idle','Animations','Idle',60,'Blue'],
    ['Victory Jump','Emotes','Gesture',58,'Orange','t'],['Salute','Emotes','Gesture',40,'Green'],['Dance Groove','Emotes','Dance',75,'Purple','n'],['Wave','Emotes','Gesture',0,'Blue','o'],['Zombie Shuffle','Emotes','Dance',60,'Green','h'],['Spooky Float','Emotes','Pose',70,'Purple','h'],['Hero Pose','Emotes','Pose',50,'Orange']]
    .map(([n, m, sub, p, col, f], id) => ({ id, n, m, sub, p, col, h: (f || '').includes('h'), o: (f || '').includes('o'), nw: (f || '').includes('n'), tr: (f || '').includes('t'), cr: this.CREATORS[id % 6], favs: 40 + (id * 37) % 900 }));
  STORES = [['Mini Basics',89,18.6e6,'s'],['Grouchy UGC',94,294e3,'s'],['Hair Studio',100,596,'s'],['Cartoony Rainbow',100,28.4e3,'s'],['Dolce',95,261.9e3],['Y2K Store',96,461.5e3],['Anime World',86,10.2e6],['Free Shop',89,18e6],['Kings UGC',96,45.6e3],['Chibi Store',85,7.4e3],['Pawing Outfits',91,13.6e6],['Formal Attire',95,15.8e3],['Cosplay Corner',95,42.5e3],['Goth Garden',97,1.7e6],['Blox Fits',82,10.1e6],['Pastel Lab',93,88e3],['Street Kings',90,512e3],['Tiny Hats',99,3.2e3]];
  COMMUNITY = [['Neon Rider','pixelfox',[11,16,18,29,27]],['Cottagecore','mossy_m',[2,15,21,28]],['Street Ninja','k4tana',[12,14,19,36]],['Goth Princess','nyxie',[9,15,19,23]],['Cyber Punk','zeroday',[3,13,16,25]],['Cozy Winter','snowpea',[1,9,21,27]],['Skater','ollie_o',[4,10,16,18]],['Pumpkin Patch','JON.',[8,14,18,26]],['Fairy Core','glimmer',[7,15,20,24]],['Sporty','dashr',[0,10,17,18]]];
  ROBLOX = [['Current Avatar',[0,10,14,19,31]],['Weekend',[1,11,16,21]],['Party',[3,9,15,19,24]]];
  KEYS = [[0,'#070b22','#141c44'],[5,'#0d1438','#2a2f62'],[6.5,'#3c5aa8','#f4a35e'],[8.5,'#2b79d8','#a9d6f2'],[16,'#2f7fd6','#bfe0f2'],[18,'#4a3c86','#ff8a3d'],[19.5,'#1b1f52','#6a3f6e'],[21,'#090d2a','#1a1f48'],[24,'#070b22','#141c44']];
  mix(a, b, t) { const h = x => [1,3,5].map(i => parseInt(x.slice(i, i + 2), 16)); const A = h(a), B = h(b); return 'rgb(' + A.map((v, i) => Math.round(v + (B[i] - v) * t)).join(',') + ')'; }
  setUI(id, patch) { this.setState(s => ({ ui: { ...s.ui, [id]: { ...s.ui[id], ...patch } } })); }
  toast(id, msg) { this.setUI(id, { toast: msg }); clearTimeout(this['t' + id]); this['t' + id] = setTimeout(() => this.setUI(id, { toast: null }), 1800); }
  slotKey(i) { return i.m === 'Hair' ? 'Hair' : i.m + '/' + i.sub; }
  hash(str) { let h = 2166136261; for (const ch of str) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619) >>> 0; } return h; }
  code(prefix, str) { const A = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; let h = this.hash(str), out = ''; for (let i = 0; i < 6; i++) { out += A[h % 32]; h = (Math.floor(h / 32) ^ Math.imul(h, 2654435761)) >>> 0; } return prefix + '-' + out; }
  qr(str) {
    let h = this.hash(str); const rnd = () => { h ^= h << 13; h >>>= 0; h ^= h >> 17; h ^= h << 5; h >>>= 0; return h / 4294967296; };
    const cells = [];
    const finder = (x, y) => { for (const [fx, fy] of [[0, 0], [14, 0], [0, 14]]) { const dx = x - fx, dy = y - fy; if (dx >= 0 && dx < 7 && dy >= 0 && dy < 7) return (dx === 0 || dx === 6 || dy === 0 || dy === 6 || (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4)) ? 1 : 0; if (dx >= -1 && dx <= 7 && dy >= -1 && dy <= 7) return 0; } return null; };
    for (let y = 0; y < 21; y++) for (let x = 0; x < 21; x++) { const f = finder(x, y); const on = f === null ? (y === 6 || x === 6 ? (x + y) % 2 === 0 : rnd() > 0.52) : f === 1; cells.push({ c: on ? '#111' : '#fff' }); }
    return cells;
  }
  getOutfit(src, i) {
    const s = this.state;
    if (src === 'Mine') { const m = s.mine[i]; return m && { n: m.n, by: 'Your outfit', items: m.items }; }
    if (src === 'Community') { const c = this.COMMUNITY[i]; return { n: c[0], by: 'by ' + c[1] + ' · community', items: c[2] }; }
    const r = this.ROBLOX[i]; return { n: r[0], by: 'Saved on Roblox', items: r[1] };
  }
  storeItems(k) { return this.ITEMS.filter(i => (i.id * 7 + k * 3) % 5 < 2 || (i.id + k) % 11 === 0); }
  renderVals() {
    const s = this.state, BK = this.BK, OR = this.OR, t = s.time;
    let k = 0; while (k < this.KEYS.length - 2 && t > this.KEYS[k + 1][0]) k++;
    const [t0, a0, b0] = this.KEYS[k], [t1, a1, b1] = this.KEYS[k + 1];
    const f = (t - t0) / (t1 - t0), top = this.mix(a0, a1, f), bot = this.mix(b0, b1, f);
    const day = Math.max(0, Math.sin(Math.PI * (t - 5.5) / 13));
    const open = s.sky === 'Clear' || s.sky === 'Clouds';
    let skyBg = `linear-gradient(180deg,${top} 0%,${bot} 50%,${bot} 100%)`;
    if (s.sky === 'Studio') skyBg = 'linear-gradient(180deg,#7d828c 0%,#c9ccd2 50%,#c9ccd2 100%)';
    if (s.sky === 'Void') skyBg = 'linear-gradient(180deg,#000 0%,#0b0b0d 50%,#0b0b0d 100%)';
    const isSun = t >= 6 && t <= 18, p = isSun ? (t - 6) / 12 : ((t + 6) % 24) / 12;
    const line = 'rgba(0,0,0,.14)';
    const pat = s.pattern === 'Grid' ? `linear-gradient(${line} 2px,transparent 2px) 0 0/70px 70px,linear-gradient(90deg,${line} 2px,transparent 2px) 0 0/70px 70px,` : s.pattern === 'Checker' ? `conic-gradient(rgba(0,0,0,.1) 25%,transparent 0 50%,rgba(0,0,0,.1) 0 75%,transparent 0) 0 0/140px 140px,` : '';
    const lit = s.sky === 'Studio' ? 1 : (0.45 + 0.55 * day);
    const fmt = x => { const h = Math.floor(x) % 24, m = Math.round((x % 1) * 60); return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0'); };
    const fmtN = n => n >= 1e6 ? (n / 1e6).toFixed(1) + 'M' : n >= 1e3 ? (n / 1e3).toFixed(1) + 'K' : String(n);
    const I = this.ITEMS;
    const owned = i => i.o || s.owned.includes(i.id);
    const worn = new Set(s.worn), bset = new Set(s.basket);
    const tint = i => `linear-gradient(160deg,${this.COL[i.col]}55,#1c1c1c 75%)`;
    const pInfo = i => ({ showToll: !owned(i) && i.p > 0, priceLabel: owned(i) ? 'Owned' : i.p === 0 ? 'Free' : String(i.p), priceColor: owned(i) ? 'rgba(255,255,255,.6)' : i.p === 0 ? '#9be37a' : '#ffa64d', priceText: owned(i) ? 'Owned' : i.p === 0 ? 'Free' : i.p + ' Robux' });
    const wearOne = (st, i) => { let w = st.worn.filter(x => x !== i.id); if (i.m !== 'Accessories' && i.m !== 'Emotes') w = w.filter(x => this.slotKey(I[x]) !== this.slotKey(i)); w.push(i.id); return w; };
    const toggleWear = (i, id) => { const on = worn.has(i.id); this.setState(st => ({ worn: on ? st.worn.filter(x => x !== i.id) : wearOne(st, i) })); this.toast(id, on ? 'Took off ' + i.n : 'Trying on ' + i.n); };
    const toggleBasket = (i, id) => { const on = bset.has(i.id); this.setState(st => ({ basket: on ? st.basket.filter(x => x !== i.id) : [...st.basket, i.id] })); this.toast(id, on ? 'Removed ' + i.n + ' from basket' : 'Added ' + i.n + ' to basket'); };
    const openBuy = (id, items) => {
      items = items.filter(i => !owned(i));
      if (!items.length) return this.toast(id, 'You already own all of that');
      const tot = items.reduce((a, i) => a + i.p, 0);
      this.setUI(id, { buy: { ids: items.map(i => i.id), title: items.length === 1 ? 'Buy item' : 'Buy ' + items.length + ' items', text: items.length === 1 ? 'Would you like to buy ' + items[0].n + '?' : items.map(i => i.n).join(', '), price: tot === 0 ? 'Free' : String(tot), tint: items.length === 1 ? tint(items[0]) : '#2a2a2a' }, menu: null });
    };
    const pmin = s.pmin === '' ? null : +s.pmin, pmax = s.pmax === '' ? null : +s.pmax;
    const ql = s.q.trim().toLowerCase();
    const catList = I.filter(i => {
      if (s.cat === 'Featured') { if (s.sub === 'New' && !i.nw) return false; if (s.sub === 'Trending' && !i.tr) return false; }
      else if (s.cat === 'Halloween') { if (!i.h) return false; if (s.sub !== 'All' && i.m !== s.sub) return false; }
      else { if (i.m !== s.cat) return false; if (s.sub !== 'All' && i.sub !== s.sub) return false; }
      return (!ql || i.n.toLowerCase().includes(ql)) && (s.colour === 'Any' || i.col === s.colour) && (pmin == null || i.p >= pmin) && (pmax == null || i.p <= pmax);
    });
    const meta = {
      '5a': { title: 'HUD', note: 'The basket badge now shows the explicit basket total. Tap your avatar in the world to open Wearing.' },
      '5b': { title: 'Catalogue: badges + price range', note: 'An orange checkroom badge means you are wearing it. A white basket badge means it is in your basket. The menu is Try · basket toggle · Buy · View. The price popover is a two-handle slider with presets, and the grid updates live as you drag.' },
      '5h': { title: 'Stores home (no category selected)', note: 'The default state. Each category gets its own carousel, Netflix-style. See all, or tapping a tab, selects that category as a grid. Tap the selected tab again to come back here.' },
      '5c': { title: 'Store page', note: 'A vertical column of horizontal sections: a featured item viewer with arrows, Bestsellers and New arrivals carousels (swipe), and collection tiles that open their own grid. Favourite and Share sit in the header.' },
      '5d': { title: 'Outfit screen', note: 'Large preview, Wear all, then every item with checkboxes for a partial wear, add to basket or buy. Tap a row to open the item screen; the breadcrumb (Outfits › Neon Rider › …) brings you back.' },
      '5e': { title: 'Share (outfit or store)', note: 'Tap Share, then Reveal code. You get a copyable code and a QR that deep-links back to this screen in the game. The code also works in the Outfits and Stores search.' },
      '5f': { title: 'Basket screen', note: 'The explicit basket. Try each item on or remove it, see a summary, Buy all through the Roblox prompt, try everything on, or pull in what you are wearing.' },
      '5g': { title: 'Wearing screen', note: 'What is on the avatar right now, with owned or price for each item. Move unowned items to the basket, save the look as an outfit, or take everything off.' }
    };
    const icons = { Catalogue: 'apparel', Stores: 'storefront', Outfits: 'checkroom' };
    const frames = Object.keys(meta).map(id => {
      const u = s.ui[id], stack = u.stack || [], topE = stack[stack.length - 1];
      const push = e => this.setUI(id, { stack: [...stack, e], menu: null, filt: null, osel: null });
      const popTo = n => this.setUI(id, { stack: stack.slice(0, n), menu: null, osel: null });
      const card = (i, ctx) => {
        const key = ctx + ':' + i.id, on = worn.has(i.id), inB = bset.has(i.id);
        return { ...pInfo(i), name: i.n, label: i.sub.toLowerCase(), tint: tint(i), wearing: on, inBasket: inB, menu: u.menu === key,
          tryLabel: on ? 'Take off' : 'Try', tryIcon: on ? 'remove' : 'checkroom',
          basketIcon: inB ? 'remove_shopping_cart' : 'add_shopping_cart', basketLabel: inB ? 'Remove from basket' : 'Add to basket',
          buyLabel: owned(i) ? 'Owned' : i.p === 0 ? 'Get' : 'Buy',
          onClick: () => this.setUI(id, { menu: u.menu === key ? null : key, filt: null }),
          tryIt: e => { e.stopPropagation(); this.setUI(id, { menu: null }); toggleWear(i, id); },
          basketIt: e => { e.stopPropagation(); toggleBasket(i, id); },
          buyIt: e => { e.stopPropagation(); openBuy(id, [i]); },
          viewIt: e => { e.stopPropagation(); push({ t: 'item', i: i.id }); } };
      };
      const entryName = e => e.t === 'item' ? I[e.i].n : e.t === 'store' ? this.STORES[e.i][0] : e.t === 'coll' ? e.name : (this.getOutfit(e.src, e.i) || {}).n;
      const rootLabel = u.full === 'Outfits' && topE ? 'Outfits' : u.full;
      const isList = u.full === 'Basket' || u.full === 'Wearing';
      const crumbs = [{ label: rootLabel, sep: false, onClick: () => popTo(0) }, ...stack.map((e, n) => ({ label: entryName(e), sep: true, onClick: () => popTo(n + 1) }))]
        .map((c, n, a) => ({ ...c, color: n === a.length - 1 ? '#fff' : 'rgba(255,255,255,.6)', weight: n === a.length - 1 ? 900 : 800 }));
      const r = {
        id, ...meta[id],
        tabs: Object.keys(icons).map(label => ({ label, icon: icons[label], bg: u.full === label ? OR : BK, onClick: () => this.setUI(id, { full: label, stack: [], menu: null, filt: null, world: false }) })),
        actions: [{ label: 'Create avatar', icon: 'person_add', onClick: () => this.toast(id, 'Create avatar') }, { label: 'Save to Roblox', icon: 'cloud_upload', onClick: () => this.toast(id, 'Saved to Roblox') }, { label: 'Reset', icon: 'restart_alt', onClick: () => this.toast(id, 'Reset to your avatar') }],
        openBasket: () => this.setUI(id, { full: 'Basket', stack: [], world: false, menu: null }),
        openWearing: () => this.setUI(id, { full: 'Wearing', stack: [], world: false, menu: null }),
        wearBorder: u.full === 'Wearing' ? '#ff8a1a' : 'rgba(255,255,255,.14)', basketBorder: u.full === 'Basket' ? '#ff8a1a' : 'rgba(255,255,255,.12)',
        worldOpen: !!u.world && !u.full, worldBg: u.world ? OR : BK, toggleWorld: () => this.setUI(id, { world: !u.world }),
        fullOpen: !!u.full, closeFull: () => this.setUI(id, { full: null, stack: [], menu: null, filt: null }),
        hasCrumbs: stack.length > 0 || isList, canBack: stack.length > 0, back: () => popTo(stack.length - 1), crumbs,
        isCatRoot: u.full === 'Catalogue' && !topE, isStoreRoot: u.full === 'Stores' && !topE, isOutfitRoot: u.full === 'Outfits' && !topE,
        isItem: topE && topE.t === 'item', isStore: topE && topE.t === 'store', isColl: topE && topE.t === 'coll', isOutfit: topE && topE.t === 'outfit',
        isBasket: u.full === 'Basket' && !topE, isWearing: u.full === 'Wearing' && !topE,
        undo: e => { e.stopPropagation(); this.toast(id, 'Undone'); },
        colourOpen: u.filt === 'colour', priceOpen: u.filt === 'price', closeFilt: () => this.setUI(id, { filt: null }),
        colourBtnBg: u.filt === 'colour' || s.colour !== 'Any' ? OR : BK, priceBtnBg: u.filt === 'price' || pmin != null || pmax != null ? OR : BK,
        openColour: () => this.setUI(id, { filt: u.filt === 'colour' ? null : 'colour', menu: null }),
        openPrice: () => this.setUI(id, { filt: u.filt === 'price' ? null : 'price', menu: null }),
        colours: ['Any', ...Object.keys(this.COL)].map(c => ({ label: c, text: c === 'Any' ? 'Any' : '', bg: c === 'Any' ? '#333' : this.COL[c], ring: s.colour === c ? '0 0 0 2px #111,0 0 0 4px #ffa64d' : '0 0 0 1px #000', onClick: () => { this.setState({ colour: c }); this.setUI(id, { filt: null }); } })),
        buyOpen: !!u.buy, buy: u.buy || {}, closeBuy: () => this.setUI(id, { buy: null }),
        confirmBuy: () => { const b = u.buy; this.setState(st => ({ owned: [...st.owned, ...b.ids], basket: st.basket.filter(x => !b.ids.includes(x)) })); this.setUI(id, { buy: null }); this.toast(id, b.ids.length === 1 ? 'Purchased ' + I[b.ids[0]].n : 'Purchased ' + b.ids.length + ' items'); },
        toast: u.toast || null, v: {}, st: {}, ov: {}, sh: {}
      };
      r.cards = r.isCatRoot ? catList.map(i => card(i, 'g')) : [];
      if (r.isItem) {
        const i = I[topE.i], on = worn.has(i.id), inB = bset.has(i.id), fav = s.favs.includes(i.id);
        r.v = { ...pInfo(i), name: i.n, main: i.m, sub: i.sub, creator: i.cr, colour: i.col, tint: tint(i), wearing: on, inBasket: inB, favs: (i.favs + (fav ? 1 : 0)).toLocaleString(),
          tryLabel: on ? 'Take off' : 'Try on', tryIcon: on ? 'remove' : 'checkroom', basketLabel: inB ? 'In basket' : 'Add to basket', basketIcon: inB ? 'remove_shopping_cart' : 'add_shopping_cart',
          buyLabel: owned(i) ? 'Owned' : i.p === 0 ? 'Get free' : 'Buy ' + i.p,
          tryIt: () => toggleWear(i, id), basketIt: () => toggleBasket(i, id), buyIt: () => openBuy(id, [i]),
          fav: () => this.setState(st => ({ favs: fav ? st.favs.filter(x => x !== i.id) : [...st.favs, i.id] })), favColor: fav ? '#ffa64d' : '#fff',
          more: I.filter(x => x.id !== i.id && x.m === i.m).sort((a, b) => (b.sub === i.sub) - (a.sub === i.sub)).slice(0, 6).map(x => ({ ...card(x, 'm'), viewIt: e => { e.stopPropagation(); this.setUI(id, { stack: [...stack.slice(0, -1), { t: 'item', i: x.id }], menu: null }); } })) };
      }
      const sq = s.sq.trim().toLowerCase();
      const storeList = sort => {
        if (sort === 'My stores') return [{ isCreate: true, isStore: false, name: 'Create store', meta: 'Sell your own items', onClick: () => this.toast(id, 'Create store') }, { isStore: true, isCreate: false, name: 'My Store', meta: 'Unpublished', onClick: () => push({ t: 'store', i: 15 }) }];
        let list = this.STORES.map(([n, rt, vv, fl], i) => ({ i, n, rt, vv, ad: (fl || '').includes('s'), fav: s.favStores.includes(i) }));
        if (sort === 'Sponsored') list = list.filter(x => x.ad);
        if (sort === 'Favourites') list = list.filter(x => x.fav);
        if (sort === 'Popular') list.sort((a, b) => b.vv - a.vv);
        if (sort === 'Top rated') list.sort((a, b) => b.rt - a.rt);
        return list.filter(x => !sq || x.n.toLowerCase().includes(sq) || this.code('STR', x.n).toLowerCase() === sq).map(x => ({ isStore: true, isCreate: false, name: x.n, meta: x.rt + '% liked · ' + fmtN(x.vv), fav: x.fav, ad: x.ad && sort === 'Sponsored', onClick: () => push({ t: 'store', i: x.i }) }));
      };
      r.storeHome = r.isStoreRoot && !s.storeSort; r.storeGrid = r.isStoreRoot && !!s.storeSort;
      r.storeRows = r.storeHome ? ['Sponsored', 'Popular', 'Top rated', 'Favourites', 'My stores'].map(c => ({ title: c, cards: storeList(c).slice(0, 10), seeAll: () => this.setState({ storeSort: c }) })).filter(x => x.cards.length) : [];
      if (r.isStoreRoot && s.storeSort) r.stores = storeList(s.storeSort);
      else if (false) {
        if (s.storeSort === 'My stores') r.stores = [{ isCreate: true, isStore: false, name: 'Create store', meta: 'Sell your own items', onClick: () => this.toast(id, 'Create store') }, { isStore: true, isCreate: false, name: 'My Store', meta: 'Unpublished', onClick: () => push({ t: 'store', i: 15 }) }];
        else {
          let list = this.STORES.map(([n, rt, vv, fl], i) => ({ i, n, rt, vv, ad: (fl || '').includes('s'), fav: s.favStores.includes(i) }));
          if (s.storeSort === 'Sponsored') list = list.filter(x => x.ad);
          if (s.storeSort === 'Favourites') list = list.filter(x => x.fav);
          if (s.storeSort === 'Popular') list.sort((a, b) => b.vv - a.vv);
          if (s.storeSort === 'Top rated') list.sort((a, b) => b.rt - a.rt);
          r.stores = list.filter(x => !sq || x.n.toLowerCase().includes(sq) || this.code('STR', x.n).toLowerCase() === sq).map(x => ({ isStore: true, isCreate: false, name: x.n, meta: x.rt + '% liked · ' + fmtN(x.vv), fav: x.fav, ad: x.ad && s.storeSort === 'Sponsored', onClick: () => push({ t: 'store', i: x.i }) }));
        }
      } else r.stores = [];
      if (r.isStore || r.isColl) {
        const si = topE.t === 'store' ? topE.i : topE.store, [sn, srt, svv] = this.STORES[si], items = this.storeItems(si), fav = s.favStores.includes(si);
        const colls = [{ name: 'Under 50', f: i => i.p < 50 }, { name: 'Halloween drop', f: i => i.h }, { name: 'Full looks', f: i => i.m === 'Clothing' }, { name: 'Accessories', f: i => i.m === 'Accessories' }].map(c => ({ ...c, items: items.filter(c.f) })).filter(c => c.items.length).slice(0, 3);
        if (r.isStore) {
          const feat = items.filter(i => i.tr || i.p > 70).slice(0, 4).concat(items).slice(0, 4), hi = (u.hero || 0) % feat.length, h = feat[hi], hon = worn.has(h.id), hb = bset.has(h.id);
          r.st = { name: sn, creator: this.CREATORS[si % 6], rating: srt, visits: fmtN(svv), favColor: fav ? '#ffa64d' : '#fff', favLabel: fav ? 'Favourited' : 'Favourite',
            fav: () => this.setState(st2 => ({ favStores: fav ? st2.favStores.filter(x => x !== si) : [...st2.favStores, si] })),
            share: () => this.setUI(id, { share: { kind: 'store', si }, revealed: false }),
            sections: [
              { title: 'Featured', isHero: true, isRow: false, isColl: false, seeAll: null, hero: { ...pInfo(h), name: h.n, tint: tint(h), pos: (hi + 1) + ' / ' + feat.length,
                tryLabel: hon ? 'Take off' : 'Try on', tryIcon: hon ? 'remove' : 'checkroom', basketLabel: hb ? 'In basket' : 'Basket', basketIcon: hb ? 'remove_shopping_cart' : 'add_shopping_cart',
                tryIt: () => toggleWear(h, id), basketIt: () => toggleBasket(h, id), view: () => push({ t: 'item', i: h.id }),
                prev: () => this.setUI(id, { hero: (hi + feat.length - 1) % feat.length }), next: () => this.setUI(id, { hero: (hi + 1) % feat.length }) } },
              { title: 'Bestsellers', isRow: true, isHero: false, isColl: false, cards: [...items].sort((a, b) => b.favs - a.favs).slice(0, 10).map(i => card(i, 'b')), seeAll: () => push({ t: 'coll', store: si, name: 'Bestsellers', all: 'best' }) },
              { title: 'New arrivals', isRow: true, isHero: false, isColl: false, cards: [...items].reverse().slice(0, 10).map(i => card(i, 'n')), seeAll: () => push({ t: 'coll', store: si, name: 'New arrivals', all: 'new' }) },
              { title: 'Collections', isColl: true, isRow: false, isHero: false, seeAll: null, colls: colls.map((c, n) => ({ name: c.name, count: c.items.length + ' items', bg: ['linear-gradient(135deg,rgba(255,138,26,.45),#1c1c1c)', 'linear-gradient(135deg,rgba(139,92,246,.45),#1c1c1c)', 'linear-gradient(135deg,rgba(59,130,246,.45),#1c1c1c)'][n], onClick: () => push({ t: 'coll', store: si, name: c.name }) })) }
            ] };
        } else {
          const c = colls.find(c => c.name === topE.name);
          const list = topE.all === 'best' ? [...items].sort((a, b) => b.favs - a.favs) : topE.all === 'new' ? [...items].reverse() : c ? c.items : items;
          r.collCards = list.map(i => card(i, 'c'));
        }
      }
      if (r.isOutfit) {
        const ofit = this.getOutfit(topE.src, topE.i) || { n: '', by: '', items: [] };
        const sel = u.osel || ofit.items, selSet = new Set(sel), selItems = ofit.items.filter(x => selSet.has(x)).map(x => I[x]);
        const unownedSel = selItems.filter(i => !owned(i)), cost = unownedSel.reduce((a, i) => a + i.p, 0);
        const allOn = ofit.items.length && ofit.items.every(x => worn.has(x));
        r.ov = { name: ofit.n, by: ofit.by, ring: allOn ? 'inset 0 0 0 2px #ff8a1a' : 'inset 0 0 0 1px rgba(255,255,255,.12)',
          countLabel: ofit.items.length + ' items · ' + sel.length + ' selected', toggleAllLabel: sel.length === ofit.items.length ? 'Select none' : 'Select all',
          toggleAll: () => this.setUI(id, { osel: sel.length === ofit.items.length ? [] : [...ofit.items] }),
          wearAll: () => { this.setState({ worn: [...ofit.items] }); this.toast(id, 'Wearing ' + ofit.n); },
          wearSel: () => { if (!selItems.length) return this.toast(id, 'Select some items first'); this.setState(st => { let w = { worn: st.worn }; selItems.forEach(i => { w = { worn: wearOne(w, i) }; }); return w; }); this.toast(id, 'Wearing ' + selItems.length + ' items'); },
          basketSel: () => { const add = unownedSel.filter(i => !bset.has(i.id)); this.setState(st => ({ basket: [...st.basket, ...add.map(i => i.id)] })); this.toast(id, add.length ? 'Added ' + add.length + ' to basket' : 'Nothing new to add'); },
          buySel: () => openBuy(id, selItems), buyLabel: cost ? 'Buy · ' + cost : 'Buy',
          share: () => this.setUI(id, { share: { kind: 'outfit', src: topE.src, i: topE.i }, revealed: false }),
          rows: ofit.items.map(x => { const i = I[x], on = selSet.has(x); return { ...pInfo(i), name: i.n, tint: tint(i), wearing: worn.has(x), inBasket: bset.has(x), checkBg: on ? OR : '#111', checkOp: on ? 1 : 0,
            toggle: () => this.setUI(id, { osel: on ? sel.filter(y => y !== x) : [...sel, x] }), open: () => push({ t: 'item', i: x }) }; }) };
      }
      if (r.isOutfitRoot) {
        const oql = s.oq.trim().toLowerCase();
        const match = (n) => !oql || n.toLowerCase().includes(oql) || this.code('OUT', n).toLowerCase() === oql;
        const oc = (n, sub, items, src, i) => ({ isOutfit: true, isSave: false, name: n, sub, ring: items.length === worn.size && items.every(x => worn.has(x)) ? 'inset 0 0 0 2px #ff8a1a,0 0 10px rgba(255,138,26,.55)' : 'inset 0 0 0 1px rgba(255,255,255,.1)', onClick: () => push({ t: 'outfit', src, i }) });
        if (s.osrc === 'Mine') r.outfitCards = [{ isSave: true, isOutfit: false, name: 'New outfit', sub: worn.size + ' items', onClick: () => { this.setState(st => ({ mine: [...st.mine, { n: 'Outfit ' + (st.mine.length + 1), items: [...st.worn] }] })); this.toast(id, 'Saved what you\'re wearing'); } }, ...s.mine.map((m, i) => ({ m, i })).filter(x => match(x.m.n)).map(({ m, i }) => oc(m.n, m.items.length + ' items', m.items, 'Mine', i))];
        else if (s.osrc === 'Community') r.outfitCards = this.COMMUNITY.map((c, i) => ({ c, i })).filter(x => match(x.c[0])).map(({ c, i }) => oc(c[0], 'by ' + c[1], c[2], 'Community', i));
        else r.outfitCards = this.ROBLOX.map(([n, it], i) => oc(n, oql ? 'from ' + s.oq.trim() : 'saved on Roblox', it, 'Roblox', i));
      } else r.outfitCards = [];
      r.basketRows = s.basket.map(x => { const i = I[x], on = worn.has(x); return { ...pInfo(i), name: i.n, sub: i.m + ' · ' + i.sub + ' · by ' + i.cr, tint: tint(i), tryLabel: on ? 'Wearing' : 'Try on', tryBg: on ? OR : BK, tryIt: () => toggleWear(i, id), remove: () => toggleBasket(i, id), open: () => push({ t: 'item', i: x }) }; });
      const bItems = s.basket.map(x => I[x]);
      r.buyBasket = () => openBuy(id, bItems);
      r.tryBasket = () => { if (!bItems.length) return this.toast(id, 'Basket is empty'); this.setState(st => { let w = { worn: st.worn }; bItems.forEach(i => { w = { worn: wearOne(w, i) }; }); return w; }); this.toast(id, 'Trying on your basket'); };
      const unownedWorn = s.worn.map(x => I[x]).filter(i => !owned(i));
      r.wornToBasket = () => { const add = unownedWorn.filter(i => !bset.has(i.id)); this.setState(st => ({ basket: [...st.basket, ...add.map(i => i.id)] })); this.toast(id, add.length ? 'Added ' + add.length + ' to basket' : 'Nothing new to add'); };
      r.unownedToBasket = r.wornToBasket;
      r.wornRows = s.worn.map(x => { const i = I[x], inB = bset.has(x); return { ...pInfo(i), name: i.n, sub: i.m + ' · ' + i.sub, tint: tint(i), canBasket: !owned(i), basketLabel: inB ? 'In basket' : 'Add to basket', basketIcon: inB ? 'remove_shopping_cart' : 'add_shopping_cart', basketBg: inB ? OR : BK, basketIt: () => toggleBasket(i, id), takeOff: () => toggleWear(i, id), open: () => push({ t: 'item', i: x }) }; });
      r.saveOutfit = () => { this.setState(st => ({ mine: [...st.mine, { n: 'Outfit ' + (st.mine.length + 1), items: [...st.worn] }] })); this.toast(id, 'Saved to your outfits'); };
      r.takeOffAll = () => { this.setState({ worn: [] }); this.toast(id, 'Took everything off'); };
      r.shareOpen = !!u.share; r.closeShare = () => this.setUI(id, { share: null });
      if (u.share) {
        const sh = u.share, name = sh.kind === 'store' ? this.STORES[sh.si][0] : (this.getOutfit(sh.src, sh.i) || {}).n, code = this.code(sh.kind === 'store' ? 'STR' : 'OUT', name);
        r.sh = { title: sh.kind === 'store' ? 'Share store' : 'Share outfit', kind: sh.kind, where: sh.kind === 'store' ? 'Stores' : 'Outfits', name,
          hidden: !u.revealed, code: u.revealed ? code : '•••-••••••', cells: this.qr(code), qrBlur: u.revealed ? 'none' : 'blur(5px)',
          actionLabel: u.revealed ? (u.copied ? 'Copied' : 'Copy') : 'Reveal code', actionIcon: u.revealed ? (u.copied ? 'check' : 'content_copy') : 'visibility',
          action: () => { if (!u.revealed) return this.setUI(id, { revealed: true, copied: false }); try { navigator.clipboard.writeText(code); } catch (e) {} this.setUI(id, { copied: true }); } };
      }
      return r;
    });
    const textTab = (label, active, onClick) => ({ label, onClick, color: active ? '#fff' : 'rgba(255,255,255,.55)', line: active ? 'inset 0 -3px 0 #ff8a1a' : 'none' });
    const bOwnedN = s.basket.filter(x => owned(I[x])).length, bTotal = s.basket.map(x => I[x]).filter(i => !owned(i)).reduce((a, i) => a + i.p, 0);
    const wUn = s.worn.map(x => I[x]).filter(i => !owned(i));
    const presets = [['Free', '', '0'], ['Under 50', '', '45'], ['50–100', '50', '100'], ['100+', '100', '']];
    return {
      frames, stop: e => e.stopPropagation(), skyBg, sceneFilter: `brightness(${(s.bright / 100) * lit})`,
      starsOp: open ? Math.max(0, 1 - day * 2.2) : (s.sky === 'Void' ? 0.6 : 0), cloudsOp: s.sky === 'Clouds' ? 0.5 + 0.5 * day : 0,
      orbLeft: (10 + p * 80) + '%', orbTop: (46 - Math.sin(Math.PI * p) * 36) + '%', orbColor: isSun ? '#fff4c8' : '#e6eaff', orbGlow: isSun ? 'rgba(255,220,140,.7)' : 'rgba(200,210,255,.35)', orbOp: open ? 1 : 0,
      floorBg: pat + s.floor, hazeColor: s.sky === 'Void' ? 'rgba(0,0,0,0)' : 'rgba(255,255,255,.28)', shadowOp: s.shadows ? (0.25 + 0.6 * day) : 0,
      time: t, timeLabel: fmt(t), bright: s.bright,
      setTime: e => this.setState({ time: +e.target.value }), setBright: e => this.setState({ bright: +e.target.value }),
      skies: ['Clear', 'Clouds', 'Studio', 'Void'].map(label => ({ label, bg: s.sky === label ? OR : BK, onClick: () => this.setState({ sky: label }) })),
      floors: ['#ff7a00', '#1c1c1e', '#e9e6e1', '#3fbf8a', '#7a5cff'].map(c => ({ c, ring: s.floor === c ? '0 0 0 2px #111,0 0 0 4px #ffa64d' : '0 0 0 1px #000', onClick: () => this.setState({ floor: c }) })),
      patterns: ['Grid', 'Checker', 'Plain'].map(label => ({ label, bg: s.pattern === label ? OR : BK, onClick: () => this.setState({ pattern: label }) })),
      toggleShadows: () => this.setState({ shadows: !s.shadows }), shadowsTrack: s.shadows ? OR : '#222', shadowsKnob: s.shadows ? '24px' : '2px',
      basketBadge: bTotal > 0 ? String(bTotal) : null, basketCountLabel: s.basket.length + ' items', basketCta: bTotal > 0 ? 'Open basket · ' + bTotal + ' R$' : 'Open basket',
      basketN: s.basket.length, basketOwnedN: bOwnedN, basketTotal: bTotal, basketEmpty: s.basket.length === 0,
      wornCount: s.worn.length, wornEmpty: s.worn.length === 0, wornUnownedN: wUn.length, wornUnownedCost: wUn.reduce((a, i) => a + i.p, 0),
      q: s.q, setQ: e => this.setState({ q: e.target.value }),
      catTabs: Object.keys(this.SUBS).map(c => textTab(c, s.cat === c, () => this.setState({ cat: c, sub: 'All' }))),
      subTabs: this.SUBS[s.cat].map(c => ({ label: c, onClick: () => this.setState({ sub: c }), color: s.sub === c ? '#ffb36b' : 'rgba(255,255,255,.75)', bg: s.sub === c ? 'rgba(255,138,26,.16)' : 'transparent', border: s.sub === c ? 'rgba(255,138,26,.65)' : 'rgba(255,255,255,.14)' })),
      catEmpty: catList.length === 0, catCountLabel: catList.length + ' items match',
      colourSwatch: s.colour === 'Any' ? 'conic-gradient(#ff7a00,#ff5fa8,#8b5cf6,#3b82f6,#3fbf6a,#ff7a00)' : this.COL[s.colour], colourLabel: s.colour === 'Any' ? 'Colour' : s.colour,
      priceLabel: pmin == null && pmax == null ? 'Price' : pmin != null && pmax != null ? (pmin === pmax ? String(pmin) : pmin + '–' + pmax) : pmin != null ? pmin + '+' : pmax === 0 ? 'Free' : 'Up to ' + pmax,
      pminV: pmin == null ? 0 : pmin, pmaxV: pmax == null ? 400 : pmax, pminText: pmin == null ? '0' : String(pmin), pmaxText: pmax == null ? 'Any' : String(pmax),
      pFillL: ((pmin == null ? 0 : pmin) / 4) + '%', pFillR: (100 - (pmax == null ? 400 : pmax) / 4) + '%',
      setPmin: e => { const v = Math.min(+e.target.value, pmax == null ? 400 : pmax); this.setState({ pmin: v <= 0 ? '' : String(v) }); },
      setPmax: e => { const v = Math.max(+e.target.value, pmin == null ? 0 : pmin); this.setState({ pmax: v >= 400 ? '' : String(v) }); }, clearPrice: () => this.setState({ pmin: '', pmax: '' }),
      pricePresets: presets.map(([label, a, b]) => { const on = s.pmin === a && s.pmax === b; return { label, onClick: () => this.setState({ pmin: a, pmax: b }), color: on ? '#ffb36b' : 'rgba(255,255,255,.8)', bg: on ? 'rgba(255,138,26,.16)' : 'transparent', border: on ? 'rgba(255,138,26,.65)' : 'rgba(255,255,255,.18)' }; }),
      sq: s.sq, setSq: e => this.setState({ sq: e.target.value }),
      storeTabs: ['Sponsored', 'Popular', 'Top rated', 'Favourites', 'My stores'].map(c => textTab(c, s.storeSort === c, () => this.setState({ storeSort: s.storeSort === c ? null : c }))),
      oq: s.oq, setOq: e => this.setState({ oq: e.target.value }), outfitPh: s.osrc === 'Roblox' ? 'Search a username' : 'Search or enter outfit code',
      outfitTabs: ['Mine', 'Community', 'Roblox'].map(c => textTab(c, s.osrc === c, () => this.setState({ osrc: c })))
    };
  }
}

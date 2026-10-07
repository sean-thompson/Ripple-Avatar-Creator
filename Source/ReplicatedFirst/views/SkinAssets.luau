--!strict

--[[
	SkinAssets

	The single home for HUD image asset IDs.

	Icons: one white-fill 128px image per Material Symbols Rounded glyph,
	tinted at runtime with ImageColor3. Source PNGs: assets/ui/icons/, built by
	tools/build_icons.py from the design's icon font. To add an icon: add
	it to the script's ICONS list, rebuild, upload the PNG via Studio's Asset
	Manager, and add its IMAGE asset ID (not a Decal ID) below.

	An icon with no ID renders a deliberately ugly placeholder so missing art
	is obvious.
]]

local SkinAssets = {}

SkinAssets.icons = {
	add_business = 97532956820465,
	add_circle = 135005117071279,
	add_shopping_cart = 82527124583124,
	apparel = 94177734376541,
	arrow_back = 121766949760746,
	bookmark_add = 86911205794599,
	check = 88158457528017,
	check_circle = 92221501449673,
	checkroom = 78096217583635,
	chevron_left = 123626147887091,
	chevron_right = 114670021870771,
	close = 139136293752542,
	cloud_upload = 91562809650291,
	content_copy = 101027253209192,
	delete = 101639546014495,
	delete_sweep = 96618116522731,
	expand_less = 123341703772881,
	flight = 71395858478083,
	ios_share = 90787313571068,
	landscape = 93716528650433,
	link = 109659227478159,
	lock = 74847788561694,
	person_add = 98841581564997,
	remove = 90125229559734,
	remove_shopping_cart = 128883588652032,
	restart_alt = 89689435225163,
	search = 113580527499154,
	shopping_basket = 99889459944389,
	star = 138473232558734,
	storefront = 126209902090800,
	toll = 108231234324649,
	undo = 138050190849416,
	visibility = 95037949648164,
} :: { [string]: number }

-- "rbxassetid://..." for an icon name, or nil if it has no art yet.
function SkinAssets.iconImage(name: string): string?
	local id = SkinAssets.icons[name]
	if id == nil then
		return nil
	end
	return "rbxassetid://" .. id
end

-- Every icon name with an ID, sorted (for galleries).
function SkinAssets.iconNames(): { string }
	local names = {}
	for name in SkinAssets.icons do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return SkinAssets

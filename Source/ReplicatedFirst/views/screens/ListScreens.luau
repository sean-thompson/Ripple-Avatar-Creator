--!strict

--[[
	ListScreens (design frames 5f Basket / 5g Wearing, placeholder data)

	Basket: one row per item (Try on / Remove), a summary (items, already owned,
	total) with Buy all, Try on everything, Add what I'm wearing (the unowned
	worn items not already in it) and Remove all (press twice). Wearing: what's on the avatar
	(price or Owned, Basket toggle, Take off) with Buy all (the unowned ones),
	Add unowned to basket, Save as outfit and Take everything off (press twice). Rows open the item page.

	Buy / Get and Buy all open Roblox's purchase prompt; Save as outfit saves
	the look to Outfits › Mine.

	ListScreens.Basket / ListScreens.Wearing props: nav, look
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local PillButton = require(components:WaitForChild("PillButton"))
local ConfirmButton = require(components:WaitForChild("ConfirmButton"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))
local HudContext = require(views:WaitForChild("HudContext"))

local e = React.createElement

local SIDE_WIDTH = 250
local ROW_BUTTON = 84 -- design px per row button
-- Price + up to three buttons on the right of each row.
local ROW_TRAILING = 60 + ROW_BUTTON * 3 + 8 * 3

-- Buy (or Get, when free) for an item that isn't owned; nil when it is.
local function buyButton(item: any, order: number, hud: any)
	if item.owned then
		return nil
	end
	return e(PillButton, {
		variant = "pill",
		size = 32,
		width = ROW_BUTTON,
		label = if item.price == 0 then "Get" else "Buy",
		textStyle = Tokens.type.small,
		active = true,
		loading = hud.buying("item:" .. item.id),
		layoutOrder = order,
		onActivated = function()
			hud.buy({ item.id })
		end,
	})
end

local function smallButton(label: string, order: number, active: boolean?, onActivated: () -> ())
	return e(PillButton, {
		variant = "pill",
		size = 32,
		width = ROW_BUTTON,
		label = label,
		textStyle = Tokens.type.small,
		active = active,
		sound = false, -- row actions change the look, which plays its own sound
		layoutOrder = order,
		onActivated = onActivated,
	})
end

local function rowList(skin, rows: { [string]: any }, count: number, emptyText: string)
	if count == 0 then
		return e("Frame", {
			Size = UDim2.new(1, -skin.px(SIDE_WIDTH + 16), 1, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Text = e(ShadowText, { text = emptyText, style = Tokens.type.cardTitle, transparency = Tokens.alpha.textDim, shadow = false }),
		})
	end
	rows.Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(8)) })
	-- Inset so row strokes at the edges aren't clipped by the ScrollingFrame.
	rows.Inset = e("UIPadding", {
		PaddingTop = UDim.new(0, skin.px(3)),
		PaddingBottom = UDim.new(0, skin.px(3)),
		PaddingLeft = UDim.new(0, skin.px(3)),
		PaddingRight = UDim.new(0, skin.px(8)),
	})
	return e("ScrollingFrame", {
		Size = UDim2.new(1, -skin.px(SIDE_WIDTH + 16), 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, count * (skin.px(64) + skin.px(8)) + skin.px(6)),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = skin.px(8),
		ScrollBarImageColor3 = Tokens.color.accent,
		-- Rows shrink to make room when the scroll bar shows (plus the padding
		-- above), so they never run under it.
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	}, rows)
end

local function summaryLine(skin, label: string, value: string, order: number, strong: boolean?)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, skin.px(22)),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Label = e(ShadowText, {
			text = label,
			style = if strong then Tokens.type.bodyStrong else Tokens.type.meta,
			transparency = if strong then 0 else Tokens.alpha.textSoft,
			shadow = false,
		}),
		Value = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = value,
			TextColor3 = if strong then Tokens.color.accentText else Tokens.color.white,
			TextSize = skin.textPx(if strong then 16 else 14),
			FontFace = Tokens.font(900),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top, -- line up with the label
		}),
	})
end

local function sidePanel(skin, title: string, lines: { any }, buttons: { any })
	local children: { [string]: any } = {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(14)),
			PaddingBottom = UDim.new(0, skin.px(14)),
			PaddingLeft = UDim.new(0, skin.px(14)),
			PaddingRight = UDim.new(0, skin.px(14)),
		}),
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(8)) }),
		Title = e(ShadowText, { text = title, style = Tokens.type.cardTitle, layoutOrder = 0 }),
	}
	for index, line in lines do
		children["Line" .. index] = line
	end
	for index, button in buttons do
		children["Button" .. index] = button
	end
	return e(GlassPanel, {
		variant = "light",
		cornerRadius = Tokens.radius.basketCard,
		anchorPoint = Vector2.new(1, 0),
		position = UDim2.fromScale(1, 0),
		size = UDim2.new(0, skin.px(SIDE_WIDTH), 1, 0),
	}, children)
end

local function wideButton(
	label: string,
	icon: string?,
	order: number,
	active: boolean?,
	onActivated: (() -> ())?,
	sound: any?,
	disabled: boolean?,
	loading: boolean?
)
	return e(PillButton, {
		variant = "pill",
		size = Tokens.size.ctaHeight,
		label = label,
		icon = icon,
		iconSize = 18,
		active = active,
		sound = sound,
		disabled = disabled,
		loading = loading,
		layoutOrder = order,
		onActivated = onActivated,
	})
end

-- Save as outfit: saves what's worn, then reads "Saved to Outfits" for a
-- moment (the new outfit is in Outfits › Mine; no toast).
local SAVED_SECONDS = 2

local function SaveOutfitButton(props: { look: any, layoutOrder: number })
	local saved, setSaved = React.useState(false)
	React.useEffect(function()
		if not saved then
			return nil
		end
		local thread = task.delay(SAVED_SECONDS, function()
			setSaved(false)
		end)
		return function()
			task.cancel(thread)
		end
	end, { saved })
	return e(PillButton, {
		variant = "pill",
		size = Tokens.size.ctaHeight,
		label = if saved then "Saved to Outfits" else "Save as outfit",
		icon = if saved then "check" else "bookmark_add",
		iconSize = 18,
		sound = false, -- saving plays its own sound
		disabled = #props.look.worn == 0,
		layoutOrder = props.layoutOrder,
		onActivated = function()
			if not saved and props.look.saveOutfit() then
				setSaved(true)
			end
		end,
	})
end

local function BasketScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local hud = React.useContext(HudContext)
	local look = props.look
	local rows: { [string]: any } = {}
	local owned = 0
	-- Worn items that could go in: not owned, not already there.
	local wornToAdd = {}
	for _, id in look.worn do
		local item = PlaceholderData.item(id)
		if item and not item.owned and not look.inBasket(id) then
			table.insert(wornToAdd, id)
		end
	end
	for index, id in look.basket do
		local item = PlaceholderData.item(id)
		if item.owned then
			owned += 1
		end
		local wearing = look.isWorn(id)
		rows["Row" .. id] = e(Parts.ListRow, {
			title = item.name,
			subtitle = item.main .. " · " .. item.sub .. " · by " .. item.creator,
			colour = Parts.swatch(item.colour),
			image = Parts.image(item),
			layoutOrder = index,
			trailingWidth = ROW_TRAILING,
			trailing = {
				Price = e(Parts.PriceTag, { item = item, size = 14, layoutOrder = 1 }),
				Buy = buyButton(item, 2, hud),
				Try = smallButton(if wearing then "Wearing" else "Try on", 3, wearing, function()
					look.toggleWear(id)
				end),
				Remove = smallButton("Remove", 4, false, function()
					look.toggleBasket(id)
				end),
			},
			onActivated = function()
				props.nav.push({ kind = "item", id = id, label = item.name })
			end,
		})
	end

	return e("Frame", {
		Name = "BasketScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Rows = rowList(skin, rows, #look.basket, "Your basket is empty"),
		Summary = sidePanel(skin, "Summary", {
			summaryLine(skin, "Items", tostring(#look.basket), 1),
			summaryLine(skin, "Already owned", tostring(owned), 2),
			summaryLine(skin, "Total", Tokens.robux(look.basketTotal), 3, true),
		}, {
			wideButton("Buy all", "shopping_basket", 10, true, function()
				hud.buy(look.basket, "basket")
			end, nil, #look.basket == owned, hud.buying("basket")),
			wideButton("Try on everything", "checkroom", 11, false, function()
				look.wearAll(look.basket)
			end, false, #look.basket == 0),
			wideButton("Add what I'm wearing", "add_shopping_cart", 12, false, function()
				look.addToBasket(wornToAdd)
			end, false, #wornToAdd == 0),
			e(ConfirmButton, {
				label = "Remove all",
				icon = "remove_shopping_cart",
				layoutOrder = 13,
				disabled = #look.basket == 0,
				onConfirm = look.clearBasket,
			}),
		}),
	})
end

local function WearingScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local hud = React.useContext(HudContext)
	local look = props.look
	local rows: { [string]: any } = {}
	local unowned, cost = 0, 0
	-- Unowned paid items first (dearest first), then free, then owned; the
	-- order put on breaks ties.
	local function rank(item): number
		return if item.owned then 3 elseif item.price > 0 then 1 else 2
	end
	local ordered = table.clone(look.worn)
	local putOn = {}
	for index, id in look.worn do
		putOn[id] = index
	end
	table.sort(ordered, function(a, b)
		local itemA, itemB = PlaceholderData.item(a), PlaceholderData.item(b)
		local rankA, rankB = rank(itemA), rank(itemB)
		if rankA ~= rankB then
			return rankA < rankB
		elseif rankA == 1 and itemA.price ~= itemB.price then
			return itemA.price > itemB.price
		end
		return putOn[a] < putOn[b]
	end)
	for index, id in ordered do
		local item = PlaceholderData.item(id)
		if not item.owned then
			unowned += 1
			cost += item.price
		end
		local inBasket = look.inBasket(id)
		rows["Row" .. id] = e(Parts.ListRow, {
			title = item.name,
			subtitle = item.main .. " · " .. item.sub,
			colour = Parts.swatch(item.colour),
			image = Parts.image(item),
			layoutOrder = index,
			trailingWidth = ROW_TRAILING,
			trailing = {
				Price = e(Parts.PriceTag, { item = item, size = 14, layoutOrder = 1 }),
				Buy = buyButton(item, 2, hud),
				Basket = if item.owned
					then nil
					else smallButton(if inBasket then "In basket" else "Basket", 3, inBasket, function()
						look.toggleBasket(id)
					end),
				TakeOff = smallButton("Take off", 4, false, function()
					look.toggleWear(id)
				end),
			},
			onActivated = function()
				props.nav.push({ kind = "item", id = id, label = item.name })
			end,
		})
	end

	return e("Frame", {
		Name = "WearingScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Rows = rowList(skin, rows, #look.worn, "You're not wearing anything"),
		Summary = sidePanel(skin, "Wearing", {
			summaryLine(skin, "Items", tostring(#look.worn), 1),
			summaryLine(skin, "Not owned", unowned .. " · " .. (if cost > 0 then Tokens.robux(cost) else "Free"), 2),
		}, {
			wideButton("Buy all", "shopping_basket", 9, true, function()
				hud.buy(look.worn, "wearing")
			end, nil, unowned == 0, hud.buying("wearing")),
			wideButton("Add unowned to basket", "add_shopping_cart", 10, false, function()
				local unownedIds = {}
				for _, id in look.worn do
					if not PlaceholderData.item(id).owned then
						table.insert(unownedIds, id)
					end
				end
				look.addToBasket(unownedIds)
			end, false),
			e(SaveOutfitButton, { look = look, layoutOrder = 11 }),
			e(ConfirmButton, {
				label = "Take everything off",
				icon = "delete_sweep",
				layoutOrder = 12,
				disabled = #look.worn == 0,
				onConfirm = look.takeOffAll,
			}),
		}),
	})
end

return {
	Basket = BasketScreen,
	Wearing = WearingScreen,
}

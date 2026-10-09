--!strict

--[[
	ListScreens (design frames 5f Basket / 5g Wearing, placeholder data)

	Basket: one row per item (Try on / Remove), a summary (items, already owned,
	total) with Buy all and Try on everything. Wearing: what's on the avatar
	(price or Owned, Basket toggle, Take off) with Add unowned to basket, Save as
	outfit and Take everything off. Rows open the item page.

	Buy all opens the buy prompt; Save as outfit is a stub until Task 12.

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
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))
local HudContext = require(views:WaitForChild("HudContext"))

local e = React.createElement

local SIDE_WIDTH = 250

local function smallButton(label: string, order: number, active: boolean?, onActivated: () -> ())
	return e(PillButton, {
		variant = "pill",
		size = 32,
		width = 104,
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
		PaddingRight = UDim.new(0, skin.px(3)),
	})
	return e("ScrollingFrame", {
		Size = UDim2.new(1, -skin.px(SIDE_WIDTH + 16), 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, count * (skin.px(64) + skin.px(8)) + skin.px(6)),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = skin.px(8),
		ScrollBarImageColor3 = Tokens.color.accent,
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

local function wideButton(label: string, icon: string?, order: number, active: boolean?, onActivated: (() -> ())?, sound: any?)
	return e(PillButton, {
		variant = "pill",
		size = Tokens.size.ctaHeight,
		label = label,
		icon = icon,
		iconSize = 18,
		active = active,
		sound = sound,
		layoutOrder = order,
		onActivated = onActivated,
	})
end

local function BasketScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local hud = React.useContext(HudContext)
	local look = props.look
	local rows: { [string]: any } = {}
	local owned = 0
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
			trailing = {
				Price = e(Parts.PriceTag, { item = item, size = 14, layoutOrder = 1 }),
				Try = smallButton(if wearing then "Wearing" else "Try on", 2, wearing, function()
					look.toggleWear(id)
				end),
				Remove = smallButton("Remove", 3, false, function()
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
				hud.openBuy(look.basket)
			end),
			wideButton("Try on everything", "checkroom", 11, false, function()
				look.wearAll(look.basket)
			end, false),
		}),
	})
end

local function WearingScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local look = props.look
	local rows: { [string]: any } = {}
	local unowned, cost = 0, 0
	for index, id in look.worn do
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
			trailing = {
				Price = e(Parts.PriceTag, { item = item, size = 14, layoutOrder = 1 }),
				Basket = if item.owned
					then nil
					else smallButton(if inBasket then "In basket" else "Basket", 2, inBasket, function()
						look.toggleBasket(id)
					end),
				TakeOff = smallButton("Take off", 3, false, function()
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
			summaryLine(skin, "Not owned", unowned .. " · " .. Tokens.robux(cost), 2),
		}, {
			wideButton("Add unowned to basket", "add_shopping_cart", 10, true, function()
				for _, id in look.worn do
					if not PlaceholderData.item(id).owned and not look.inBasket(id) then
						look.toggleBasket(id)
					end
				end
			end, false),
			wideButton("Save as outfit", "bookmark_add", 11, false),
			wideButton("Take everything off", "delete_sweep", 12, false, look.takeOffAll, false),
		}),
	})
end

return {
	Basket = BasketScreen,
	Wearing = WearingScreen,
}

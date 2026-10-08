--!strict

--[[
	OutfitsScreen (design frames 5d/5e, placeholder data)

	Root: source tabs (Mine · Community · Roblox) and a grid of outfit tiles;
	the outfit you're wearing gets the orange ring. An outfit opens its page:
	preview, Wear all, and every item as a row — a row opens the item page
	(Outfits › Neon Rider › Varsity Jacket). Saving, partial wear, codes and
	username lookup arrive in Tasks 12–16.

	OutfitsScreen.Root props: nav, look
	OutfitsScreen.Outfit props: nav, look, source, index
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local TextTab = require(components:WaitForChild("TextTab"))
local PillButton = require(components:WaitForChild("PillButton"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))

local e = React.createElement

local function wearingAll(look: any, outfit: PlaceholderData.Outfit): boolean
	for _, id in outfit.items do
		if not look.isWorn(id) then
			return false
		end
	end
	return #outfit.items > 0
end

local function OutfitTile(props: { outfit: PlaceholderData.Outfit, worn: boolean, onActivated: () -> (), layoutOrder: number })
	local skin = useSkin()
	local interaction = useInteraction()
	local first = PlaceholderData.item(props.outfit.items[1])
	return e("TextButton", {
		Name = "OutfitTile",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = props.onActivated,
		[React.Event.MouseEnter] = interaction.onEnter,
		[React.Event.MouseLeave] = interaction.onLeave,
	}, {
		Thumb = e(Parts.Thumb, {
			colour = Parts.swatch(first.colour),
			radius = 16,
			hovered = interaction.hovered,
			selected = props.worn,
			caption = "outfit",
		}, {
			Aspect = e("UIAspectRatioConstraint", { AspectRatio = 0.8, DominantAxis = Enum.DominantAxis.Width }),
		}),
		Meta = e("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, skin.px(36)),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(2)) }),
			Name = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, skin.textPx(14) + skin.px(2)),
				BackgroundTransparency = 1,
				Text = props.outfit.name,
				TextColor3 = Tokens.color.white,
				TextSize = skin.textPx(14),
				FontFace = Tokens.font(900),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 1,
			}),
			By = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, skin.textPx(12.5) + skin.px(2)),
				BackgroundTransparency = 1,
				Text = props.outfit.by .. " · " .. #props.outfit.items .. " items",
				TextColor3 = Tokens.color.white,
				TextTransparency = Tokens.alpha.textDim,
				TextSize = skin.textPx(12.5),
				FontFace = Tokens.font(800),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
			}),
		}),
	})
end

local function OutfitsScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local source, setSource = React.useState("Mine")

	local tabs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(20)),
		}),
	}
	for index, name in PlaceholderData.outfitSources do
		tabs["Tab" .. index] = e(TextTab, {
			label = name,
			active = name == source,
			layoutOrder = index,
			onActivated = function()
				setSource(name)
			end,
		})
	end

	local outfits = (PlaceholderData.outfits :: any)[source] :: { PlaceholderData.Outfit }
	local tiles: { [string]: any } = {}
	for index, outfit in outfits do
		tiles["Outfit" .. index] = e(OutfitTile, {
			outfit = outfit,
			worn = wearingAll(props.look, outfit),
			layoutOrder = index,
			onActivated = function()
				props.nav.push({ kind = "outfit", id = { source = source, index = index }, label = outfit.name })
			end,
		})
	end

	local tabsHeight = skin.px(Tokens.size.textTabHeight)
	return e("Frame", {
		Name = "OutfitsScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Tabs = e("Frame", {
			Size = UDim2.new(1, 0, 0, tabsHeight),
			BackgroundTransparency = 1,
		}, tabs),
		Grid = e(Parts.CardGrid, {
			columns = 5,
			cellAspect = 0.8,
			extraHeight = 40,
			count = #outfits,
			position = UDim2.fromOffset(0, tabsHeight + skin.px(12)),
			size = UDim2.new(1, 0, 1, -(tabsHeight + skin.px(12))),
		}, tiles),
	})
end

local function OutfitScreen(props: { nav: any, look: any, source: string, index: number })
	local skin = useSkin()
	local outfit = ((PlaceholderData.outfits :: any)[props.source] :: { PlaceholderData.Outfit })[props.index]
	local preview = skin.px(220)
	local first = PlaceholderData.item(outfit.items[1])

	local rows: { [string]: any } = {
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(8)) }),
		-- Inset so row strokes at the edges aren't clipped by the ScrollingFrame.
		Inset = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(3)),
			PaddingBottom = UDim.new(0, skin.px(3)),
			PaddingLeft = UDim.new(0, skin.px(3)),
			PaddingRight = UDim.new(0, skin.px(3)),
		}),
	}
	for index, id in outfit.items do
		local item = PlaceholderData.item(id)
		rows["Row" .. index] = e(Parts.ListRow, {
			title = item.name,
			subtitle = item.main .. " · " .. item.sub .. (if props.look.isWorn(id) then " · wearing" else ""),
			colour = Parts.swatch(item.colour),
			layoutOrder = index,
			trailing = { Price = e(Parts.PriceTag, { item = item, size = 14 }) },
			onActivated = function()
				props.nav.push({ kind = "item", id = id, label = item.name })
			end,
		})
	end

	local rowsHeight = #outfit.items * (skin.px(64) + skin.px(8)) + skin.px(6)
	return e("Frame", {
		Name = "OutfitScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Preview = e(Parts.Thumb, {
			colour = Parts.swatch(first.colour),
			radius = 18,
			caption = "outfit preview",
			selected = wearingAll(props.look, outfit),
			size = UDim2.new(0, preview, 1, 0),
		}),
		Body = e("Frame", {
			Position = UDim2.fromOffset(preview + skin.px(20), 0),
			Size = UDim2.new(1, -(preview + skin.px(20)), 1, 0),
			BackgroundTransparency = 1,
		}, {
			Title = e(ShadowText, { text = outfit.name, style = { size = 24, weight = 900 } }),
			By = e("Frame", {
				Position = UDim2.fromOffset(0, skin.px(32)),
				Size = UDim2.new(1, 0, 0, skin.px(18)),
				BackgroundTransparency = 1,
			}, {
				Text = e(ShadowText, {
					text = outfit.by .. " · " .. #outfit.items .. " items",
					style = Tokens.type.meta,
					transparency = Tokens.alpha.textDim,
					shadow = false,
				}),
			}),
			WearAll = e(PillButton, {
				variant = "pill",
				size = Tokens.size.ctaHeight,
				width = 150,
				icon = "checkroom",
				iconSize = 18,
				label = "Wear all",
				active = true,
				anchorPoint = Vector2.new(1, 0),
				position = UDim2.fromScale(1, 0),
				sound = false, -- the look change plays its own sound
				onActivated = function()
					props.look.wearAll(outfit.items, outfit.name)
				end,
			}),
			Rows = e("ScrollingFrame", {
				Position = UDim2.fromOffset(0, skin.px(64)),
				Size = UDim2.new(1, 0, 1, -skin.px(64)),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, rowsHeight),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = skin.px(8),
				ScrollBarImageColor3 = Tokens.color.accent,
			}, rows),
		}),
	})
end

return {
	Root = OutfitsScreen,
	Outfit = OutfitScreen,
}

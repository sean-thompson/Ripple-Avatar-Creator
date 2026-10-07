--!strict

--[[
	GalleryKit (THROWAWAY — Task 1 skin gallery)

	Scrolling sheet of every skin piece and state: type specimen, all icons,
	button states and sizes, tabs, badges, chips, text tabs and glass panels
	over bright / dark / busy backdrops.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local SkinAssets = require(views:WaitForChild("SkinAssets"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local PillButton = require(components:WaitForChild("PillButton"))
local PillTabs = require(components:WaitForChild("PillTabs"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local Badge = require(components:WaitForChild("Badge"))
local TextTab = require(components:WaitForChild("TextTab"))
local Chip = require(components:WaitForChild("Chip"))
local Icon = require(components:WaitForChild("Icon"))

local e = React.createElement

local function heading(skin, text: string, order: number)
	local size = skin.textPx(Tokens.type.panelTitle.size)
	return e("TextLabel", {
		Size = UDim2.new(1, 0, 0, size + skin.px(10)),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Tokens.color.accentText,
		TextSize = size,
		FontFace = Tokens.font(900),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = order,
	})
end

local function flow(skin, order: number, gap: number, children: { [string]: any })
	children.Layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Wraps = true,
		Padding = UDim.new(0, skin.px(gap)),
	})
	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, children)
end

local function captioned(skin, caption: string, order: number, child: any, width: number, height: number)
	local captionSize = skin.textPx(Tokens.type.meta.size)
	return e("Frame", {
		Size = UDim2.fromOffset(skin.px(width), skin.px(height) + captionSize + skin.px(8)),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Holder = e("Frame", {
			Size = UDim2.fromOffset(skin.px(width), skin.px(height)),
			BackgroundTransparency = 1,
		}, { Child = child }),
		Caption = e("TextLabel", {
			Position = UDim2.fromOffset(0, skin.px(height) + skin.px(4)),
			Size = UDim2.new(1, 0, 0, captionSize),
			BackgroundTransparency = 1,
			Text = caption,
			TextColor3 = Tokens.color.white,
			TextTransparency = Tokens.alpha.textDim,
			TextSize = captionSize,
			FontFace = Tokens.font(700),
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

local function centred(child: any)
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		Child = child,
	})
end

local function GalleryKit()
	local skin = useSkin()
	local tab, setTab = React.useState("Catalogue")
	local chipOn, setChipOn = React.useState(1)
	local textTabOn, setTextTabOn = React.useState(1)
	local activeToggle, setActiveToggle = React.useState(false)

	-- Type specimen with measured widths: distinct widths prove distinct faces.
	local specimen: { [string]: any } = {}
	for index, weight in { 600, 700, 800, 900 } do
		specimen["W" .. weight] = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, skin.textPx(28) + skin.px(6)),
			BackgroundTransparency = 1,
			Text = string.format("Nunito %d — Try on Witch Hat", weight),
			TextColor3 = Tokens.color.white,
			TextSize = skin.textPx(28),
			FontFace = Tokens.font(weight),
			LayoutOrder = index,
		})
	end

	local icons: { [string]: any } = {}
	for index, name in SkinAssets.iconNames() do
		icons[name] = captioned(skin, name, index, centred(e(Icon, { name = name, size = 36 })), 96, 44)
	end

	local roundSizes: { [string]: any } = {}
	for index, key in { "basket", "action", "close", "undo", "back", "small" } do
		local spec = (Tokens.size :: any)[key]
		roundSizes[key] = captioned(skin, string.format("%s %d", key, spec.size), index, e(PillButton, {
			variant = "round",
			size = spec.size,
			icon = "shopping_basket",
			iconSize = spec.icon,
			glowRadius = spec.glow,
		}), 96, 90)
	end

	local states: { [string]: any } = {
		Default = captioned(skin, "default", 1, e(PillButton, {
			variant = "round",
			size = 64,
			icon = "person_add",
			iconSize = 30,
			glowRadius = 14,
		}), 96, 70),
		Hover = captioned(skin, "hover (forced)", 2, e(PillButton, {
			variant = "round",
			size = 64,
			icon = "person_add",
			iconSize = 30,
			glowRadius = 14,
			forcedState = "hover",
		}), 96, 70),
		Pressed = captioned(skin, "pressed (forced)", 3, e(PillButton, {
			variant = "round",
			size = 64,
			icon = "person_add",
			iconSize = 30,
			glowRadius = 14,
			forcedState = "pressed",
		}), 96, 70),
		Active = captioned(skin, "active (tap)", 4, e(PillButton, {
			variant = "round",
			size = 64,
			icon = "landscape",
			iconSize = 30,
			glowRadius = 14,
			active = activeToggle,
			onActivated = function()
				setActiveToggle(not activeToggle)
			end,
		}), 96, 70),
		Disabled = captioned(skin, "disabled", 5, e(PillButton, {
			variant = "round",
			size = 64,
			icon = "lock",
			iconSize = 30,
			disabled = true,
		}), 96, 70),
		Cta = captioned(skin, "pill CTA (orange)", 6, e(PillButton, {
			variant = "pill",
			size = Tokens.size.ctaHeight,
			width = 220,
			label = "Open basket · 160 R$",
			icon = "chevron_right",
			iconSize = 20,
			active = true,
		}), 230, 50),
		Pill = captioned(skin, "pill (black)", 7, e(PillButton, {
			variant = "pill",
			size = 36,
			width = 120,
			label = "Studio",
			textStyle = Tokens.type.small,
		}), 130, 50),
	}

	local badges = {
		Count = captioned(skin, "count / orange", 1, centred(e(Badge, { kind = "count", tone = "orange", icon = "toll", text = "160" })), 110, 36),
		Wearing = captioned(skin, "marker / wearing", 2, centred(e(Badge, { kind = "marker", tone = "orange", icon = "checkroom" })), 110, 36),
		InBasket = captioned(skin, "marker / in basket", 3, centred(e(Badge, { kind = "marker", tone = "white", icon = "shopping_basket" })), 110, 36),
	}

	local chips: { [string]: any } = {}
	for index, name in { "All", "Long", "Short", "Curly", "Updo" } do
		chips[name] = e(Chip, {
			label = name,
			active = chipOn == index,
			layoutOrder = index,
			onActivated = function()
				setChipOn(index)
			end,
		})
	end

	local textTabs: { [string]: any } = {}
	for index, name in { "Mine", "Community", "Roblox" } do
		textTabs[name] = e(TextTab, {
			label = name,
			active = textTabOn == index,
			layoutOrder = index,
			onActivated = function()
				setTextTabOn(index)
			end,
		})
	end

	-- Glass over three backdrops: bright, dark, busy (stripes).
	local backdrops = {
		{ name = "bright", color = Color3.fromHex("#bfe0f2") },
		{ name = "dark", color = Color3.fromHex("#141c44") },
		{ name = "busy", color = Color3.fromHex("#ff7a00"), stripes = true },
	}
	local glass: { [string]: any } = {}
	for index, backdrop in backdrops do
		local stripes: { [string]: any } = {}
		if backdrop.stripes then
			for s = 0, 7 do
				stripes["S" .. s] = e("Frame", {
					Position = UDim2.fromScale(s / 8, 0),
					Size = UDim2.fromScale(1 / 16, 1),
					BackgroundColor3 = Color3.fromHex("#3b82f6"),
					BorderSizePixel = 0,
				})
			end
		end
		local panels: { [string]: any } = {}
		for vIndex, variant in { "dark", "bar", "light" } do
			panels[variant] = e(GlassPanel, {
				variant = variant :: any,
				cornerRadius = 18,
				shadow = true,
				position = UDim2.fromOffset(skin.px(14 + (vIndex - 1) * 112), skin.px(30)),
				size = UDim2.fromOffset(skin.px(100), skin.px(110)),
				zIndex = 2,
			}, {
				Text = e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = variant,
					TextColor3 = Tokens.color.white,
					TextSize = skin.textPx(Tokens.type.bodyStrong.size),
					FontFace = Tokens.font(900),
					ZIndex = 3,
				}),
			})
		end
		glass[backdrop.name] = captioned(skin, backdrop.name .. " backdrop", index, e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = backdrop.color,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, skin.px(14)) }),
			Stripes = e(React.Fragment, nil, stripes),
			Panels = e(React.Fragment, nil, panels),
		}), 350, 170)
	end

	return e("ScrollingFrame", {
		Name = "Kit",
		Position = UDim2.fromOffset(skin.px(28), skin.px(84)),
		Size = UDim2.new(1, -skin.px(56), 1, -skin.px(84 + 28)),
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = skin.px(10),
		ScrollBarImageColor3 = Tokens.color.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, skin.px(Tokens.radius.contentPanel)) }),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(12)),
			PaddingBottom = UDim.new(0, skin.px(24)),
			PaddingLeft = UDim.new(0, skin.px(20)),
			PaddingRight = UDim.new(0, skin.px(20)),
		}),
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(10)) }),
		TypeHeading = heading(skin, "Type — Nunito 600 / 700 / 800 / 900", 1),
		Type = flow(skin, 2, 24, specimen),
		IconHeading = heading(skin, "Icons", 3),
		Icons = flow(skin, 4, 6, icons),
		StateHeading = heading(skin, "Buttons — states", 5),
		States = flow(skin, 6, 16, states),
		SizeHeading = heading(skin, "Buttons — round sizes", 7),
		Sizes = flow(skin, 8, 16, roundSizes),
		TabsHeading = heading(skin, "Tab bar", 9),
		Tabs = flow(skin, 10, 0, {
			Tabs = e(PillTabs, {
				tabs = {
					{ id = "Catalogue", label = "Catalogue", icon = "apparel" },
					{ id = "Stores", label = "Stores", icon = "storefront" },
					{ id = "Outfits", label = "Outfits", icon = "checkroom" },
				},
				activeId = tab,
				onSelect = setTab,
				layoutOrder = 1,
			}),
		}),
		BadgeHeading = heading(skin, "Badges", 11),
		Badges = flow(skin, 12, 16, badges),
		ChipHeading = heading(skin, "Chips and text tabs", 13),
		Chips = flow(skin, 14, 8, chips),
		TextTabs = flow(skin, 15, 20, textTabs),
		GlassHeading = heading(skin, "Glass — dark / bar / light", 16),
		Glass = flow(skin, 17, 16, glass),
	})
end

return GalleryKit

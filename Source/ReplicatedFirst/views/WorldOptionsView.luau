--!strict

--[[
	WorldOptionsView (design: World options side panel)

	Time of day, sky preset, floor colour + pattern, lighting and shadows, and
	the flight hint. STATIC in Task 2: controls change only their own look —
	Task 4 drives the real (client-only, per-player, saved) world from them.

	Translucent glass, not blurred: the player needs to see the world change
	behind it.

	Props:
		onClose: () -> ()
		t: binding?   slide progress (0 off the right edge → 1 in place)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local PillButton = require(components:WaitForChild("PillButton"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local Icon = require(components:WaitForChild("Icon"))
local ShadowText = require(components:WaitForChild("ShadowText"))

local e = React.createElement

export type Props = {
	onClose: () -> (),
	t: any?,
}

local SKIES = { "Clear", "Clouds", "Studio", "Void" }
local PATTERNS = { "Grid", "Checker", "Plain" }

local function label(_skin, text: string, style: Tokens.TypeStyle, order: number, color: Color3?, transparency: number?)
	return e(ShadowText, {
		text = text,
		style = style,
		color = color,
		transparency = transparency,
		shadow = false,
		layoutOrder = order,
	})
end

local function row(skin, order: number, height: number, gap: number, children: { [string]: any })
	children.Layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, skin.px(gap)),
	})
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, skin.px(height)),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, children)
end

-- Static slider: track, orange fill, white knob (World options).
local function slider(skin, order: number, fraction: number)
	local knob = skin.px(22)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, knob),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Track = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, skin.px(6)),
			BackgroundColor3 = Tokens.color.inputWell,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Fill = e("Frame", {
				Size = UDim2.fromScale(fraction, 1),
				BackgroundColor3 = Tokens.color.accent,
				BorderSizePixel = 0,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
		}),
		Knob = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(fraction, 0.5),
			Size = UDim2.fromOffset(knob, knob),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Gradient = e("UIGradient", { Color = Tokens.gradient.knob, Rotation = Tokens.gradient.rotation }),
			Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1) }),
		}),
	})
end

local function toggle(skin, on: boolean, onActivated: () -> ())
	local w, h, k = skin.px(50), skin.px(28), skin.px(22)
	return e("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = if on then Tokens.color.white else Tokens.color.toggleOff,
		AutoButtonColor = false,
		Text = "",
		[React.Event.Activated] = onActivated,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Gradient = if on then e("UIGradient", { Color = Tokens.gradient.orange, Rotation = Tokens.gradient.rotation }) else nil,
		Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1) }),
		Knob = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, if on then w - k - skin.px(3) else skin.px(2), 0.5, 0),
			Size = UDim2.fromOffset(k, k),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Gradient = e("UIGradient", { Color = Tokens.gradient.knob, Rotation = Tokens.gradient.rotation }),
		}),
	})
end

local function WorldOptionsView(props: Props)
	local skin = useSkin()
	local sky, setSky = React.useState("Clear")
	local floor, setFloor = React.useState(1)
	local pattern, setPattern = React.useState("Grid")
	local shadows, setShadows = React.useState(true)

	local skyButtons: { [string]: any } = {}
	for index, name in SKIES do
		skyButtons[name] = e(PillButton, {
			variant = "pill",
			size = 36,
			width = 70,
			label = name,
			textStyle = Tokens.type.small,
			active = sky == name,
			layoutOrder = index,
			onActivated = function()
				setSky(name)
			end,
		})
	end

	local floorSwatches: { [string]: any } = {}
	for index, color in Tokens.floorSwatches do
		local selected = floor == index
		floorSwatches["Swatch" .. index] = e("TextButton", {
			Size = UDim2.fromOffset(skin.px(36), skin.px(36)),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			[React.Event.Activated] = function()
				setFloor(index)
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			-- Inferred: CSS double ring `0 0 0 2px #111, 0 0 0 4px #ffa64d` → one accent stroke.
			Ring = e("UIStroke", {
				Color = if selected then Tokens.color.accentText else Tokens.color.black,
				Thickness = skin.stroke(if selected then 3 else 1),
			}),
		})
	end

	local patternButtons: { [string]: any } = {}
	for index, name in PATTERNS do
		patternButtons[name] = e(PillButton, {
			variant = "pill",
			size = 36,
			width = 94,
			label = name,
			textStyle = Tokens.type.small,
			active = pattern == name,
			layoutOrder = index,
			onActivated = function()
				setPattern(name)
			end,
		})
	end

	return e(GlassPanel, {
		variant = "dark",
		cornerRadius = Tokens.radius.sidePanel,
		shadow = true,
		anchorPoint = Vector2.new(1, 0),
		position = (props.t or React.createBinding(1)):map(function(t: number)
			local off = (1 - t) * skin.px(Tokens.size.sidePanelWidth + Tokens.size.edgeInset)
			return UDim2.new(1, -skin.px(Tokens.size.edgeInset) + off, 0, skin.px(88))
		end),
		size = UDim2.new(0, skin.px(Tokens.size.sidePanelWidth), 1, -skin.px(88 + 112)),
		zIndex = 5,
	}, {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(14)),
			PaddingBottom = UDim.new(0, skin.px(18)),
			PaddingLeft = UDim.new(0, skin.px(18)),
			PaddingRight = UDim.new(0, skin.px(14)),
		}),
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(14)) }),
		Header = e("Frame", {
			Size = UDim2.new(1, 0, 0, skin.px(36)),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Title = row(skin, 1, 36, 8, {
				Icon = e(Icon, { name = "landscape", size = 22, color = Tokens.color.accentIcon, layoutOrder = 1 }),
				Text = label(skin, "World options", Tokens.type.panelTitle, 2),
			}),
			Close = e(PillButton, {
				variant = "round",
				size = Tokens.size.small.size,
				icon = "close",
				iconSize = Tokens.size.small.icon,
				anchorPoint = Vector2.new(1, 0),
				position = UDim2.fromScale(1, 0),
				sound = false, -- closing plays the swipe-off
				onActivated = props.onClose,
			}),
		}),
		TimeLabel = row(skin, 2, 20, 0, {
			Label = label(skin, "Time of day", Tokens.type.sectionLabel, 1),
			Value = e("TextLabel", {
				Size = UDim2.new(1, -skin.px(100), 1, 0),
				BackgroundTransparency = 1,
				Text = "13:00",
				TextColor3 = Tokens.color.accentText,
				TextSize = skin.textPx(Tokens.type.sectionLabel.size),
				FontFace = Tokens.font(800),
				TextXAlignment = Enum.TextXAlignment.Right,
				LayoutOrder = 2,
			}),
		}),
		TimeSlider = slider(skin, 3, 13 / 24),
		SkyLabel = label(skin, "Sky", Tokens.type.sectionLabel, 4),
		Skies = row(skin, 5, 36, 6, skyButtons),
		FloorLabel = label(skin, "Floor", Tokens.type.sectionLabel, 6),
		Floors = row(skin, 7, 36, 10, floorSwatches),
		Patterns = row(skin, 8, 36, 6, patternButtons),
		LightLabel = label(skin, "Lighting", Tokens.type.sectionLabel, 9),
		LightSlider = slider(skin, 10, 0.5),
		Shadows = e("Frame", {
			Size = UDim2.new(1, 0, 0, skin.px(28)),
			BackgroundTransparency = 1,
			LayoutOrder = 11,
		}, {
			Label = row(skin, 1, 28, 0, {
				Text = label(skin, "Shadows", Tokens.type.bodyStrong, 1),
			}),
			Toggle = toggle(skin, shadows, function()
				setShadows(not shadows)
			end),
		}),
		Hint = row(skin, 12, 20, 6, {
			Icon = e(Icon, { name = "flight", size = 18, color = Tokens.color.accentText, layoutOrder = 1 }),
			Text = label(skin, "Double-jump to fly. Use it to find a quiet spot.", Tokens.type.hint, 2, nil, Tokens.alpha.textSoft),
		}),
	})
end

return WorldOptionsView

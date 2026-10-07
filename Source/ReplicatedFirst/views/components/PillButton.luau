--!strict

--[[
	PillButton

	The design's glossy button (black split gradient, orange when active, 1px
	black border, inset top highlight). Hover glows orange and brightens; press
	springs to 0.94 scale. Covers both shapes in the mock:

	  variant "round"  circular icon button — Basket (84), actions (64),
	                   close (52), undo (44), back (40), small (36)
	  variant "pill"   rounded-rect with icon and/or label — CTAs, sky presets

	The press scale sits on an inner frame so it doesn't nudge siblings in a
	UIListLayout (pitfall 12); layout props live on the outer button (pitfall 7).

	Labelled buttons keep their content OUT of the press scale: Roblox snaps
	text to whole pixel sizes and positions, so text under a changing UIScale
	visibly jitters, and the text and its shadow snap apart. The face and glow
	still sink on press; the label stays perfectly still. Icon-only buttons
	scale their icon (images scale smoothly).

	Inferred translations (design is CSS):
	  · box-shadow 0 0 Npx rgba(255,138,26,.9) hover glow → concentric rings
	    behind the button (Tokens.glow)
	  · text-shadow 0 1px 1px rgba(0,0,0,.6) → ShadowText

	Props:
		variant: "round" | "pill"
		size: number?            round: diameter (design px). pill: height.
		width: number?           pill only, design px; nil fills the parent's width
		icon: string?            Material Symbols name
		iconSize: number?        design px
		iconAfter: boolean?      put the icon after the label (e.g. a trailing chevron)
		label: string?
		textStyle: Tokens.TypeStyle?   default Tokens.type.cta
		active: boolean?         orange face
		disabled: boolean?
		glowRadius: number?      design px; 0 disables
		badge: React element?    pinned top-right, may overflow
		forcedState: ("hover" | "pressed")?  gallery screenshots only
		onActivated: (() -> ())?
		layoutOrder, position, anchorPoint, zIndex
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useSpring = require(hooks:WaitForChild("useSpring"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local GlossFace = require(script.Parent:WaitForChild("GlossFace"))
local Icon = require(script.Parent:WaitForChild("Icon"))
local ShadowText = require(script.Parent:WaitForChild("ShadowText"))

local e = React.createElement

export type Props = {
	variant: "round" | "pill",
	size: number?,
	width: number?,
	icon: string?,
	iconSize: number?,
	iconAfter: boolean?,
	label: string?,
	textStyle: Tokens.TypeStyle?,
	active: boolean?,
	disabled: boolean?,
	glowRadius: number?,
	badge: any?,
	forcedState: ("hover" | "pressed")?,
	onActivated: (() -> ())?,
	layoutOrder: number?,
	position: UDim2?,
	anchorPoint: Vector2?,
	zIndex: number?,
}

local PILL = UDim.new(0.5, 0)

local function PillButton(props: Props)
	local skin = useSkin()
	local interaction = useInteraction(props.disabled)

	local hovered = interaction.hovered or props.forcedState == "hover" or props.forcedState == "pressed"
	local pressed = interaction.pressed or props.forcedState == "pressed"

	local pressSpring = useSpring({ scale = if pressed then Tokens.press.scale else 1 }, Tokens.spring.press)
	local hoverSpring = useSpring({ alpha = if hovered then 1 else 0 }, Tokens.spring.hover)
	local stateSpring = useSpring({ alpha = if props.active then 1 else 0 }, Tokens.spring.state)

	local isRound = props.variant == "round"
	local height = skin.px(props.size or Tokens.size.action.size)
	local outerSize = if isRound
		then UDim2.fromOffset(height, height)
		elseif props.width then UDim2.fromOffset(skin.px(props.width), height)
		else UDim2.new(1, 0, 0, height)

	local z = props.zIndex or 1
	local textStyle = props.textStyle or Tokens.type.cta
	local glowRadius = skin.px(props.glowRadius or 0)

	-- Glow rings: largest first so the brightest ring renders on top.
	local glow: { [string]: any } = {}
	if glowRadius > 0 then
		for index = #Tokens.glow.rings, 1, -1 do
			local ring = Tokens.glow.rings[index]
			local grow = math.max(1, math.floor(glowRadius * ring.grow + 0.5))
			glow["Ring" .. index] = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, grow * 2, 1, grow * 2),
				BackgroundColor3 = Tokens.glow.color,
				BackgroundTransparency = hoverSpring.alpha:map(function(alpha: number)
					-- Clamped: springs overshoot, which would flash past full glow.
					return 1 - (1 - ring.transparency) * math.clamp(alpha, 0, 1)
				end),
				BorderSizePixel = 0,
				ZIndex = z - 1, -- behind the face (siblings sort by ZIndex)
			}, {
				Corner = e("UICorner", { CornerRadius = PILL }),
			})
		end
	end

	local contentChildren: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(6)),
		}),
	}
	if props.icon then
		contentChildren.Icon = e(Icon, {
			name = props.icon,
			size = props.iconSize or Tokens.size.action.icon,
			layoutOrder = if props.iconAfter then 3 else 1,
			zIndex = z + 2,
		})
	end
	if props.label then
		contentChildren.Label = e(ShadowText, {
			text = props.label,
			style = textStyle,
			layoutOrder = 2,
			zIndex = z + 2,
		})
	end

	local content = e("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = z + 2,
	}, contentChildren)

	return e("TextButton", {
		Name = "PillButton",
		Size = outerSize,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder or 0,
		ZIndex = z,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = not props.disabled,
		[React.Event.Activated] = if props.disabled then nil else props.onActivated,
		[React.Event.MouseEnter] = interaction.onEnter,
		[React.Event.MouseLeave] = interaction.onLeave,
		[React.Event.MouseButton1Down] = interaction.onDown,
		[React.Event.MouseButton1Up] = interaction.onUp,
	}, {
		Body = e("Frame", {
			Name = "Body",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = z,
		}, {
			PressScale = e("UIScale", { Scale = pressSpring.scale }),
			Glow = e(React.Fragment, nil, glow),
			Face = e("Frame", {
				Name = "Face",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = z,
			}, {
				Corner = e("UICorner", { CornerRadius = PILL }),
				Border = e("UIStroke", {
					Color = Tokens.stroke.borderColor,
					Thickness = skin.stroke(Tokens.stroke.border),
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Gloss = e(GlossFace, {
					cornerRadius = PILL,
					activeAlpha = stateSpring.alpha,
					hoverAlpha = hoverSpring.alpha,
					highlight = Tokens.highlight.blackPill,
					zIndex = z,
				}),
			}),
			Content = if props.label then nil else content,
			Badge = if props.badge
				then e("Frame", {
					Name = "BadgeAnchor",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					ZIndex = z + 3,
				}, { Badge = props.badge })
				else nil,
		}),
		-- Unscaled label content (see header): a sibling drawn above the body.
		Content = if props.label then content else nil,
	})
end

return PillButton

--!strict

--[[
	TextTab

	The design's text tabs (Catalogue categories; Stores and Outfits source
	tabs): white when active with a 3px orange underline, white at 55% when
	inactive, white on hover. Colour and underline spring between states.

	Props:
		label: string
		active: boolean
		onActivated: () -> ()
		layoutOrder: number?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useSpring = require(hooks:WaitForChild("useSpring"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local useTextWidth = require(hooks:WaitForChild("useTextWidth"))
local Sounds = require(views:WaitForChild("Sounds"))
local Press = require(views:WaitForChild("Press"))

local e = React.createElement

export type Props = {
	label: string,
	active: boolean,
	onActivated: () -> (),
	layoutOrder: number?,
}

local function TextTab(props: Props)
	local skin = useSkin()
	local interaction = useInteraction()
	local lit = props.active or interaction.hovered

	local spring = useSpring({
		text = if lit then 0 else Tokens.alpha.textMuted,
		underline = if props.active then 0 else 1,
	}, Tokens.spring.state)

	local style = Tokens.type.textTab
	local textSize = skin.textPx(style.size)
	local font = Tokens.font(style.weight)
	-- Explicit width, not AutomaticSize (mis-sizes under the canvas UIScale).
	local width = useTextWidth(props.label, font, textSize)

	local function onPress()
		Sounds.play("tab")
		props.onActivated()
	end

	return e("TextButton", {
		Name = "TextTab",
		Size = UDim2.fromOffset(width, skin.px(Tokens.size.textTabHeight)),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = props.label,
		TextColor3 = Tokens.color.white,
		TextTransparency = spring.text,
		TextSize = textSize,
		FontFace = font,
		[React.Event.InputBegan] = Press.began(onPress),
		[React.Event.Activated] = Press.activated(onPress),
		[React.Event.MouseEnter] = interaction.onEnter,
		[React.Event.MouseLeave] = interaction.onLeave,
	}, {
		Underline = e("Frame", {
			Name = "Underline",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, skin.stroke(3)),
			BackgroundColor3 = Tokens.color.accent,
			BackgroundTransparency = spring.underline,
			BorderSizePixel = 0,
		}),
	})
end

return TextTab

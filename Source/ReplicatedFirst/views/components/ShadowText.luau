--!strict

--[[
	ShadowText

	The skin's single-line label. Sized explicitly from measured text width
	(hooks/useTextWidth) rather than AutomaticSize, which mis-sizes under the
	canvas UIScale.

	With `shadow` (default true) it adds the design's text-shadow
	(CSS `0 1px 1px rgba(0,0,0,.6)`): a 1px-offset black copy BEHIND the text.
	The copy is a lower-ZIndex sibling — as a child of the visible label it
	would draw on top and grey the text out.

	Props:
		text: string
		style: Tokens.TypeStyle
		color: Color3?          default white
		transparency: number?   text transparency
		shadow: boolean?        default true
		layoutOrder: number?
		zIndex: number?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useTextWidth = require(hooks:WaitForChild("useTextWidth"))

local e = React.createElement

export type Props = {
	text: string,
	style: Tokens.TypeStyle,
	color: Color3?,
	transparency: number?,
	shadow: boolean?,
	layoutOrder: number?,
	zIndex: number?,
}

local function ShadowText(props: Props)
	local skin = useSkin()
	local z = props.zIndex or 1
	local textSize = skin.textPx(props.style.size)
	local font = Tokens.font(props.style.weight)
	local width = useTextWidth(props.text, font, textSize)

	return e("Frame", {
		Name = "ShadowText",
		Size = UDim2.fromOffset(width, textSize),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 0,
		ZIndex = z,
	}, {
		Shadow = if props.shadow == false
			then nil
			else e("TextLabel", {
				Position = UDim2.fromOffset(0, skin.stroke(1)),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = props.text,
				TextColor3 = Tokens.color.black,
				TextTransparency = 0.4,
				TextSize = textSize,
				FontFace = font,
				ZIndex = z,
			}),
		Text = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = props.text,
			TextColor3 = props.color or Tokens.color.white,
			TextTransparency = props.transparency or 0,
			TextSize = textSize,
			FontFace = font,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = z + 1,
		}),
	})
end

return ShadowText

--!strict

--[[
	HudButton

	A toggle button used inside the StatusBar pill.
	Shows active state with gold-tinted background when the associated modal is open.

	Props:
		label: string
		isActive: boolean
		onActivated: () -> ()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local e = React.createElement

export type Props = {
	label: string,
	isActive: boolean,
	onActivated: () -> (),
	layoutOrder: number?,
}

local COLOR_TEXT = Color3.fromRGB(243, 241, 236)
local COLOR_GOLD_SOFT = Color3.fromRGB(246, 213, 138)
local COLOR_GOLD_BG = Color3.fromRGB(60, 48, 24)
local COLOR_STROKE = Color3.new(1, 1, 1)

local function HudButton(props: Props)
	local bgColor: Color3
	local bgTransparency: number
	local textColor: Color3
	local strokeTransparency: number

	if props.isActive then
		bgColor = COLOR_GOLD_BG
		bgTransparency = 0
		textColor = COLOR_GOLD_SOFT
		strokeTransparency = 0.45
	else
		bgColor = Color3.new(1, 1, 1)
		bgTransparency = 0.94
		textColor = COLOR_TEXT
		strokeTransparency = 0.86
	end

	return e("TextButton", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 34),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = bgTransparency,
		Text = props.label,
		TextColor3 = textColor,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		LayoutOrder = props.layoutOrder or 0,
		AutoButtonColor = false,
		[React.Event.Activated] = props.onActivated,
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}),
		Stroke = e("UIStroke", {
			Color = if props.isActive then Color3.fromRGB(233, 180, 76) else COLOR_STROKE,
			Transparency = strokeTransparency,
			Thickness = 1,
		}),
	})
end

return HudButton

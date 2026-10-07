--!strict

--[[
	Breadcrumbs (design: crumb row at the top of the full panel's content area)

	Back button (when deeper than the root) + "Root › Page › Page" crumbs. The
	last crumb is bright and heavy; earlier ones are dimmer and jump back to
	their level when tapped.

	Props:
		rootLabel: string
		stack: { useNavigation.Entry }
		onBack: () -> ()
		onPopTo: (depth: number) -> ()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local useTextWidth = require(hooks:WaitForChild("useTextWidth"))
local PillButton = require(components:WaitForChild("PillButton"))
local Icon = require(components:WaitForChild("Icon"))

local e = React.createElement

local function Crumb(props: { label: string, isLast: boolean, onActivated: () -> (), layoutOrder: number })
	local skin = useSkin()
	local interaction = useInteraction()
	local weight = if props.isLast then 900 else 800
	local textSize = skin.textPx(Tokens.type.crumb.size)
	local font = Tokens.font(weight)
	local width = useTextWidth(props.label, font, textSize)
	return e("TextButton", {
		Name = "Crumb",
		Size = UDim2.fromOffset(width, skin.px(40)),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = props.label,
		TextColor3 = if interaction.hovered and not props.isLast then Tokens.color.accentText else Tokens.color.white,
		TextTransparency = if props.isLast or interaction.hovered then 0 else Tokens.alpha.textDim,
		TextSize = textSize,
		FontFace = font,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = props.onActivated,
		[React.Event.MouseEnter] = interaction.onEnter,
		[React.Event.MouseLeave] = interaction.onLeave,
	})
end

export type Props = {
	rootLabel: string,
	stack: { any },
	onBack: () -> (),
	onPopTo: (depth: number) -> (),
}

local function Breadcrumbs(props: Props)
	local skin = useSkin()
	local canBack = #props.stack > 0
	local back = Tokens.size.back

	local crumbs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(4)),
		}),
	}
	local labels = { props.rootLabel }
	for _, entry in props.stack do
		table.insert(labels, entry.label)
	end
	for depth, label in labels do
		if depth > 1 then
			crumbs["Sep" .. depth] = e(Icon, {
				name = "chevron_right",
				size = 18,
				transparency = 1 - 0.35,
				layoutOrder = depth * 2 - 1,
			})
		end
		crumbs["Crumb" .. depth] = e(Crumb, {
			label = label,
			isLast = depth == #labels,
			layoutOrder = depth * 2,
			onActivated = function()
				props.onPopTo(depth - 1)
			end,
		})
	end

	local backWidth = if canBack then skin.px(back.size + 10) else 0
	return e("Frame", {
		Name = "Breadcrumbs",
		Size = UDim2.new(1, 0, 0, skin.px(back.size)),
		BackgroundTransparency = 1,
	}, {
		Back = if canBack
			then e(PillButton, {
				variant = "round",
				size = back.size,
				icon = "arrow_back",
				iconSize = back.icon,
				glowRadius = back.glow,
				onActivated = props.onBack,
			})
			else nil,
		Crumbs = e("Frame", {
			Position = UDim2.fromOffset(backWidth, 0),
			Size = UDim2.new(1, -backWidth, 1, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, crumbs),
	})
end

return Breadcrumbs

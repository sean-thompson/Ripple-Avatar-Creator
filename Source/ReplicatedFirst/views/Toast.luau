--!strict

--[[
	Toast (design: the confirmation pill under the tab bar, ~1.8s)

	Shows the latest toast; a new one replaces the current one — the old pill
	drops away while the new one pops in, so rapid repeat actions read as a
	quick flicker of updates rather than a growing stack.

	The pill fades via a CanvasGroup (GlassPanel can't fade its children),
	padded so its halo shadow isn't clipped (pitfall 8).

	Props:
		toast: { id: number, text: string, icon: string }?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useTransition = require(hooks:WaitForChild("useTransition"))
local useTextWidth = require(hooks:WaitForChild("useTextWidth"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local Icon = require(components:WaitForChild("Icon"))
local ShadowText = require(components:WaitForChild("ShadowText"))

local e = React.createElement

export type ToastData = { id: number, text: string, icon: string }

local MARGIN = 10 -- design px of render room around the pill for its shadow

local function Pill(props: { toast: ToastData, t: any })
	local skin = useSkin()
	local style = Tokens.type.toast
	local textWidth = useTextWidth(props.toast.text, Tokens.font(style.weight), skin.textPx(style.size))
	local margin = skin.px(MARGIN)
	local width = skin.px(12) + skin.px(20) + skin.px(7) + textWidth + skin.px(18)
	local height = skin.px(Tokens.size.toastHeight)

	return e("CanvasGroup", {
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = props.t:map(function(t: number)
			return UDim2.new(0.5, 0, 0, skin.px(84) - margin - (1 - t) * skin.px(Tokens.motion.toastDrop))
		end),
		Size = UDim2.fromOffset(width + margin * 2, height + margin * 2),
		GroupTransparency = props.t:map(function(t: number)
			return 1 - math.clamp(t, 0, 1)
		end),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, {
		Margin = e("UIPadding", {
			PaddingTop = UDim.new(0, margin),
			PaddingBottom = UDim.new(0, margin),
			PaddingLeft = UDim.new(0, margin),
			PaddingRight = UDim.new(0, margin),
		}),
		Pill = e(GlassPanel, {
			variant = "bar",
			cornerRadius = Tokens.size.toastHeight / 2,
			shadow = true,
		}, {
			Padding = e("UIPadding", { PaddingLeft = UDim.new(0, skin.px(12)), PaddingRight = UDim.new(0, skin.px(18)) }),
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, skin.px(7)),
			}),
			Icon = e(Icon, { name = props.toast.icon, size = 20, color = Tokens.color.accentText, layoutOrder = 1 }),
			Text = e(ShadowText, { text = props.toast.text, style = style, layoutOrder = 2 }),
		}),
	})
end

local function Toast(props: { toast: ToastData? })
	local transitions = useTransition(if props.toast then { props.toast } else {}, {
		from = { t = 0 },
		enter = { t = 1 },
		leave = { t = 0 },
		keys = function(toast: ToastData)
			return tostring(toast.id)
		end,
		config = Tokens.spring.toastIn,
		leaveConfig = Tokens.spring.toastOut,
	})

	local children: { [string]: any } = {}
	for _, transition in transitions do
		children["Toast" .. transition.key] = e(Pill, { toast = transition.item, t = transition.springProps.t })
	end
	return e(React.Fragment, nil, children)
end

return Toast

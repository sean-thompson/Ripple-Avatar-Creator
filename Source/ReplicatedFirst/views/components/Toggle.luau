--!strict

--[[
	Toggle (design: World options "Shadows" switch)

	50×28 track — glossy orange when on, dark when off — with a white knob that
	springs across.

	Props:
		on: boolean
		onToggle: (on: boolean) -> ()
		position, anchorPoint, layoutOrder
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local Sounds = require(views:WaitForChild("Sounds"))
local Press = require(views:WaitForChild("Press"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useSpring = require(hooks:WaitForChild("useSpring"))

local e = React.createElement

export type Props = {
	on: boolean,
	onToggle: (on: boolean) -> (),
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function Toggle(props: Props)
	local skin = useSkin()
	local spring = useSpring({ t = if props.on then 1 else 0 }, Tokens.spring.state)
	local w, h, k = skin.px(50), skin.px(28), skin.px(22)
	local inset = skin.px(3)

	local function onPress()
		Sounds.play("press")
		props.onToggle(not props.on)
	end

	return e("TextButton", {
		Name = "Toggle",
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = UDim2.fromOffset(w, h),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = Tokens.color.toggleOff,
		AutoButtonColor = false,
		Text = "",
		[React.Event.InputBegan] = Press.began(onPress),
		[React.Event.Activated] = Press.activated(onPress),
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		-- Border mode: on a button a UIStroke otherwise outlines the (empty) text.
		Stroke = e("UIStroke", {
			Color = Tokens.color.black,
			Thickness = skin.stroke(1),
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		On = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Tokens.color.white,
			BackgroundTransparency = spring.t:map(function(t: number)
				return 1 - math.clamp(t, 0, 1)
			end),
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Gradient = e("UIGradient", { Color = Tokens.gradient.orange, Rotation = Tokens.gradient.rotation }),
		}),
		Knob = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = spring.t:map(function(t: number)
				return UDim2.new(0, inset + (w - k - inset * 2) * t, 0.5, 0)
			end),
			Size = UDim2.fromOffset(k, k),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Gradient = e("UIGradient", { Color = Tokens.gradient.knob, Rotation = Tokens.gradient.rotation }),
		}),
	})
end

return Toggle

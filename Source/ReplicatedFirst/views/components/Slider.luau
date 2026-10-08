--!strict

--[[
	Slider (design: World options "Time of day" / "Lighting" sliders)

	Dark track, orange fill, white knob. Press anywhere on it (mouse or touch)
	and drag; the value snaps to `step`. The track is inset by half a knob at
	each end inside the full-width hit area, so the whole knob is grabbable
	even at the ends (otherwise its outer half hangs outside the button). `onChange` fires live while dragging
	(apply it immediately), `onCommit` once on release (save it).

	Positions are read in screen pixels against the track's AbsolutePosition /
	AbsoluteSize, so it works under the SkinRoot canvas UIScale.

	Props:
		value: number
		min: number
		max: number
		step: number
		onChange: (value: number) -> ()
		onCommit: (value: number) -> ()
		layoutOrder: number?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))

local e = React.createElement

export type Props = {
	value: number,
	min: number,
	max: number,
	step: number,
	onChange: (value: number) -> (),
	onCommit: (value: number) -> (),
	layoutOrder: number?,
}

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function Slider(props: Props)
	local skin = useSkin()
	local trackRef = React.useRef(nil :: GuiObject?)
	local dragging = React.useRef(false)
	local lastValue = React.useRef(props.value)
	-- Latest props for the input callbacks (they outlive a render).
	local latest = React.useRef(props)
	latest.current = props

	local function valueAt(x: number): number
		local track = trackRef.current
		local p = latest.current
		if not track or track.AbsoluteSize.X <= 0 then
			return p.value
		end
		local fraction = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = p.min + fraction * (p.max - p.min)
		return math.clamp(math.floor((raw - p.min) / p.step + 0.5) * p.step + p.min, p.min, p.max)
	end

	local function update(x: number)
		local value = valueAt(x)
		if value ~= lastValue.current then
			lastValue.current = value
			latest.current.onChange(value)
		end
	end

	React.useEffect(function()
		local moved = UserInputService.InputChanged:Connect(function(input: InputObject)
			if
				dragging.current
				and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
			then
				update(input.Position.X)
			end
		end)
		local ended = UserInputService.InputEnded:Connect(function(input: InputObject)
			if dragging.current and isPress(input) then
				dragging.current = false
				latest.current.onCommit(lastValue.current)
			end
		end)
		return function()
			moved:Disconnect()
			ended:Disconnect()
		end
	end, {})

	local fraction = math.clamp((props.value - props.min) / (props.max - props.min), 0, 1)
	local knob = skin.px(22)

	return e("TextButton", {
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, knob + skin.px(8)),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.layoutOrder or 0,
		[React.Event.InputBegan] = function(_rbx: GuiObject, input: InputObject)
			if isPress(input) then
				dragging.current = true
				lastValue.current = props.value
				update(input.Position.X)
			end
		end,
	}, {
		Track = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -knob, 0, skin.px(6)),
			BackgroundColor3 = Tokens.color.inputWell,
			BorderSizePixel = 0,
			ref = trackRef,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Fill = e("Frame", {
				Size = UDim2.fromScale(fraction, 1),
				BackgroundColor3 = Tokens.color.accent,
				BorderSizePixel = 0,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
			-- Child of the track so `fraction` maps onto the track's length.
			Knob = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(fraction, 0.5),
				Size = UDim2.fromOffset(knob, knob),
				BackgroundColor3 = Tokens.color.white,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
				Gradient = e("UIGradient", { Color = Tokens.gradient.knob, Rotation = Tokens.gradient.rotation }),
				Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1) }),
			}),
		}),
	})
end

return Slider

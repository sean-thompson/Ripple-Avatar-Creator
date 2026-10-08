--!strict

--[[
	RangeSlider (design: Catalogue price popover, two-handle min/max slider)

	Slider's look and input with two knobs: dark track, orange fill between
	them. A press grabs the nearer knob (ties go to the one that can move
	that way) and drags it; knobs can meet but not cross. Values snap to
	`step`. As in Slider, the track is inset by half a knob at each end so
	both knobs are fully grabbable at the ends, and positions are read in
	screen pixels against the track, so it works under the canvas UIScale.

	`onChange` fires live while dragging (update labels), `onCommit` once on
	release (run the search — the catalogue's rate limit can't take a search
	per pixel of drag).

	Props:
		low: number
		high: number
		min: number
		max: number
		step: number
		onChange: (low: number, high: number) -> ()
		onCommit: (low: number, high: number) -> ()
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
	low: number,
	high: number,
	min: number,
	max: number,
	step: number,
	onChange: (low: number, high: number) -> (),
	onCommit: (low: number, high: number) -> (),
	layoutOrder: number?,
}

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function RangeSlider(props: Props)
	local skin = useSkin()
	local trackRef = React.useRef(nil :: GuiObject?)
	local dragging = React.useRef(nil :: ("low" | "high")?)
	local values = React.useRef({ low = props.low, high = props.high })
	-- Latest props for the input callbacks (they outlive a render).
	local latest = React.useRef(props)
	latest.current = props

	local function valueAt(x: number): number
		local track = trackRef.current
		local p = latest.current
		if not track or track.AbsoluteSize.X <= 0 then
			return p.min
		end
		local fraction = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = p.min + fraction * (p.max - p.min)
		return math.clamp(math.floor((raw - p.min) / p.step + 0.5) * p.step + p.min, p.min, p.max)
	end

	local function update(x: number)
		local which = dragging.current
		if not which then
			return
		end
		local value = valueAt(x)
		local v = values.current
		local low, high = v.low, v.high
		if which == "low" then
			low = math.min(value, high)
		else
			high = math.max(value, low)
		end
		if low ~= v.low or high ~= v.high then
			values.current = { low = low, high = high }
			latest.current.onChange(low, high)
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
				dragging.current = nil
				latest.current.onCommit(values.current.low, values.current.high)
			end
		end)
		return function()
			moved:Disconnect()
			ended:Disconnect()
		end
	end, {})

	local span = props.max - props.min
	local lowFraction = math.clamp((props.low - props.min) / span, 0, 1)
	local highFraction = math.clamp((props.high - props.min) / span, 0, 1)
	local knob = skin.px(22)

	local function knobFrame(name: string, fraction: number)
		return e("Frame", {
			Name = name,
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
		})
	end

	return e("TextButton", {
		Name = "RangeSlider",
		Size = UDim2.new(1, 0, 0, knob + skin.px(8)),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.layoutOrder or 0,
		[React.Event.InputBegan] = function(_rbx: GuiObject, input: InputObject)
			if not isPress(input) then
				return
			end
			values.current = { low = props.low, high = props.high }
			local value = valueAt(input.Position.X)
			local toLow, toHigh = math.abs(value - props.low), math.abs(value - props.high)
			if toLow == toHigh then
				-- Knobs together: the side of the press decides which moves.
				dragging.current = if value < props.low then "low" else "high"
			else
				dragging.current = if toLow < toHigh then "low" else "high"
			end
			update(input.Position.X)
		end,
	}, {
		Track = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -knob, 0, skin.px(8)),
			BackgroundColor3 = Tokens.color.inputWell,
			BorderSizePixel = 0,
			ref = trackRef,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Fill = e("Frame", {
				Position = UDim2.fromScale(lowFraction, 0),
				Size = UDim2.fromScale(highFraction - lowFraction, 1),
				BackgroundColor3 = Tokens.color.accent,
				BorderSizePixel = 0,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
			-- Children of the track so fractions map onto its length.
			Low = knobFrame("Low", lowFraction),
			High = knobFrame("High", highFraction),
		}),
	})
end

return RangeSlider

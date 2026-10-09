--!strict

--[[
	Spinner

	A spinning arc: a ring whose stroke fades round its length, turning once
	a second. "Something's on its way" (a loading grid cell, a button waiting
	on Roblox).

	Props:
		size: number           diameter, design px
		thickness: number?     stroke, design px (default 4)
		color: Color3?         default Tokens.color.accent
		position, anchorPoint, layoutOrder, zIndex
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))

local e = React.createElement

local function Spinner(props: {
	size: number,
	thickness: number?,
	color: Color3?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
})
	local skin = useSkin()
	local rotation, setRotation = React.useBinding(0)
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function(dt: number)
			setRotation((rotation:getValue() + dt * 360) % 360)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})
	local ring = skin.px(props.size)
	return e("Frame", {
		Name = "Spinner",
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = UDim2.fromOffset(ring, ring),
		BackgroundTransparency = 1,
		Rotation = rotation,
		LayoutOrder = props.layoutOrder or 0,
		ZIndex = props.zIndex or 1,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Stroke = e("UIStroke", { Color = props.color or Tokens.color.accent, Thickness = skin.stroke(props.thickness or 4) }, {
			-- Fades round the ring, so it reads as a spinning arc.
			Fade = e("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.6, 0.85),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),
	})
end

return Spinner

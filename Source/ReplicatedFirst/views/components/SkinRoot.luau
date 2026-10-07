--!strict

--[[
	SkinRoot

	Viewport-filling root for skinned HUD content. Measures its own
	AbsoluteSize (so ScreenGui insets are respected — unlike useViewportScale,
	which reads the raw viewport) and provides SkinContext to its children.

	It's also the single place the sizing decision lives:

	  relative  children render directly in the full-size frame; skin
	            components scale their own pixels via useSkin().px.
	  fit       children render on a 1180x820 design canvas under one UIScale,
	            centred and letterboxed (html-to-react-luau Pattern 2).
	  fill      as fit, but the canvas takes the screen's aspect (in design
	            units) so corner-pinned content reaches the real edges.

	axis: "height" scales by viewport height only; "min" uses the smaller of the
	width/height ratios so narrow (4:3) screens don't overflow. `fit` is always
	"min".

	The UIScale is parented to the INNER canvas and the OUTER frame is what we
	measure — scaling the measured frame would feed back (pitfall 12).

	Props:
		sizing: SkinContext.Sizing
		glass: SkinContext.Glass
		axis: ("height" | "min")?   default "min"
		children
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local SkinContext = require(views:WaitForChild("SkinContext"))
local Tokens = require(views:WaitForChild("Tokens"))

local e = React.createElement

export type Axis = "height" | "min"

export type Props = {
	sizing: SkinContext.Sizing,
	glass: SkinContext.Glass,
	axis: Axis?,
	children: any,
}

local DESIGN_W = Tokens.design.width
local DESIGN_H = Tokens.design.height

local function computeScale(size: Vector2, axis: Axis): number
	if size.X <= 0 or size.Y <= 0 then
		return 1
	end
	local byHeight = size.Y / DESIGN_H
	if axis == "height" then
		return byHeight
	end
	return math.min(size.X / DESIGN_W, byHeight)
end

local function SkinRoot(props: Props)
	local rootRef = React.useRef(nil :: Frame?)
	local size, setSize = React.useState(Vector2.new(DESIGN_W, DESIGN_H))

	React.useEffect(function()
		local root = rootRef.current
		if not root then
			return
		end
		local function update()
			setSize(root.AbsoluteSize)
		end
		update()
		local connection = root:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		return function()
			connection:Disconnect()
		end
	end, {})

	local axis: Axis = if props.sizing == "fit" then "min" else props.axis or "min"
	local scale = computeScale(size, axis)

	local contextValue = React.useMemo(function()
		return {
			sizing = props.sizing,
			glass = props.glass,
			scale = scale,
		}
	end, { props.sizing, props.glass, scale } :: { any })

	local content
	if props.sizing == "relative" then
		content = e("Frame", {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, props.children)
	else
		local canvasSize = if props.sizing == "fit"
			then Vector2.new(DESIGN_W, DESIGN_H)
			else Vector2.new(size.X / scale, size.Y / scale)
		content = e("Frame", {
			Name = "Canvas",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(canvasSize.X, canvasSize.Y),
			BackgroundTransparency = 1,
		}, {
			Scale = e("UIScale", { Scale = scale }),
			Children = React.createElement(React.Fragment, nil, props.children),
		})
	end

	return e(SkinContext.Provider, {
		value = contextValue,
	}, {
		Root = e("Frame", {
			Name = "SkinRoot",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ref = rootRef,
		}, {
			Content = content,
		}),
	})
end

return SkinRoot

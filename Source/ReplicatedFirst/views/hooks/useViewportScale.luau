--!strict

--[[
	useViewportScale

	Returns the current viewport's height as a fraction of a canonical
	design height (1080 by default). Re-runs on viewport resize.

	Roblox natively expresses "relative to parent" (UDim2.Scale) but NOT
	"relative to viewport" as a plain number. This hook fills that gap for
	the residual PIXEL dimensions that can't be a Scale UDim:

	  · UIStroke.Thickness — pixel integer. Multiply a design-pixel stroke
	    (e.g. 3px) by useViewportScale() to get a viewport-proportional
	    thickness that matches the rest of a scale-based layout.
	  · UICorner.CornerRadius offset — small corner radii are usually
	    pixel-based and benefit from the same multiplier.
	  · TextSize derived from a CSS `font-size: <N>vh` design value:
	    TextSize = math.floor(N/100 * DESIGN_HEIGHT * useViewportScale() + 0.5)

	Companion to UDim2.fromScale + UIAspectRatioConstraint. Does NOT replace
	them — it's just for the pixel dimensions Roblox doesn't natively scale.

	CAVEAT — height-axis only. This tracks viewport HEIGHT, so it stays in
	proportion only for elements that also scale with viewport height (e.g.
	corner-pinned pieces in a viewport-filling root). It is WRONG for pixels
	inside an aspect-locked / width-dominant container (a centred modal with
	UIAspectRatioConstraint + DominantAxis.Width) — there, drive scale off the
	container's own measured AbsoluteSize instead. See the html-to-react-luau
	skill (pitfall #13) for the full story.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local DESIGN_HEIGHT = 1080

local function useViewportScale(): number
	local function compute(): number
		local camera = workspace.CurrentCamera
		if not camera then
			return 1
		end
		return camera.ViewportSize.Y / DESIGN_HEIGHT
	end

	local scale, setScale = React.useState(compute())

	React.useEffect(function()
		local camera = workspace.CurrentCamera
		local vpConn: RBXScriptConnection? = nil
		local function recompute()
			setScale(compute())
		end
		recompute()
		if camera then
			vpConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
		end
		local camConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			if vpConn then
				vpConn:Disconnect()
			end
			local cam = workspace.CurrentCamera
			if cam then
				vpConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
			end
			recompute()
		end)
		return function()
			if vpConn then
				vpConn:Disconnect()
			end
			camConn:Disconnect()
		end
	end, {})

	return scale
end

return useViewportScale

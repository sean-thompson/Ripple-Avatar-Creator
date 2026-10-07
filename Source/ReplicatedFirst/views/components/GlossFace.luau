--!strict

--[[
	GlossFace

	The glossy split-gradient fill shared by pill buttons and tab segments:
	a black face, an orange face stacked on top that fades in when active, a
	white hover overlay, and the inset top highlight.

	Gradient colours can't be sprung (SpringSolver has no ColorSequence), so
	"active" crossfades the orange face's transparency instead.

	Inferred translations (design is CSS):
	  · filter: brightness(1.18) on hover → white overlay (Tokens.hover)
	  · inset 0 1px 0 rgba(255,255,255,a) → 1px white stroke just inside the
	    edge, faded out down the shape by a stroke UIGradient

	Fills its parent. Put the black border UIStroke on the parent, not here.

	Props:
		cornerRadius: UDim?      nil for square (e.g. segments clipped by a CanvasGroup)
		activeAlpha: binding     0 = black, 1 = orange
		hoverAlpha: binding      0 = none, 1 = full hover overlay
		highlight: number?       top-highlight alpha (default Tokens.highlight.blackPill)
		zIndex: number?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))

local e = React.createElement

export type Props = {
	cornerRadius: UDim?,
	activeAlpha: any,
	hoverAlpha: any,
	highlight: number?,
	zIndex: number?,
}

local function corner(radius: UDim?)
	if radius == nil then
		return nil
	end
	return e("UICorner", { CornerRadius = radius })
end

local function GlossFace(props: Props)
	local skin = useSkin()
	local z = props.zIndex or 1
	local inset = skin.stroke(1)
	local highlightRadius = if props.cornerRadius
		then UDim.new(props.cornerRadius.Scale, math.max(0, props.cornerRadius.Offset - inset))
		else nil

	return e(React.Fragment, nil, {
		Black = e("Frame", {
			Name = "FaceBlack",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
			ZIndex = z,
		}, {
			Corner = corner(props.cornerRadius),
			Gradient = e("UIGradient", { Color = Tokens.gradient.black, Rotation = Tokens.gradient.rotation }),
		}),
		Orange = e("Frame", {
			Name = "FaceOrange",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Tokens.color.white,
			BackgroundTransparency = props.activeAlpha:map(function(alpha: number)
				return 1 - math.clamp(alpha, 0, 1)
			end),
			BorderSizePixel = 0,
			ZIndex = z,
		}, {
			Corner = corner(props.cornerRadius),
			Gradient = e("UIGradient", { Color = Tokens.gradient.orange, Rotation = Tokens.gradient.rotation }),
		}),
		Hover = e("Frame", {
			Name = "HoverOverlay",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Tokens.color.white,
			BackgroundTransparency = props.hoverAlpha:map(function(alpha: number)
				-- Clamped: springs overshoot, which would flash past full hover.
				return 1 - (1 - Tokens.hover.overlayTransparency) * math.clamp(alpha, 0, 1)
			end),
			BorderSizePixel = 0,
			ZIndex = z,
		}, {
			Corner = corner(props.cornerRadius),
		}),
		Highlight = e("Frame", {
			Name = "Highlight",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
			BackgroundTransparency = 1,
			ZIndex = z,
		}, {
			Corner = corner(highlightRadius),
			Stroke = e("UIStroke", {
				Color = Tokens.color.white,
				Thickness = inset,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, {
				Gradient = e("UIGradient", {
					Rotation = Tokens.gradient.rotation,
					Transparency = Tokens.highlightTransparency(props.highlight or Tokens.highlight.blackPill),
				}),
			}),
		}),
	})
end

return GlossFace

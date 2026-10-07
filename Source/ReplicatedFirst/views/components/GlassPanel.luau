--!strict

--[[
	GlassPanel

	The design's glass surfaces:

	  variant "dark"   World options side panel (grey→near-black, 72→86%)
	  variant "bar"    toast, Wearing bar (darker, near-opaque)
	  variant "light"  content panel, basket card (faint white wash)

	Roblox UI can't blur what's behind it, so the CSS backdrop-filter has no
	direct equivalent. In SkinContext glass "translucent" the fill is made
	denser to stay legible; in "blur" it keeps the design's alphas and relies on
	a scene blur (useGlassBlur) behind full-screen panels.

	Inferred translations:
	  · box-shadow → black UIStroke halo on a sibling frame (canonical soft shadow)
	  · inset top highlight → stroke-gradient highlight just inside the edge

	Props:
		variant: "dark" | "bar" | "light"
		cornerRadius: number?   design px (default 22)
		shadow: boolean?
		size: UDim2?            default fill parent
		position, anchorPoint, layoutOrder, zIndex
		children                rendered inside the fill
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))

local e = React.createElement

export type Props = {
	variant: "dark" | "bar" | "light",
	cornerRadius: number?,
	shadow: boolean?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
	children: any,
}

local function GlassPanel(props: Props)
	local skin = useSkin()
	local variant: Tokens.GlassVariant = (Tokens.glass :: any)[props.variant]
	local boost = if skin.glass == "translucent" then Tokens.glass.translucentBoost else 0
	local alphaTop = math.min(1, variant.alphaTop + boost)
	local alphaBottom = math.min(1, variant.alphaBottom + boost)
	local radius = UDim.new(0, skin.px(props.cornerRadius or Tokens.radius.sidePanel))
	local z = props.zIndex or 1
	local inset = skin.stroke(1)

	return e("Frame", {
		Name = "GlassPanel",
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder or 0,
		BackgroundTransparency = 1,
		ZIndex = z,
	}, {
		Shadow = if props.shadow
			then e("Frame", {
				Name = "Shadow",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = z - 1,
			}, {
				Corner = e("UICorner", { CornerRadius = radius }),
				Halo = e("UIStroke", {
					Color = Tokens.color.black,
					Thickness = skin.px(Tokens.stroke.shadowThickness),
					Transparency = Tokens.stroke.shadowTransparency,
				}),
			})
			else nil,
		Fill = e("Frame", {
			Name = "Fill",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
			ZIndex = z,
		}, {
			Corner = e("UICorner", { CornerRadius = radius }),
			Gradient = e("UIGradient", {
				Rotation = Tokens.gradient.rotation,
				Color = ColorSequence.new(variant.top, variant.bottom),
				Transparency = NumberSequence.new(1 - alphaTop, 1 - alphaBottom),
			}),
			Border = e("UIStroke", {
				Color = Tokens.color.white,
				Transparency = variant.border,
				Thickness = skin.stroke(1),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Highlight = e("Frame", {
				Name = "Highlight",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
				BackgroundTransparency = 1,
				ZIndex = z,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, math.max(0, radius.Offset - inset)) }),
				Stroke = e("UIStroke", {
					Color = Tokens.color.white,
					Thickness = inset,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}, {
					Gradient = e("UIGradient", {
						Rotation = Tokens.gradient.rotation,
						Transparency = Tokens.highlightTransparency(variant.highlight),
					}),
				}),
			}),
			Content = e("Frame", {
				Name = "Content",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = z + 1,
			}, props.children),
		}),
	})
end

return GlassPanel

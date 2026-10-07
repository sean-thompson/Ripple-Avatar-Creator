--!strict

--[[
	PillTabs

	The design's segmented tab bar (Catalogue · Stores · Outfits): one glossy
	pill split into equal segments, rounded only at the outer ends. The active
	segment crossfades to orange; hover brightens.

	UICorner doesn't clip children, so the segments sit inside a CanvasGroup
	with a UICorner (which does clip its composite). The black border, the faint
	outer ring and the drop shadow sit on sibling frames OUTSIDE the
	CanvasGroup, because a CanvasGroup drops anything drawn past its bounds
	(pitfall 8).

	Inferred translations:
	  · inset -1px 0 0 rgba(0,0,0,.8), inset -2px 0 0 rgba(255,255,255,.08)
	    segment dividers → two 1px frames on each segment's right edge
	  · 0 0 0 1px rgba(255,255,255,.12) outer ring → second stroke frame
	  · 0 3px 10px rgba(0,0,0,.5) → black UIStroke halo

	Props:
		tabs: { { id: string, label: string, icon: string } }
		activeId: string?
		onSelect: (id: string) -> ()
		tabWidth: number?      design px, default 172
		height: number?        design px, default 52
		position, anchorPoint, layoutOrder, zIndex
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useSpring = require(hooks:WaitForChild("useSpring"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local GlossFace = require(script.Parent:WaitForChild("GlossFace"))
local Icon = require(script.Parent:WaitForChild("Icon"))
local ShadowText = require(script.Parent:WaitForChild("ShadowText"))

local e = React.createElement

export type Tab = { id: string, label: string, icon: string }

export type Props = {
	tabs: { Tab },
	activeId: string?,
	onSelect: (id: string) -> (),
	tabWidth: number?,
	height: number?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
}

type SegmentProps = {
	tab: Tab,
	active: boolean,
	isLast: boolean,
	width: number,
	height: number,
	order: number,
	onSelect: (id: string) -> (),
}

local function Segment(props: SegmentProps)
	local skin = useSkin()
	local interaction = useInteraction()
	local hoverSpring = useSpring({ alpha = if interaction.hovered then 1 else 0 }, Tokens.spring.hover)
	local stateSpring = useSpring({ alpha = if props.active then 1 else 0 }, Tokens.spring.state)

	local line = skin.stroke(1)

	return e("TextButton", {
		Name = "Tab_" .. props.tab.id,
		Size = UDim2.fromOffset(props.width, props.height),
		LayoutOrder = props.order,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		[React.Event.Activated] = function()
			props.onSelect(props.tab.id)
		end,
		[React.Event.MouseEnter] = interaction.onEnter,
		[React.Event.MouseLeave] = interaction.onLeave,
	}, {
		Gloss = e(GlossFace, {
			activeAlpha = stateSpring.alpha,
			hoverAlpha = hoverSpring.alpha,
			highlight = Tokens.highlight.tab,
		}),
		DividerDark = if props.isLast
			then nil
			else e("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, line, 1, 0),
				BackgroundColor3 = Tokens.color.black,
				BackgroundTransparency = 1 - 0.8,
				BorderSizePixel = 0,
				ZIndex = 2,
			}),
		DividerLight = if props.isLast
			then nil
			else e("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -line, 0, 0),
				Size = UDim2.new(0, line, 1, 0),
				BackgroundColor3 = Tokens.color.white,
				BackgroundTransparency = 1 - 0.08,
				BorderSizePixel = 0,
				ZIndex = 2,
			}),
		Content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, skin.px(8)),
			}),
			Icon = e(Icon, { name = props.tab.icon, size = 24, layoutOrder = 1, zIndex = 3 }),
			Label = e(ShadowText, {
				text = props.tab.label,
				style = Tokens.type.tabLabel,
				layoutOrder = 2,
				zIndex = 3,
			}),
		}),
	})
end

local PILL = UDim.new(0.5, 0)

local function PillTabs(props: Props)
	local skin = useSkin()
	local width = skin.px(props.tabWidth or Tokens.size.tabWidth)
	local height = skin.px(props.height or Tokens.size.tabHeight)
	local total = width * #props.tabs
	local z = props.zIndex or 1
	local line = skin.stroke(1)

	local segments: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index, tab in props.tabs do
		segments[tab.id] = e(Segment, {
			tab = tab,
			active = tab.id == props.activeId,
			isLast = index == #props.tabs,
			width = width,
			height = height,
			order = index,
			onSelect = props.onSelect,
		})
	end

	return e("Frame", {
		Name = "PillTabs",
		Size = UDim2.fromOffset(total, height),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder or 0,
		BackgroundTransparency = 1,
		ZIndex = z,
	}, {
		Shadow = e("Frame", {
			Name = "Shadow",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = z,
		}, {
			Corner = e("UICorner", { CornerRadius = PILL }),
			Halo = e("UIStroke", {
				Color = Tokens.color.black,
				Thickness = skin.px(Tokens.stroke.shadowThickness),
				Transparency = Tokens.stroke.shadowTransparency,
			}),
		}),
		Segments = e("CanvasGroup", {
			Name = "Segments",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = z + 1,
		}, {
			Corner = e("UICorner", { CornerRadius = PILL }),
			Row = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, segments),
		}),
		Border = e("Frame", {
			Name = "Border",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = z + 2,
		}, {
			Corner = e("UICorner", { CornerRadius = PILL }),
			Stroke = e("UIStroke", {
				Color = Tokens.color.black,
				Thickness = line,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}),
		Ring = e("Frame", {
			Name = "Ring",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, line * 2, 1, line * 2),
			BackgroundTransparency = 1,
			ZIndex = z + 2,
		}, {
			Corner = e("UICorner", { CornerRadius = PILL }),
			Stroke = e("UIStroke", {
				Color = Tokens.color.white,
				Transparency = Tokens.stroke.tabRingTransparency,
				Thickness = line,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}),
	})
end

return PillTabs

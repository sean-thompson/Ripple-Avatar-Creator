--!strict

--[[
	WorldHud (design frame 5a: the HUD over the world)

	Tab bar top centre; bottom-left the Basket button (Robux total badge) and
	Create avatar / Save to Roblox / Reset; bottom-right the World options
	toggle and its side panel. The top-left is left clear for Roblox's own
	top-bar buttons (the tab bar is centred, so nothing reaches it).

	Hidden while the full panel is open — the design's panel covers it.
	Create avatar and Save to Roblox are stubs until Task 11; Reset clears the
	placeholder look.

	Props:
		nav, look
		tabs: { PillTabs.Tab }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local PillButton = require(components:WaitForChild("PillButton"))
local PillTabs = require(components:WaitForChild("PillTabs"))
local Badge = require(components:WaitForChild("Badge"))
local WorldOptionsView = require(views:WaitForChild("WorldOptionsView"))

local e = React.createElement

export type Props = {
	nav: any,
	look: any,
	tabs: { any },
}

local function WorldHud(props: Props)
	local skin = useSkin()
	local worldOpen, setWorldOpen = React.useState(false)

	local basket = Tokens.size.basket
	local action = Tokens.size.action
	local edge = skin.px(Tokens.size.edgeInset)
	local total = props.look.basketTotal

	local function actionButton(icon: string, order: number, onActivated: (() -> ())?)
		return e(PillButton, {
			variant = "round",
			size = action.size,
			icon = icon,
			iconSize = action.icon,
			glowRadius = action.glow,
			layoutOrder = order,
			zIndex = 2,
			onActivated = onActivated,
		})
	end

	return e("Frame", {
		Name = "WorldHud",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Tabs = e(PillTabs, {
			tabs = props.tabs,
			activeId = nil,
			onSelect = props.nav.toggleTab,
			anchorPoint = Vector2.new(0.5, 0),
			position = UDim2.new(0.5, 0, 0, skin.px(16)),
			zIndex = 2,
		}),
		BottomLeft = e("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, edge, 1, -edge),
			Size = UDim2.fromOffset(skin.px(basket.size + 12 * 3 + action.size * 3), skin.px(basket.size)),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, skin.px(12)),
			}),
			Basket = e(PillButton, {
				variant = "round",
				size = basket.size,
				icon = "shopping_basket",
				iconSize = basket.icon,
				glowRadius = basket.glow,
				layoutOrder = 1,
				zIndex = 2,
				onActivated = function()
					props.nav.openRoot("Basket")
				end,
				-- Design: badge sits top -8px, right -18px of the 84 button.
				badge = if total > 0
					then e(Badge, {
						kind = "count",
						tone = "orange",
						icon = "toll",
						text = tostring(total),
						anchorPoint = Vector2.new(1, 0),
						position = UDim2.fromOffset(skin.px(18), -skin.px(8)),
						zIndex = 6,
					})
					else nil,
			}),
			CreateAvatar = actionButton("person_add", 2),
			SaveToRoblox = actionButton("cloud_upload", 3),
			Reset = actionButton("restart_alt", 4, props.look.takeOffAll),
		}),
		WorldToggle = e(PillButton, {
			variant = "round",
			size = action.size,
			icon = "landscape",
			iconSize = action.icon,
			glowRadius = action.glow,
			active = worldOpen,
			anchorPoint = Vector2.new(1, 1),
			position = UDim2.new(1, -edge, 1, -edge),
			zIndex = 2,
			onActivated = function()
				setWorldOpen(not worldOpen)
			end,
		}),
		World = if worldOpen
			then e(WorldOptionsView, {
				onClose = function()
					setWorldOpen(false)
				end,
			})
			else nil,
	})
end

return WorldHud

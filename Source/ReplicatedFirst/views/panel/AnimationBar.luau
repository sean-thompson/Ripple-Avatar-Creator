--!strict

--[[
	AnimationBar (panel preview card: what the preview avatar is doing)

	A row of round buttons above the Wearing button — Idle, Move, Air, Swim,
	Emotes — choosing the animation the avatar preview
	plays (the real character is never touched). Animations come from what
	the player is wearing (an animation pack, or Roblox's defaults), read
	from the character's Animate script when they play.

	Each button opens a small menu upward: Idle (idle / look around), Move
	(walk / run), Air (jump / fall / climb), Swim (swim / tread water), and
	Emotes (the emotes being worn plus any in the basket). Long names end in
	an ellipsis.

	Props:
		selected: string                 the current choice's key
		emotes: { { id: number, name: string } }
		onSelect: (choice: Choice) -> ()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))
local useBackInput = require(views:WaitForChild("hooks"):WaitForChild("useBackInput"))
local PillButton = require(components:WaitForChild("PillButton"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))

local e = React.createElement

-- A thing the preview can play: one of the character's animations (by its
-- Animate folder + Animation name) or an emote (by catalogue id).
export type Choice = {
	key: string,
	label: string,
	folder: string?,
	name: string?,
	emoteId: number?,
}

type Group = { key: string, icon: string, label: string, variants: { Choice } }

local GROUPS: { Group } = {
	{
		key = "idle",
		icon = "accessibility_new",
		label = "Idle",
		variants = {
			{ key = "idle/1", label = "Idle", folder = "idle", name = "Animation1" },
			{ key = "idle/2", label = "Look around", folder = "idle", name = "Animation2" },
		},
	},
	{
		key = "move",
		icon = "directions_run",
		label = "Move",
		variants = {
			{ key = "move/walk", label = "Walk", folder = "walk", name = "WalkAnim" },
			{ key = "move/run", label = "Run", folder = "run", name = "RunAnim" },
		},
	},
	{
		key = "air",
		icon = "paragliding",
		label = "Air",
		variants = {
			{ key = "air/jump", label = "Jump", folder = "jump", name = "JumpAnim" },
			{ key = "air/fall", label = "Fall", folder = "fall", name = "FallAnim" },
			{ key = "air/climb", label = "Climb", folder = "climb", name = "ClimbAnim" },
		},
	},
	{
		key = "swim",
		icon = "pool",
		label = "Swim",
		variants = {
			{ key = "swim/1", label = "Swim", folder = "swim", name = "Swim" },
			{ key = "swim/2", label = "Tread water", folder = "swimidle", name = "SwimIdle" },
		},
	},
}

local AnimationBar = {}

AnimationBar.DEFAULT = GROUPS[1].variants[1]

-- Five buttons across the 250px card (less its 12px margins).
local BUTTON = 34
local GAP = 10
local ICON = 19
local ROW = 30
local MENU_WIDTH = 150
local MENU_ROWS = 6 -- visible before the list scrolls
local BAR_WIDTH = (#GROUPS + 1) * BUTTON + #GROUPS * GAP

local function groupOf(key: string): string
	return string.match(key, "^([^/]+)") or key
end

local function Menu(props: {
	choices: { Choice },
	selected: string,
	index: number, -- button position, for alignment
	onPick: (Choice) -> (),
	emptyText: string?,
})
	local skin = useSkin()
	local count = math.max(#props.choices, 1)
	local visible = math.min(count, MENU_ROWS)
	local listHeight = visible * ROW + (visible - 1) * GAP
	local rows: { [string]: any } = {
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(GAP)) }),
	}
	if #props.choices == 0 then
		rows.Empty = e(PillButton, {
			variant = "pill",
			size = ROW,
			label = props.emptyText or "Nothing here",
			textStyle = Tokens.type.small,
			disabled = true,
			glowRadius = 0,
			zIndex = 6,
		})
	end
	for order, choice in props.choices do
		rows["Choice" .. order] = e(PillButton, {
			variant = "pill",
			size = ROW,
			label = choice.label,
			labelMaxWidth = MENU_WIDTH - 16 - 20, -- inside the menu's padding and the pill's ends
			textStyle = Tokens.type.small,
			active = choice.key == props.selected,
			glowRadius = 0,
			sound = "tab",
			layoutOrder = order,
			zIndex = 6,
			onActivated = function()
				props.onPick(choice)
			end,
		})
	end
	-- Centred over its button, but kept inside the bar's width.
	local x = (props.index - 0.5) * (BUTTON + GAP)
	return e(GlassPanel, {
		variant = "bar",
		cornerRadius = 14,
		shadow = true,
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.new(0, skin.px(math.clamp(x, MENU_WIDTH / 2, BAR_WIDTH - MENU_WIDTH / 2)), 0, -skin.px(8)),
		size = UDim2.fromOffset(skin.px(MENU_WIDTH), skin.px(listHeight + 16)),
		zIndex = 6,
	}, {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(8)),
			PaddingBottom = UDim.new(0, skin.px(8)),
			PaddingLeft = UDim.new(0, skin.px(8)),
			PaddingRight = UDim.new(0, skin.px(8)),
		}),
		List = e("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, skin.px(count * ROW + (count - 1) * GAP)),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = if count > MENU_ROWS then skin.px(4) else 0,
			ScrollBarImageColor3 = Tokens.color.accent,
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			ZIndex = 6,
		}, rows),
	})
end

function AnimationBar.Bar(props: {
	selected: string,
	emotes: { { id: number, name: string } },
	onSelect: (Choice) -> (),
	position: UDim2?,
	anchorPoint: Vector2?,
})
	local skin = useSkin()
	local menu, setMenu = React.useState(nil :: string?) -- group key, or "emotes"
	local selectedGroup = groupOf(props.selected)

	useBackInput(function()
		if menu then
			setMenu(nil)
			return true
		end
		return false
	end)

	local function pick(choice: Choice)
		setMenu(nil)
		props.onSelect(choice)
	end

	local buttons: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(GAP)),
		}),
	}
	local menuElement = nil
	for index, group in GROUPS do
		buttons[group.key] = e(PillButton, {
			variant = "round",
			size = BUTTON,
			icon = group.icon,
			iconSize = ICON,
			active = selectedGroup == group.key or menu == group.key,
			glowRadius = 0,
			sound = "tab",
			layoutOrder = index,
			zIndex = 4,
			onActivated = function()
				if #group.variants > 1 then
					setMenu(if menu == group.key then nil else group.key)
				else
					pick(group.variants[1])
				end
			end,
		})
		if menu == group.key then
			menuElement = e(Menu, { choices = group.variants, selected = props.selected, index = index, onPick = pick })
		end
	end
	local emoteChoices: { Choice } = {}
	for _, emote in props.emotes do
		table.insert(emoteChoices, { key = "emote/" .. emote.id, label = emote.name, emoteId = emote.id })
	end
	buttons.emotes = e(PillButton, {
		variant = "round",
		size = BUTTON,
		icon = "emoji_people",
		iconSize = ICON,
		active = selectedGroup == "emote" or menu == "emotes",
		glowRadius = 0,
		sound = "tab",
		layoutOrder = #GROUPS + 1,
		zIndex = 4,
		onActivated = function()
			setMenu(if menu == "emotes" then nil else "emotes")
		end,
	})
	if menu == "emotes" then
		menuElement = e(Menu, {
			choices = emoteChoices,
			selected = props.selected,
			index = #GROUPS + 1,
			onPick = pick,
			emptyText = "No emotes worn",
		})
	end

	return e("Frame", {
		Name = "AnimationBar",
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = UDim2.fromOffset(skin.px(BAR_WIDTH), skin.px(BUTTON)),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, {
		Buttons = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}, buttons),
		Menu = menuElement,
	})
end

return AnimationBar

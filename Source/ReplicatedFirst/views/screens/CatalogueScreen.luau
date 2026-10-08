--!strict

--[[
	CatalogueScreen (design frame 5b root)

	Category text tabs + search, sub-category chips, and a 6-column grid of
	real catalogue items (useCatalogue → CatalogueClient, Task 7). Tabs and
	chips come from CatalogueConfig; the search box is a catalogue keyword
	search within the current tab and chip. Tapping a card opens its item
	page. The card's Try/Basket/Buy menu, colour/price filters, paste a link
	and load-more arrive in Task 8.

	Props: nav, look
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local TextTab = require(components:WaitForChild("TextTab"))
local Chip = require(components:WaitForChild("Chip"))
local Icon = require(components:WaitForChild("Icon"))
local PillButton = require(components:WaitForChild("PillButton"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local useCatalogue = require(hooks:WaitForChild("useCatalogue"))
local CatalogueConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CatalogueConfig"))

local e = React.createElement

local MESSAGES = {
	loading = "Loading…",
	error = "The catalogue isn't answering right now. Try again in a moment.",
	empty = "No items found",
}

local function CatalogueScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local category, setCategory = React.useState(CatalogueConfig.categories[1].name)
	local sub, setSub = React.useState("All")
	local query, setQuery = React.useState("")
	local searchFocused, setSearchFocused = React.useState(false)
	local catalogue = useCatalogue(category, if sub == "All" then nil else sub, query)

	-- "All" plus the tab's chips; a single-chip tab (Backgrounds) shows none.
	local subs = {}
	for _, entry in CatalogueConfig.categories do
		if entry.name == category and #entry.chips > 1 then
			subs = { "All" }
			for _, chip in entry.chips do
				table.insert(subs, chip.name)
			end
		end
	end

	local tabs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(20)),
		}),
	}
	for index, entry in CatalogueConfig.categories do
		tabs["Tab" .. index] = e(TextTab, {
			label = entry.name,
			active = entry.name == category,
			layoutOrder = index,
			onActivated = function()
				setCategory(entry.name)
				setSub("All")
			end,
		})
	end

	local chips: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(8)),
		}),
	}
	for index, name in subs do
		chips["Chip" .. index] = e(Chip, {
			label = name,
			active = name == sub,
			layoutOrder = index,
			onActivated = function()
				-- Tapping the active filter clears it (same as tapping All).
				setSub(if name == sub then "All" else name)
			end,
		})
	end

	local cards: { [string]: any } = {}
	local count = 0
	for _, item in catalogue.items do
		count += 1
		cards["Item" .. item.id] = e(Parts.ItemCard, {
			item = item,
			wearing = props.look.isWorn(item.id),
			inBasket = props.look.inBasket(item.id),
			layoutOrder = count,
			onActivated = function()
				props.nav.push({ kind = "item", id = item.id, label = item.name })
			end,
		})
	end
	local message = if count > 0 then nil
		elseif catalogue.status == "ready" then MESSAGES.empty
		else MESSAGES[catalogue.status]

	local searchWidth = skin.px(230)
	local tabsHeight = skin.px(Tokens.size.textTabHeight)
	local gridTop = if #subs > 0
		then tabsHeight + skin.px(Tokens.size.chipHeight) + skin.px(22)
		else tabsHeight + skin.px(12)

	return e("Frame", {
		Name = "CatalogueScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		TopRow = e("Frame", {
			Size = UDim2.new(1, 0, 0, tabsHeight),
			BackgroundTransparency = 1,
		}, {
			Tabs = e("ScrollingFrame", {
				Size = UDim2.new(1, -(searchWidth + skin.px(16)), 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollingDirection = Enum.ScrollingDirection.X,
				ScrollBarThickness = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				CanvasSize = UDim2.new(),
			}, tabs),
			Rule = e("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, -(searchWidth + skin.px(16)), 0, skin.stroke(1)),
				BackgroundColor3 = Tokens.color.white,
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
			}),
			Search = e("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(searchWidth, skin.px(40)),
				BackgroundColor3 = Tokens.color.inputWell,
				BorderSizePixel = 0,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
				Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1) }),
				Icon = e(Icon, {
					name = "search",
					size = 20,
					transparency = 0.45,
					anchorPoint = Vector2.new(0, 0.5),
					position = UDim2.new(0, skin.px(14), 0.5, 0),
				}),
				Box = e("TextBox", {
					Position = UDim2.fromOffset(skin.px(40), 0),
					-- Leaves room on the right for the clear button.
					Size = UDim2.new(1, -skin.px(76), 1, 0),
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					Text = query,
					-- Hidden while typing, so focus reads as an empty box ready for input.
					PlaceholderText = if searchFocused then "" else "Search catalogue",
					PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
					TextColor3 = Tokens.color.white,
					TextSize = skin.textPx(Tokens.type.search.size),
					FontFace = Tokens.font(Tokens.type.search.weight),
					TextXAlignment = Enum.TextXAlignment.Left,
					[React.Change.Text] = function(box: TextBox)
						setQuery(box.Text)
					end,
					[React.Event.Focused] = function()
						setSearchFocused(true)
					end,
					[React.Event.FocusLost] = function()
						setSearchFocused(false)
					end,
				}),
				-- Clears the search; only there when there's something to clear.
				Clear = if query ~= ""
					then e(PillButton, {
						variant = "round",
						size = Tokens.size.small.size - 8,
						icon = "close",
						iconSize = Tokens.size.small.icon - 4,
						glowRadius = 0,
						sound = "back",
						anchorPoint = Vector2.new(1, 0.5),
						position = UDim2.new(1, -skin.px(6), 0.5, 0),
						onActivated = function()
							setQuery("")
						end,
					})
					else nil,
			}),
		}),
		Chips = if #subs == 0 then nil else e("Frame", {
			Position = UDim2.fromOffset(0, tabsHeight + skin.px(10)),
			Size = UDim2.new(1, 0, 0, skin.px(Tokens.size.chipHeight)),
			BackgroundTransparency = 1,
		}, chips),
		Grid = e(Parts.CardGrid, {
			columns = 6,
			extraHeight = 40,
			count = count,
			position = UDim2.fromOffset(0, gridTop),
			size = UDim2.new(1, 0, 1, -gridTop),
		}, cards),
		Message = if message
			then e("TextLabel", {
				Position = UDim2.fromOffset(0, gridTop),
				Size = UDim2.new(1, 0, 0, skin.px(120)),
				BackgroundTransparency = 1,
				Text = message,
				TextColor3 = Tokens.color.white,
				TextTransparency = Tokens.alpha.textDim,
				TextSize = skin.textPx(Tokens.type.bodyStrong.size),
				FontFace = Tokens.font(Tokens.type.bodyStrong.weight),
			})
			else nil,
	})
end

return CatalogueScreen

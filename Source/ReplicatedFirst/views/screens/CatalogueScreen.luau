--!strict

--[[
	CatalogueScreen (design frame 5b root, placeholder data)

	Category text tabs + search, sub-category chips, and a 6-column grid of
	item cards. Tapping a card opens its item page (the card's Try/Basket/Buy
	menu, colour/price filters and real catalogue data arrive in Task 8).

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
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))

local e = React.createElement

local function matches(item: PlaceholderData.Item, category: string, sub: string, query: string): boolean
	if category == "Featured" then
		if sub == "New" and not item.new then
			return false
		elseif sub == "Trending" and not item.trending then
			return false
		end
	elseif category == "Halloween" then
		if not item.halloween or (sub ~= "All" and item.main ~= sub) then
			return false
		end
	elseif item.main ~= category or (sub ~= "All" and item.sub ~= sub) then
		return false
	end
	return query == "" or string.find(string.lower(item.name), query, 1, true) ~= nil
end

local function CatalogueScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local category, setCategory = React.useState("Featured")
	local sub, setSub = React.useState("All")
	local query, setQuery = React.useState("")

	local subs = { "All" }
	for _, entry in PlaceholderData.categories do
		if entry.name == category then
			subs = entry.subs
		end
	end

	local tabs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(20)),
		}),
	}
	for index, entry in PlaceholderData.categories do
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
	local lowered = string.lower(query)
	for _, item in PlaceholderData.items do
		if matches(item, category, sub, lowered) then
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
	end

	local searchWidth = skin.px(230)
	local tabsHeight = skin.px(Tokens.size.textTabHeight)

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
					Size = UDim2.new(1, -skin.px(54), 1, 0),
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					Text = query,
					PlaceholderText = "Search catalogue",
					PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
					TextColor3 = Tokens.color.white,
					TextSize = skin.textPx(Tokens.type.search.size),
					FontFace = Tokens.font(Tokens.type.search.weight),
					TextXAlignment = Enum.TextXAlignment.Left,
					[React.Change.Text] = function(box: TextBox)
						setQuery(box.Text)
					end,
				}),
			}),
		}),
		Chips = e("Frame", {
			Position = UDim2.fromOffset(0, tabsHeight + skin.px(10)),
			Size = UDim2.new(1, 0, 0, skin.px(Tokens.size.chipHeight)),
			BackgroundTransparency = 1,
		}, chips),
		Grid = e(Parts.CardGrid, {
			columns = 6,
			extraHeight = 40,
			count = count,
			position = UDim2.fromOffset(0, tabsHeight + skin.px(Tokens.size.chipHeight) + skin.px(22)),
			size = UDim2.new(1, 0, 1, -(tabsHeight + skin.px(Tokens.size.chipHeight) + skin.px(22))),
		}, cards),
	})
end

return CatalogueScreen

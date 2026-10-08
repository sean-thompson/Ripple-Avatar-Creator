--!strict

--[[
	StoresScreen (design frames 5h root / 5c store page, placeholder data)

	Root: sort tabs (Sponsored · Popular · Top rated · Favourites · My stores)
	and a grid of store tiles. A store opens its page: header + its items, each
	of which opens the item page — two levels of breadcrumbs. The Netflix-style
	home carousels, featured viewer, collections, favourites and Create store
	arrive in Tasks 18–19.

	StoresScreen props: nav, look
	StoresScreen.Store props: nav, look, storeId
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local Press = require(views:WaitForChild("Press"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local TextTab = require(components:WaitForChild("TextTab"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Icon = require(components:WaitForChild("Icon"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))

local e = React.createElement

local STORE_TINTS = { "Orange", "Purple", "Blue", "Pink", "Green" }

local function StoreTile(props: { store: PlaceholderData.Store, onActivated: () -> (), layoutOrder: number })
	local skin = useSkin()
	local interaction = useInteraction()
	local store = props.store
	return e("TextButton", {
		Name = "StoreTile",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.layoutOrder,
		[React.Event.InputBegan] = Press.began(props.onActivated),
		[React.Event.Activated] = Press.activated(props.onActivated),
		[React.Event.MouseEnter] = interaction.onEnter,
		[React.Event.MouseLeave] = interaction.onLeave,
	}, {
		Thumb = e(Parts.Thumb, {
			colour = Parts.swatch(STORE_TINTS[(store.id - 1) % #STORE_TINTS + 1]),
			radius = 16,
			hovered = interaction.hovered,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, skin.px(12)),
				PaddingRight = UDim.new(0, skin.px(12)),
				PaddingBottom = UDim.new(0, skin.px(10)),
			}),
			Text = e("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, skin.px(42)),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					Padding = UDim.new(0, skin.px(2)),
				}),
				Name = e(ShadowText, { text = store.name, style = Tokens.type.cardTitle, layoutOrder = 1 }),
				Meta = e(ShadowText, {
					text = string.format("%d%% liked · %s", store.rating, PlaceholderData.formatCount(store.visits)),
					style = Tokens.type.meta,
					transparency = Tokens.alpha.textDim,
					shadow = false,
					layoutOrder = 2,
				}),
			}),
			Sponsored = if store.sponsored
				then e(Icon, {
					name = "star",
					size = 18,
					color = Tokens.color.accentText,
					anchorPoint = Vector2.new(1, 0),
					position = UDim2.new(1, 0, 0, skin.px(10)),
				})
				else nil,
		}),
	})
end

local function sortedStores(sort: string): { PlaceholderData.Store }
	local list = table.clone(PlaceholderData.stores)
	if sort == "Sponsored" then
		local sponsored = {}
		for _, store in list do
			if store.sponsored then
				table.insert(sponsored, store)
			end
		end
		return sponsored
	elseif sort == "Popular" then
		table.sort(list, function(a, b)
			return a.visits > b.visits
		end)
	elseif sort == "Top rated" then
		table.sort(list, function(a, b)
			return a.rating > b.rating
		end)
	elseif sort == "Favourites" then
		return { list[10], list[12] }
	elseif sort == "My stores" then
		return { list[16] }
	end
	return list
end

local function StoresScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local sort, setSort = React.useState("Popular")

	local tabs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(20)),
		}),
	}
	for index, name in PlaceholderData.storeSorts do
		tabs["Tab" .. index] = e(TextTab, {
			label = name,
			active = name == sort,
			layoutOrder = index,
			onActivated = function()
				setSort(name)
			end,
		})
	end

	local tiles: { [string]: any } = {}
	local stores = sortedStores(sort)
	for index, store in stores do
		tiles["Store" .. store.id] = e(StoreTile, {
			store = store,
			layoutOrder = index,
			onActivated = function()
				props.nav.push({ kind = "store", id = store.id, label = store.name })
			end,
		})
	end

	local tabsHeight = skin.px(Tokens.size.textTabHeight)
	return e("Frame", {
		Name = "StoresScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Tabs = e("Frame", {
			Size = UDim2.new(1, 0, 0, tabsHeight),
			BackgroundTransparency = 1,
		}, tabs),
		Grid = e(Parts.CardGrid, {
			columns = 4,
			cellAspect = 1.7,
			count = #stores,
			position = UDim2.fromOffset(0, tabsHeight + skin.px(12)),
			size = UDim2.new(1, 0, 1, -(tabsHeight + skin.px(12))),
		}, tiles),
	})
end

local function StoreScreen(props: { nav: any, look: any, storeId: number })
	local skin = useSkin()
	local store = PlaceholderData.stores[props.storeId]
	local items = PlaceholderData.storeItems(store.id)

	local cards: { [string]: any } = {}
	for index, item in items do
		cards["Item" .. item.id] = e(Parts.ItemCard, {
			item = item,
			wearing = props.look.isWorn(item.id),
			inBasket = props.look.inBasket(item.id),
			layoutOrder = index,
			onActivated = function()
				props.nav.push({ kind = "item", id = item.id, label = item.name })
			end,
		})
	end

	local header = skin.px(64)
	return e("Frame", {
		Name = "StoreScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Header = e("Frame", {
			Size = UDim2.new(1, 0, 0, header),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(4)) }),
			Name = e(ShadowText, { text = store.name, style = { size = 24, weight = 900 }, layoutOrder = 1 }),
			Meta = e(ShadowText, {
				text = string.format("%d%% liked · %s visits · %d items", store.rating, PlaceholderData.formatCount(store.visits), #items),
				style = Tokens.type.meta,
				transparency = Tokens.alpha.textDim,
				shadow = false,
				layoutOrder = 2,
			}),
		}),
		Grid = e(Parts.CardGrid, {
			columns = 6,
			extraHeight = 40,
			count = #items,
			position = UDim2.fromOffset(0, header),
			size = UDim2.new(1, 0, 1, -header),
		}, cards),
	})
end

return {
	Root = StoresScreen,
	Store = StoreScreen,
}

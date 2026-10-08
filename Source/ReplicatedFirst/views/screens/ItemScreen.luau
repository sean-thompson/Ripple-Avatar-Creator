--!strict

--[[
	ItemScreen (design item page, placeholder data)

	Large preview, name, type / creator / colour, price, Try on · Basket · Buy,
	the item's id (selectable, to copy) and catalogue description (up to three lines),
	and a "More like this" row (same category for now — the slot the phase 3
	recommendation engine fills). Try on and Basket toggle the placeholder
	look so badges and counts react; Buy opens the buy prompt (the Roblox
	hand-off is Task 11).

	Props: nav, look, itemId
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local PillButton = require(components:WaitForChild("PillButton"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))
local CatalogueClient = require(views:WaitForChild("catalogue"):WaitForChild("CatalogueClient"))
local ItemColour = require(views:WaitForChild("catalogue"):WaitForChild("ItemColour"))
local HudContext = require(views:WaitForChild("HudContext"))
local useTextWidth = require(hooks:WaitForChild("useTextWidth"))

local e = React.createElement

-- "ID 1234…": the id is a read-only TextBox, so it can be selected and copied
-- (Roblox has no clipboard API to copy it for the player).
local function IdLine(props: { label: string, id: number, layoutOrder: number })
	local skin = useSkin()
	local text = tostring(props.id)
	local style = Tokens.type.bodyStrong
	local width = useTextWidth(text, Tokens.font(style.weight), skin.textPx(style.size))
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, skin.px(20)),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(8)),
		}),
		Label = e(ShadowText, {
			text = props.label,
			style = Tokens.type.meta,
			transparency = Tokens.alpha.textDim,
			shadow = false,
			layoutOrder = 1,
		}),
		Value = e("TextBox", {
			Size = UDim2.fromOffset(width + skin.px(4), skin.px(20)),
			BackgroundTransparency = 1,
			Text = text,
			TextEditable = false,
			ClearTextOnFocus = false,
			TextColor3 = Tokens.color.white,
			TextSize = skin.textPx(style.size),
			FontFace = Tokens.font(style.weight),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		}),
	})
end

local function metaLine(skin, label: string, value: string, order: number)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, skin.px(20)),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(8)),
		}),
		Label = e(ShadowText, {
			text = label,
			style = Tokens.type.meta,
			transparency = Tokens.alpha.textDim,
			shadow = false,
			layoutOrder = 1,
		}),
		Value = e(ShadowText, { text = value, style = Tokens.type.bodyStrong, shadow = false, layoutOrder = 2 }),
	})
end

local function ItemScreen(props: { nav: any, look: any, itemId: number })
	local skin = useSkin()
	local hud = React.useContext(HudContext)
	local item = PlaceholderData.item(props.itemId)
	local _colourVersion, setColourVersion = React.useState(0)

	-- Work out the item's colour (for the Colour line) if we don't know it.
	React.useEffect(function()
		if item.colour ~= "" or item.thumbnail == "" then
			return nil
		end
		local connection = ItemColour.changed:Connect(function()
			if ItemColour.isDone(item) then
				setColourVersion(function(v: number)
					return v + 1
				end)
			end
		end)
		ItemColour.classify(item)
		return function()
			connection:Disconnect()
		end
	end, { item.id })
	local wearing = props.look.isWorn(item.id)
	local inBasket = props.look.inBasket(item.id)
	local preview = skin.px(250)

	-- Same category, same chip first, from items this client has already seen
	-- (mock items for mock ones). Task 9 makes this a proper query.
	local similar = {}
	if item.thumbnail ~= "" then
		similar = CatalogueClient.similar(item, 6)
	else
		for _, other in PlaceholderData.items do
			if other.id ~= item.id and other.main == item.main and #similar < 6 then
				table.insert(similar, other)
			end
		end
	end
	local more: { [string]: any } = {}
	local count = 0
	for _, other in similar do
		count += 1
		more["Item" .. other.id] = e(Parts.ItemCard, {
			item = other,
			wearing = props.look.isWorn(other.id),
			inBasket = props.look.inBasket(other.id),
			layoutOrder = count,
			onActivated = function()
				props.nav.replaceTop({ kind = "item", id = other.id, label = other.name })
			end,
		})
	end

	-- Catalogue descriptions are free text: fold line breaks into spaces and
	-- cap the height (three lines) so a long one can't push the actions around.
	local description = string.gsub(item.description, "%s*\n%s*", " ")
	description = string.match(description, "^%s*(.-)%s*$") or ""
	local descriptionHeight = math.floor(skin.textPx(13.5) * 1.15 * 3)

	local buyLabel = if item.owned then "Owned" elseif item.price == 0 then "Get free" else "Buy " .. item.price

	return e("Frame", {
		Name = "ItemScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Preview = e(Parts.Thumb, {
			colour = Parts.swatch(item.colour),
			image = Parts.image(item),
			radius = 18,
			caption = string.lower(item.sub),
			size = UDim2.fromOffset(preview, preview),
		}),
		Info = e("Frame", {
			Position = UDim2.fromOffset(preview + skin.px(20), 0),
			Size = UDim2.new(1, -(preview + skin.px(20)), 0, preview),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(8)) }),
			Name = e(ShadowText, { text = item.name, style = { size = 26, weight = 900 }, layoutOrder = 1 }),
			Id = if item.thumbnail ~= ""
				then e(IdLine, {
					label = if item.kind == "Bundle" then "Bundle ID" else "ID",
					id = item.targetId,
					layoutOrder = 2,
				})
				else nil,
			Type = metaLine(skin, "Type", item.main .. " · " .. item.sub .. (if item.limited then " · Limited" else ""), 3),
			Creator = metaLine(skin, "Creator", item.creator, 4),
			Colour = if item.colour ~= "" then metaLine(skin, "Colour", item.colour, 5) else nil,
			Price = e(Parts.PriceTag, { item = item, size = 18, layoutOrder = 6 }),
			Actions = e("Frame", {
				Size = UDim2.new(1, 0, 0, skin.px(Tokens.size.ctaHeight)),
				BackgroundTransparency = 1,
				LayoutOrder = 7,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, skin.px(8)),
				}),
				Try = e(PillButton, {
					variant = "pill",
					size = Tokens.size.ctaHeight,
					width = 140,
					icon = if wearing then "remove" else "checkroom",
					iconSize = 18,
					label = if wearing then "Take off" else "Try on",
					active = not wearing,
					sound = false, -- the look change plays its own sound
					layoutOrder = 1,
					onActivated = function()
						props.look.toggleWear(item.id)
					end,
				}),
				Basket = e(PillButton, {
					variant = "pill",
					size = Tokens.size.ctaHeight,
					width = 170,
					icon = if inBasket then "remove_shopping_cart" else "add_shopping_cart",
					iconSize = 18,
					label = if inBasket then "In basket" else "Add to basket",
					sound = false, -- the look change plays its own sound
					layoutOrder = 2,
					onActivated = function()
						props.look.toggleBasket(item.id)
					end,
				}),
				Buy = e(PillButton, {
					variant = "pill",
					size = Tokens.size.ctaHeight,
					width = 120,
					label = buyLabel,
					disabled = item.owned,
					layoutOrder = 3,
					onActivated = function()
						hud.openBuy({ item.id })
					end,
				}),
			}),
			Description = if description ~= ""
				then e("TextLabel", {
					Size = UDim2.new(1, 0, 0, descriptionHeight),
					BackgroundTransparency = 1,
					Text = description,
					TextColor3 = Tokens.color.white,
					TextTransparency = Tokens.alpha.textDim,
					TextSize = skin.textPx(13.5),
					FontFace = Tokens.font(700),
					TextWrapped = true,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					LayoutOrder = 8,
				})
				else nil,
		}),
		MoreHeading = e("Frame", {
			Position = UDim2.fromOffset(0, preview + skin.px(18)),
			Size = UDim2.new(1, 0, 0, skin.px(24)),
			BackgroundTransparency = 1,
		}, {
			Heading = e(Parts.Heading, { text = "More like this" }),
		}),
		More = e(Parts.CardGrid, {
			columns = 6,
			extraHeight = 40,
			count = count,
			position = UDim2.fromOffset(0, preview + skin.px(50)),
			size = UDim2.new(1, 0, 1, -(preview + skin.px(50))),
		}, more),
	})
end

return ItemScreen

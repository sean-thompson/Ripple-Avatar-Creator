--!strict

--[[
	OutfitsScreen (design frame 5d: Outfits root and the outfit page)

	Root: source tabs (Mine · Community · Roblox) beside a search box, and a
	grid of outfit cards. Mine starts with a "Save what I'm wearing" card,
	then your saved outfits (look.outfits, Task 12). The outfit you're
	wearing exactly gets the orange ring. Search filters by name. Community
	and Roblox still show placeholder outfits (Tasks 13 and 16). Cards show a
	2×2 mosaic of the outfit's item thumbnails.

	Outfit page: on the left the preview (your avatar wearing it, for a saved
	outfit: OutfitPreview), the name (tap to rename a saved one), Wear all and
	Delete (press twice). On the right "N items · M selected" with Select
	all / none, a row per item with a checkbox (the row itself opens the item
	page: Outfits › Name › Item), and Wear selected · Add to basket · Buy
	selected (priced for the unowned items selected).

	OutfitsScreen.Root props: nav, look
	OutfitsScreen.Outfit props: nav, look, source, index (a saved outfit's id
	for Mine; the placeholder list position otherwise)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local Press = require(views:WaitForChild("Press"))
local Sounds = require(views:WaitForChild("Sounds"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local useSessionState = require(hooks:WaitForChild("useSessionState"))
local TextTab = require(components:WaitForChild("TextTab"))
local PillButton = require(components:WaitForChild("PillButton"))
local ConfirmButton = require(components:WaitForChild("ConfirmButton"))
local SearchBox = require(components:WaitForChild("SearchBox"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Icon = require(components:WaitForChild("Icon"))
local Parts = require(script.Parent:WaitForChild("Parts"))
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))
local OutfitPreview = require(script.Parent:WaitForChild("OutfitPreview"))
local HudContext = require(views:WaitForChild("HudContext"))

local e = React.createElement

local SEARCH_WIDTH = 270
local LEFT_WIDTH = 300

-- An outfit as the screens see it, whichever source it came from.
type OutfitView = {
	id: number?, -- a saved outfit's id (Mine); nil for placeholders
	name: string,
	by: string,
	items: { number },
}

-- Wearing exactly this outfit: the same items, nothing more or less.
local function wearingExactly(look: any, items: { number }): boolean
	if #items == 0 or #items ~= #look.worn then
		return false
	end
	for _, id in items do
		if not look.isWorn(id) then
			return false
		end
	end
	return true
end

local function outfitsFor(look: any, source: string): { OutfitView }
	local list: { OutfitView } = {}
	if source == "Mine" then
		for _, outfit in look.outfits do
			table.insert(list, { id = outfit.id, name = outfit.name, by = "Your outfit", items = outfit.items })
		end
	else
		for _, outfit in (PlaceholderData.outfits :: any)[source] or {} do
			table.insert(list, { id = nil, name = outfit.name, by = outfit.by, items = outfit.items })
		end
	end
	return list
end

local function findOutfit(look: any, source: string, index: number): OutfitView?
	if source == "Mine" then
		for _, outfit in look.outfits do
			if outfit.id == index then
				return { id = outfit.id, name = outfit.name, by = "Your outfit", items = outfit.items }
			end
		end
		return nil
	end
	local outfit = ((PlaceholderData.outfits :: any)[source] or {})[index]
	return if outfit then { id = nil, name = outfit.name, by = outfit.by, items = outfit.items } else nil
end

-- Up to four item thumbnails in a 2×2 grid (items with pictures first).
local function mosaic(items: { number }): { [string]: any }
	local images = {}
	for _, id in items do
		local image = Parts.image(PlaceholderData.item(id))
		if image then
			table.insert(images, image)
			if #images == 4 then
				break
			end
		end
	end
	local cells: { [string]: any } = {}
	for index, image in images do
		local column, row = (index - 1) % 2, (index - 1) // 2
		local single = #images == 1
		cells["Cell" .. index] = e("ImageLabel", {
			AnchorPoint = if single then Vector2.new(0.5, 0.5) else Vector2.zero,
			Position = if single then UDim2.fromScale(0.5, 0.5) else UDim2.fromScale(0.04 + column * 0.48, 0.04 + row * 0.48),
			Size = if single then UDim2.fromScale(0.9, 0.9) else UDim2.fromScale(0.44, 0.44),
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
		})
	end
	return cells
end

local function OutfitCard(props: {
	outfit: OutfitView,
	sub: string,
	ring: boolean,
	onActivated: () -> (),
	layoutOrder: number,
})
	local skin = useSkin()
	local interaction = useInteraction()
	local first = PlaceholderData.item(props.outfit.items[1])
	local cells = mosaic(props.outfit.items)
	return e("TextButton", {
		Name = "OutfitCard",
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
			colour = Parts.swatch(if first then first.colour else ""),
			radius = 14,
			hovered = interaction.hovered,
			selected = props.ring,
			caption = if next(cells) then nil else "outfit",
		}, {
			Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }),
			Mosaic = e(React.Fragment, nil, cells),
		}),
		Meta = e("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, skin.px(36)),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(2)) }),
			Name = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, skin.textPx(13.5) + skin.px(2)),
				BackgroundTransparency = 1,
				Text = props.outfit.name,
				TextColor3 = Tokens.color.white,
				TextSize = skin.textPx(13.5),
				FontFace = Tokens.font(800),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 1,
			}),
			Sub = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, skin.textPx(12) + skin.px(2)),
				BackgroundTransparency = 1,
				Text = props.sub,
				TextColor3 = Tokens.color.white,
				TextTransparency = Tokens.alpha.textDim,
				TextSize = skin.textPx(12),
				FontFace = Tokens.font(700),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
			}),
		}),
	})
end

-- The first Mine card: save what you're wearing as a new outfit.
local function SaveCard(props: { count: number, onActivated: () -> (), layoutOrder: number })
	local skin = useSkin()
	local interaction = useInteraction()
	local orange = Tokens.color.accentText
	return e("TextButton", {
		Name = "SaveCard",
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
		Well = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Tokens.color.accent,
			BackgroundTransparency = if interaction.hovered then 0.86 else 0.94,
			BorderSizePixel = 0,
		}, {
			Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }),
			Corner = e("UICorner", { CornerRadius = UDim.new(0, skin.px(14)) }),
			Stroke = e("UIStroke", {
				Color = orange,
				Transparency = 0.3,
				Thickness = skin.stroke(1.5),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, skin.px(4)),
			}),
			Icon = e(Icon, { name = "add_circle", size = 36, color = orange, layoutOrder = 1 }),
			Label = e("TextLabel", {
				Size = UDim2.new(1, -skin.px(12), 0, skin.textPx(13) * 2 + skin.px(2)),
				BackgroundTransparency = 1,
				Text = "Save what I'm wearing",
				TextColor3 = orange,
				TextSize = skin.textPx(13),
				FontFace = Tokens.font(900),
				TextWrapped = true,
				LayoutOrder = 2,
			}),
		}),
		Meta = e("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, skin.px(36)),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(2)) }),
			Name = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, skin.textPx(13.5) + skin.px(2)),
				BackgroundTransparency = 1,
				Text = "New outfit",
				TextColor3 = Tokens.color.white,
				TextSize = skin.textPx(13.5),
				FontFace = Tokens.font(800),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			Sub = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, skin.textPx(12) + skin.px(2)),
				BackgroundTransparency = 1,
				Text = props.count .. " items",
				TextColor3 = Tokens.color.white,
				TextTransparency = Tokens.alpha.textDim,
				TextSize = skin.textPx(12),
				FontFace = Tokens.font(700),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}),
		}),
	})
end

local function OutfitsScreen(props: { nav: any, look: any })
	local skin = useSkin()
	local look = props.look
	local source, setSource = useSessionState("outfits.source", "Mine")
	local query, setQuery = useSessionState("outfits.query", "")

	local tabs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(22)),
		}),
	}
	for index, name in PlaceholderData.outfitSources do
		tabs["Tab" .. index] = e(TextTab, {
			label = name,
			active = name == source,
			layoutOrder = index,
			onActivated = function()
				setSource(name)
			end,
		})
	end

	local needle = string.lower(query)
	local cards: { [string]: any } = {}
	local count = 0
	if source == "Mine" then
		count += 1
		cards.Save = e(SaveCard, {
			count = #look.worn,
			layoutOrder = 0,
			onActivated = look.saveOutfit,
		})
	end
	for index, outfit in outfitsFor(look, source) do
		if needle ~= "" and not string.find(string.lower(outfit.name), needle, 1, true) then
			continue
		end
		count += 1
		cards["Outfit" .. index] = e(OutfitCard, {
			outfit = outfit,
			sub = if source == "Mine" then #outfit.items .. " items" else "by " .. outfit.by,
			ring = wearingExactly(look, outfit.items),
			layoutOrder = index,
			onActivated = function()
				props.nav.push({
					kind = "outfit",
					id = { source = source, index = outfit.id or index },
					label = outfit.name,
				})
			end,
		})
	end

	local tabsHeight = skin.px(Tokens.size.textTabHeight)
	local searchWidth = skin.px(SEARCH_WIDTH)
	return e("Frame", {
		Name = "OutfitsScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Top = e("Frame", {
			Size = UDim2.new(1, 0, 0, tabsHeight),
			BackgroundTransparency = 1,
		}, {
			Tabs = e("Frame", {
				Size = UDim2.new(1, -(searchWidth + skin.px(16)), 1, 0),
				BackgroundTransparency = 1,
			}, tabs),
			Rule = e("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, -(searchWidth + skin.px(16)), 0, skin.stroke(1)),
				BackgroundColor3 = Tokens.color.white,
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
			}),
			Search = e(SearchBox, {
				text = query,
				placeholder = if source == "Roblox" then "Search a username" else "Search outfits",
				onChange = setQuery,
				anchorPoint = Vector2.new(1, 0.5),
				position = UDim2.fromScale(1, 0.5),
				size = UDim2.fromOffset(searchWidth, skin.px(40)),
			}),
		}),
		Grid = e(Parts.CardGrid, {
			columns = 5,
			extraHeight = 40,
			count = count,
			position = UDim2.fromOffset(0, tabsHeight + skin.px(14)),
			size = UDim2.new(1, 0, 1, -(tabsHeight + skin.px(14))),
			scrollKey = "outfits|" .. source .. "|" .. query,
		}, cards),
	})
end

-- A row's checkbox: orange with a tick when selected.
local function Checkbox(props: { on: boolean, onToggle: () -> () })
	local skin = useSkin()
	local function toggle()
		Sounds.play("press")
		props.onToggle()
	end
	return e("TextButton", {
		Name = "Checkbox",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(skin.px(28), skin.px(28)),
		BackgroundColor3 = if props.on then Tokens.color.accent else Color3.fromHex("#111111"),
		AutoButtonColor = false,
		Text = "",
		[React.Event.InputBegan] = Press.began(toggle),
		[React.Event.Activated] = Press.activated(toggle),
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, skin.px(8)) }),
		Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Tick = if props.on
			then e(Icon, {
				name = "check",
				size = 19,
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
			})
			else nil,
	})
end

-- The outfit's name: a saved outfit's can be edited in place (renamed when
-- the box loses focus).
local function NameField(props: { name: string, editable: boolean, onRename: (name: string) -> () })
	local skin = useSkin()
	local style = { size = 24, weight = 900 }
	if not props.editable then
		return e(ShadowText, { text = props.name, style = style, maxWidth = skin.px(LEFT_WIDTH), layoutOrder = 2 })
	end
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, skin.textPx(24) + skin.px(6)),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, {
		Box = e("TextBox", {
			Size = UDim2.new(1, -skin.px(26), 1, 0),
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			Text = props.name,
			TextColor3 = Tokens.color.white,
			TextSize = skin.textPx(24),
			FontFace = Tokens.font(900),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			[React.Event.FocusLost] = function(box: TextBox)
				local text = box.Text
				if text ~= props.name and string.match(text, "%S") then
					props.onRename(text)
				else
					box.Text = props.name
				end
			end,
		}),
		Pencil = e(Icon, {
			name = "edit",
			size = 18,
			transparency = 0.45,
			anchorPoint = Vector2.new(1, 0.5),
			position = UDim2.fromScale(1, 0.5),
		}),
	})
end

local function smallIcon(name: string, color: Color3, order: number)
	return e(Icon, { name = name, size = 20, color = color, layoutOrder = order })
end

local function OutfitScreen(props: { nav: any, look: any, source: string, index: number })
	local skin = useSkin()
	local hud = React.useContext(HudContext)
	local look = props.look
	local outfit = findOutfit(look, props.source, props.index)
	-- Selected rows by position; everything starts selected.
	local deselected, setDeselected = React.useState({} :: { [number]: boolean })

	-- Find out what's owned, for prices and the Buy label.
	React.useEffect(function()
		if outfit then
			look.checkOwned(outfit.items)
		end
		return nil
	end, { props.source, props.index })

	-- Keep the breadcrumb in step with a rename.
	React.useEffect(function()
		local top = props.nav.top
		if outfit and top and top.kind == "outfit" and top.label ~= outfit.name then
			props.nav.replaceTop({ kind = top.kind, id = top.id, label = outfit.name })
		end
		return nil
	end, { outfit and outfit.name })

	if not outfit then
		-- Deleted (or gone): nothing to show; the Delete handler goes back.
		return e("Frame", { Name = "OutfitScreen", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	end

	local items = outfit.items
	local selected: { number } = {} -- positions
	local selectedIds: { number } = {}
	local cost = 0
	for index, id in items do
		if not deselected[index] then
			table.insert(selected, index)
			table.insert(selectedIds, id)
			local item = PlaceholderData.item(id)
			if item and not item.owned then
				cost += item.price
			end
		end
	end
	local allSelected = #selected == #items
	local ring = wearingExactly(look, items)

	local rows: { [string]: any } = {
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(6)) }),
		-- Inset so row strokes at the edges aren't clipped by the ScrollingFrame.
		Inset = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(3)),
			PaddingBottom = UDim.new(0, skin.px(3)),
			PaddingLeft = UDim.new(0, skin.px(3)),
			PaddingRight = UDim.new(0, skin.px(8)),
		}),
	}
	for index, id in items do
		local item = PlaceholderData.item(id)
		if not item then
			continue
		end
		local on = not deselected[index]
		rows["Row" .. index] = e(Parts.ListRow, {
			title = item.name,
			subtitle = item.main .. " · " .. item.sub,
			colour = Parts.swatch(item.colour),
			image = Parts.image(item),
			layoutOrder = index,
			trailingWidth = 150,
			leading = e(Checkbox, {
				on = on,
				onToggle = function()
					setDeselected(function(current: { [number]: boolean })
						local result = table.clone(current)
						result[index] = if on then true else nil
						return result
					end)
				end,
			}),
			trailing = {
				Price = e(Parts.PriceTag, { item = item, size = 14, layoutOrder = 1 }),
				Wearing = if look.isWorn(id) then smallIcon("checkroom", Tokens.color.accentText, 2) else nil,
				InBasket = if look.inBasket(id) then smallIcon("shopping_basket", Tokens.color.white, 3) else nil,
			},
			onActivated = function()
				props.nav.push({ kind = "item", id = id, label = item.name })
			end,
		})
	end

	local function bottomButton(label: string, icon: string, order: number, disabled: boolean, onActivated: () -> (), extra: { [string]: any }?)
		local button = {
			variant = "pill",
			size = Tokens.size.ctaHeight,
			label = label,
			icon = icon,
			iconSize = 18,
			disabled = disabled,
			sound = false, -- each action plays its own sound
			onActivated = onActivated,
		}
		for key, value in extra or {} do
			(button :: any)[key] = value
		end
		return e("Frame", {
			Size = UDim2.new(1 / 3, -skin.px(6), 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = order,
		}, { Button = e(PillButton, button :: any) })
	end

	local saved = outfit.id ~= nil
	local outfitId = outfit.id
	local leftWidth = skin.px(LEFT_WIDTH)
	local buttonsHeight = skin.px(Tokens.size.ctaHeight)
	local headerHeight = skin.px(26)

	return e("Frame", {
		Name = "OutfitScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Left = e("Frame", {
			Size = UDim2.new(0, leftWidth, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, skin.px(10)),
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
			Preview = e("Frame", {
				-- Whatever height the details below leave.
				Size = UDim2.new(1, 0, 1, -(skin.textPx(24) + skin.px(6) + skin.px(18) + buttonsHeight * (if saved then 2 else 1) + skin.px(10) * (if saved then 4 else 3))),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				View = if saved and outfitId
					then e(OutfitPreview, { outfitId = outfitId, ring = ring })
					else e(Parts.Thumb, {
						colour = Parts.swatch(""),
						radius = 20,
						caption = if next(mosaic(items)) then nil else "outfit preview",
						selected = ring,
					}, mosaic(items)),
			}),
			Name = e(NameField, {
				name = outfit.name,
				editable = saved,
				onRename = function(name: string)
					if outfitId then
						look.renameOutfit(outfitId, name)
					end
				end,
			}),
			By = e("Frame", {
				Size = UDim2.new(1, 0, 0, skin.px(18)),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				Text = e(ShadowText, {
					text = outfit.by .. " · " .. #items .. " items",
					style = Tokens.type.meta,
					transparency = Tokens.alpha.textSoft,
					shadow = false,
				}),
			}),
			WearAll = e(PillButton, {
				variant = "pill",
				size = Tokens.size.ctaHeight,
				icon = "checkroom",
				iconSize = 18,
				label = "Wear all",
				active = true,
				sound = false, -- the look change plays its own sound
				layoutOrder = 4,
				onActivated = function()
					if outfitId then
						look.wearOutfit(outfitId)
					else
						look.wearAll(items)
					end
				end,
			}),
			Delete = if saved
				then e(ConfirmButton, {
					label = "Delete outfit",
					icon = "delete",
					armedLabel = "Tap again to delete",
					layoutOrder = 5,
					onConfirm = function()
						if outfitId then
							look.deleteOutfit(outfitId)
							props.nav.back()
						end
					end,
				})
				else nil,
		}),
		Right = e("Frame", {
			Position = UDim2.fromOffset(leftWidth + skin.px(20), 0),
			Size = UDim2.new(1, -(leftWidth + skin.px(20)), 1, 0),
			BackgroundTransparency = 1,
		}, {
			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, headerHeight),
				BackgroundTransparency = 1,
			}, {
				Count = e(ShadowText, {
					text = #items .. " items · " .. #selected .. " selected",
					style = { size = 17, weight = 900 },
				}),
				Toggle = e("TextButton", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(0, skin.px(110), 1, 0),
					BackgroundTransparency = 1,
					Text = if allSelected then "Select none" else "Select all",
					TextColor3 = Tokens.color.accentText,
					TextSize = skin.textPx(13.5),
					FontFace = Tokens.font(800),
					TextXAlignment = Enum.TextXAlignment.Right,
					[React.Event.InputBegan] = Press.began(function()
						Sounds.play("press")
						if allSelected then
							local none = {}
							for index in items do
								none[index] = true
							end
							setDeselected(none)
						else
							setDeselected({})
						end
					end),
				}),
			}),
			Rows = e("ScrollingFrame", {
				Position = UDim2.fromOffset(0, headerHeight + skin.px(10)),
				Size = UDim2.new(1, 0, 1, -(headerHeight + skin.px(10) + buttonsHeight + skin.px(10))),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, #items * (skin.px(64) + skin.px(6)) + skin.px(6)),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = skin.px(8),
				ScrollBarImageColor3 = Tokens.color.accent,
				VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			}, rows),
			Buttons = e("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, buttonsHeight),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, skin.px(8)),
				}),
				WearSelected = bottomButton("Wear selected", "checkroom", 1, #selected == 0, function()
					if outfitId then
						look.wearOutfitItems(outfitId, selected)
					else
						look.wearAll(selectedIds)
					end
				end),
				Basket = bottomButton("Add to basket", "add_shopping_cart", 2, #selected == 0, function()
					local unowned = {}
					for _, id in selectedIds do
						local item = PlaceholderData.item(id)
						if item and not item.owned then
							table.insert(unowned, id)
						end
					end
					look.addToBasket(unowned)
				end),
				Buy = bottomButton(
					if cost > 0 then "Buy · " .. Tokens.robux(cost) else "Buy",
					"toll",
					3,
					#selected == 0,
					function()
						hud.buy(selectedIds, "outfit")
					end,
					{ loading = hud.buying("outfit") }
				),
			}),
		}),
	})
end

return {
	Root = OutfitsScreen,
	Outfit = OutfitScreen,
}

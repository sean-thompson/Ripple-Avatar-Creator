--!strict

--[[
	FullPanel (design frames 5b–5h: the full-screen panel's chrome)

	Covers the world when a tab, Basket or Wearing is open:
	  · tab bar (tapping the open tab closes the panel) and close button
	  · left column: avatar-preview card with Undo and a "Wearing · N" bar
	    (opens Wearing), and the Basket card with count + CTA (opens Basket);
	    each card gets the orange border while its screen is open
	  · content area: breadcrumbs/back once deeper than a tab (always on the
	    Basket / Wearing lists), then the current screen

	Swallows input so nothing underneath reacts. The avatar preview is a
	placeholder until Task 6.

	Motion: Hud drives `t` (0 closed → 1 open) — the background fades in and
	the body drops into place and fades (CanvasGroup); the tab bar stays put so
	it reads as the same bar as the world HUD's. Each screen slides in when it
	mounts (keyed by where we are), and the basket/wearing counts roll.

	Props:
		nav: useNavigation.Navigation
		look: usePlaceholderLook.Look
		tabs: { PillTabs.Tab }
		t: binding?   open progress (default fully open)
		closing: boolean?   the panel is animating out — drop the tab bar and
		                    close button at once (the world HUD's own tab bar
		                    takes over), only the body fades
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local screens = views:WaitForChild("screens")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useInteraction = require(hooks:WaitForChild("useInteraction"))
local useAppear = require(hooks:WaitForChild("useAppear"))
local useSpringNumber = require(hooks:WaitForChild("useSpringNumber"))
local PillButton = require(components:WaitForChild("PillButton"))
local PillTabs = require(components:WaitForChild("PillTabs"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local Icon = require(components:WaitForChild("Icon"))
local ShadowText = require(components:WaitForChild("ShadowText"))
local Breadcrumbs = require(script.Parent:WaitForChild("Breadcrumbs"))
local Sounds = require(views:WaitForChild("Sounds"))
local Press = require(views:WaitForChild("Press"))
local CatalogueScreen = require(screens:WaitForChild("CatalogueScreen"))
local ItemScreen = require(screens:WaitForChild("ItemScreen"))
local StoresScreen = require(screens:WaitForChild("StoresScreen"))
local OutfitsScreen = require(screens:WaitForChild("OutfitsScreen"))
local ListScreens = require(screens:WaitForChild("ListScreens"))

local e = React.createElement

local LEFT_WIDTH = 250
local BASKET_CARD = 112
local GAP = 16

-- Full-size invisible button so a whole card is tappable under its contents.
local function cardButton(onActivated: () -> (), onEnter: () -> (), onLeave: () -> ())
	return e("TextButton", {
		Name = "Hit",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 0,
		[React.Event.InputBegan] = Press.began(onActivated),
		[React.Event.Activated] = Press.activated(onActivated),
		[React.Event.MouseEnter] = onEnter,
		[React.Event.MouseLeave] = onLeave,
	})
end

local function PreviewCard(props: { nav: any, look: any, openList: (root: string) -> () })
	local skin = useSkin()
	local interaction = useInteraction()
	local selected = props.nav.root == "Wearing"
	local undo = Tokens.size.undo
	local wornCount = useSpringNumber(#props.look.worn, Tokens.spring.count)
	return e(GlassPanel, {
		variant = "light",
		cornerRadius = Tokens.radius.contentPanel,
		borderColor = if selected or interaction.hovered then Tokens.color.accent else nil,
		borderTransparency = if selected then 0 elseif interaction.hovered then 1 - 0.8 else nil,
		size = UDim2.new(1, 0, 1, -skin.px(BASKET_CARD + 12)),
	}, {
		Hit = cardButton(function()
			props.openList("Wearing")
		end, interaction.onEnter, interaction.onLeave),
		Placeholder = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "avatar preview",
			TextColor3 = Tokens.color.white,
			TextTransparency = 1 - 0.45,
			TextSize = skin.textPx(12),
			FontFace = Tokens.font(700),
		}),
		Undo = e(PillButton, {
			variant = "round",
			size = undo.size,
			icon = "undo",
			iconSize = undo.icon,
			glowRadius = undo.glow,
			anchorPoint = Vector2.new(1, 0),
			position = UDim2.new(1, -skin.px(10), 0, skin.px(10)),
			zIndex = 3,
		}),
		WearingBar = e(GlassPanel, {
			variant = "bar",
			cornerRadius = Tokens.size.wearingBar / 2,
			anchorPoint = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -skin.px(10)),
			size = UDim2.new(1, -skin.px(20), 0, skin.px(Tokens.size.wearingBar)),
			zIndex = 2,
		}, {
			Padding = e("UIPadding", { PaddingLeft = UDim.new(0, skin.px(14)), PaddingRight = UDim.new(0, skin.px(10)) }),
			Icon = e(Icon, {
				name = "checkroom",
				size = 19,
				color = Tokens.color.accentText,
				anchorPoint = Vector2.new(0, 0.5),
				position = UDim2.fromScale(0, 0.5),
			}),
			Label = e("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, skin.px(25), 0.5, 0),
				Size = UDim2.new(1, -skin.px(50), 0, skin.textPx(Tokens.type.bodyStrong.size)),
				BackgroundTransparency = 1,
			}, {
				Text = e(ShadowText, { text = "Wearing · " .. wornCount, style = Tokens.type.bodyStrong }),
			}),
			Chevron = e(Icon, {
				name = "chevron_right",
				size = 20,
				anchorPoint = Vector2.new(1, 0.5),
				position = UDim2.fromScale(1, 0.5),
			}),
		}),
	})
end

local function BasketCard(props: { nav: any, look: any, openList: (root: string) -> () })
	local skin = useSkin()
	local interaction = useInteraction()
	local selected = props.nav.root == "Basket"
	local total = useSpringNumber(props.look.basketTotal, Tokens.spring.count)
	local count = useSpringNumber(#props.look.basket, Tokens.spring.count)
	return e(GlassPanel, {
		variant = "light",
		cornerRadius = Tokens.radius.basketCard,
		borderColor = if selected or interaction.hovered then Tokens.color.accent else nil,
		borderTransparency = if selected then 0 elseif interaction.hovered then 1 - 0.8 else nil,
		anchorPoint = Vector2.new(0, 1),
		position = UDim2.fromScale(0, 1),
		size = UDim2.new(1, 0, 0, skin.px(BASKET_CARD)),
	}, {
		Hit = cardButton(function()
			props.openList("Basket")
		end, interaction.onEnter, interaction.onLeave),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(12)),
			PaddingBottom = UDim.new(0, skin.px(12)),
			PaddingLeft = UDim.new(0, skin.px(14)),
			PaddingRight = UDim.new(0, skin.px(12)),
		}),
		Icon = e(Icon, { name = "shopping_basket", size = 20, color = Tokens.color.accentText }),
		Title = e("Frame", {
			Position = UDim2.fromOffset(skin.px(26), 0),
			Size = UDim2.fromOffset(skin.px(100), skin.px(20)),
			BackgroundTransparency = 1,
		}, {
			Text = e(ShadowText, { text = "Basket", style = Tokens.type.cardTitle }),
		}),
		Count = e("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(skin.px(100), skin.px(20)),
			BackgroundTransparency = 1,
			Text = count .. " items",
			TextColor3 = Tokens.color.white,
			TextTransparency = Tokens.alpha.textDim,
			TextSize = skin.textPx(Tokens.type.small.size),
			FontFace = Tokens.font(800),
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
		Cta = e(PillButton, {
			variant = "pill",
			size = Tokens.size.ctaHeight,
			label = if total > 0 then "Open basket · " .. total .. " R$" else "Open basket",
			icon = "chevron_right",
			iconSize = 20,
			iconAfter = true,
			active = true,
			anchorPoint = Vector2.new(0, 1),
			position = UDim2.fromScale(0, 1),
			zIndex = 3,
			sound = false, -- openList plays the switch
			onActivated = function()
				props.openList("Basket")
			end,
		}),
	})
end

-- The page pushed on top of the root (item, store, outfit), or nil.
local function deepScreen(nav: any, look: any)
	local top = nav.top
	if top then
		if top.kind == "item" then
			return e(ItemScreen, { nav = nav, look = look, itemId = top.id })
		elseif top.kind == "store" then
			return e(StoresScreen.Store, { nav = nav, look = look, storeId = top.id })
		elseif top.kind == "outfit" then
			return e(OutfitsScreen.Outfit, { nav = nav, look = look, source = top.id.source, index = top.id.index })
		end
	end
	return nil
end

local function rootScreen(nav: any, look: any)
	if nav.root == "Catalogue" then
		return e(CatalogueScreen, { nav = nav, look = look })
	elseif nav.root == "Stores" then
		return e(StoresScreen.Root, { nav = nav, look = look })
	elseif nav.root == "Outfits" then
		return e(OutfitsScreen.Root, { nav = nav, look = look })
	elseif nav.root == "Basket" then
		return e(ListScreens.Basket, { nav = nav, look = look })
	elseif nav.root == "Wearing" then
		return e(ListScreens.Wearing, { nav = nav, look = look })
	end
	return nil
end

-- Slides its screen in from the right when it mounts.
local function ScreenAppear(props: { children: any })
	local skin = useSkin()
	local t = useAppear(Tokens.spring.screen)
	return e("Frame", {
		Name = "ScreenAppear",
		Position = t:map(function(v: number)
			return UDim2.fromOffset((1 - v) * skin.px(Tokens.motion.screenSlide), 0)
		end),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, props.children)
end

export type Props = {
	nav: any,
	look: any,
	tabs: { any },
	t: any?,
	closing: boolean?,
}

local function FullPanel(props: Props)
	local skin = useSkin()
	local nav = props.nav
	local isList = nav.root == "Basket" or nav.root == "Wearing"
	local hasCrumbs = #nav.stack > 0 or isList
	local crumbsHeight = if hasCrumbs then skin.px(Tokens.size.back.size + 12) else 0
	local close = Tokens.size.close

	-- The root screen stays mounted (hidden) under pushed pages, so going back
	-- returns to it as it was: same tab, chip, search, filters, loaded items
	-- and scroll. Pushed pages are keyed by where we are, so each one starts
	-- fresh. Switching tab or closing the panel resets the root.
	local deep = deepScreen(nav, props.look)
	local deepKey = (nav.root or "") .. "/" .. #nav.stack .. "/" .. (if nav.top then nav.top.label else "")
	local open = props.t or React.createBinding(1)
	local baseTransparency = if skin.glass == "blur" then 0.25 else 0
	local margin = skin.px(6)

	-- Basket / Wearing from inside the open panel: same "switch" as changing tab.
	local function openList(root: string)
		if nav.root ~= root then
			Sounds.play("switch")
		end
		nav.openRoot(root)
	end

	return e("Frame", {
		Name = "FullPanel",
		Size = UDim2.fromScale(1, 1),
		Active = true, -- swallow input so nothing beneath reacts
		BackgroundColor3 = Tokens.color.white,
		-- With blur glass, the blurred world shows faintly through.
		BackgroundTransparency = open:map(function(t: number)
			return 1 - (1 - baseTransparency) * math.clamp(t, 0, 1)
		end),
		BorderSizePixel = 0,
		ZIndex = 10,
	}, {
		Gradient = e("UIGradient", { Color = Tokens.gradient.fullPanel, Rotation = Tokens.gradient.rotation }),
		Tabs = if props.closing then nil else e(PillTabs, {
			tabs = props.tabs,
			activeId = if isList then nil else nav.root,
			sound = false,
			onSelect = function(id: string)
				-- Tapping the open tab closes the panel (Hud plays "close");
				-- any other tab switches windows.
				if id ~= nav.root then
					Sounds.play("switch")
				end
				nav.toggleTab(id)
			end,
			anchorPoint = Vector2.new(0.5, 0),
			position = UDim2.new(0.5, 0, 0, skin.px(16)),
			zIndex = 12,
		}),
		Close = if props.closing then nil else e(PillButton, {
			variant = "round",
			size = close.size,
			icon = "close",
			iconSize = close.icon,
			glowRadius = close.glow,
			sound = false, -- closing the panel plays its own sound
			anchorPoint = Vector2.new(1, 0),
			position = UDim2.new(1, -skin.px(Tokens.size.edgeInset), 0, skin.px(16)),
			onActivated = nav.close,
			zIndex = 12,
		}),
		-- CanvasGroup (for the fade) clips at its bounds, so it's grown by a
		-- margin and padded back in — card outlines sit just outside their edges.
		Body = e("CanvasGroup", {
			Position = open:map(function(t: number)
				return UDim2.fromOffset(skin.px(28) - margin, skin.px(84) - margin - (1 - t) * skin.px(Tokens.motion.panelDrop))
			end),
			Size = UDim2.new(1, -skin.px(56) + margin * 2, 1, -skin.px(84 + 24) + margin * 2),
			GroupTransparency = open:map(function(t: number)
				return 1 - math.clamp(t, 0, 1)
			end),
			BackgroundTransparency = 1,
			ZIndex = 11,
		}, {
			Margin = e("UIPadding", {
				PaddingTop = UDim.new(0, margin),
				PaddingBottom = UDim.new(0, margin),
				PaddingLeft = UDim.new(0, margin),
				PaddingRight = UDim.new(0, margin),
			}),
			Left = e("Frame", {
				Size = UDim2.new(0, skin.px(LEFT_WIDTH), 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 11,
			}, {
				Preview = e(PreviewCard, { nav = nav, look = props.look, openList = openList }),
				Basket = e(BasketCard, { nav = nav, look = props.look, openList = openList }),
			}),
			Content = e(GlassPanel, {
				variant = "light",
				cornerRadius = Tokens.radius.contentPanel,
				position = UDim2.fromOffset(skin.px(LEFT_WIDTH + GAP), 0),
				size = UDim2.new(1, -skin.px(LEFT_WIDTH + GAP), 1, 0),
				zIndex = 11,
			}, {
				Padding = e("UIPadding", {
					PaddingTop = UDim.new(0, skin.px(14)),
					PaddingBottom = UDim.new(0, skin.px(14)),
					PaddingLeft = UDim.new(0, skin.px(16)),
					PaddingRight = UDim.new(0, skin.px(16)),
				}),
				Crumbs = if hasCrumbs
					then e(Breadcrumbs, {
						rootLabel = nav.root :: string,
						stack = nav.stack,
						onBack = nav.back,
						onPopTo = nav.popTo,
					})
					else nil,
				Screen = e("Frame", {
					Position = UDim2.fromOffset(0, crumbsHeight),
					Size = UDim2.new(1, 0, 1, -crumbsHeight),
					BackgroundTransparency = 1,
				}, {
					["Root/" .. (nav.root or "")] = e("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Visible = deep == nil,
					}, {
						Appear = e(ScreenAppear, nil, { Screen = rootScreen(nav, props.look) }),
					}),
					[deepKey] = if deep then e(ScreenAppear, nil, { Screen = deep }) else nil,
				}),
			}),
		}),
	})
end

return FullPanel

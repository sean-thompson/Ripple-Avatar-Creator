--!strict

--[[
	GalleryHudMock (THROWAWAY — Task 1 skin gallery)

	Design frame 5a rebuilt from the skin kit with no behaviour behind it:
	tab bar, Basket + action buttons, World options toggle and side panel,
	a toast, and a simplified full-panel frame (frame 5b chrome) — so the skin
	can be judged in place on each device and sizing mode.

	All geometry is design px through useSkin().px, pinned to corners the way
	the design pins them, so the same code exercises every sizing mode.

	Props:
		onFullPanelChanged: (open: boolean) -> ()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local PillButton = require(components:WaitForChild("PillButton"))
local PillTabs = require(components:WaitForChild("PillTabs"))
local GlassPanel = require(components:WaitForChild("GlassPanel"))
local Badge = require(components:WaitForChild("Badge"))
local TextTab = require(components:WaitForChild("TextTab"))
local Chip = require(components:WaitForChild("Chip"))
local Icon = require(components:WaitForChild("Icon"))
local ShadowText = require(components:WaitForChild("ShadowText"))

local e = React.createElement

export type Props = {
	onFullPanelChanged: (open: boolean) -> (),
}

local TABS = {
	{ id = "Catalogue", label = "Catalogue", icon = "apparel" },
	{ id = "Stores", label = "Stores", icon = "storefront" },
	{ id = "Outfits", label = "Outfits", icon = "checkroom" },
}

local CATEGORIES = { "Featured", "Halloween", "Hair", "Clothing", "Accessories", "Head & Body", "Animations", "Emotes" }
local SUBS = { "All", "New", "Trending" }
local SKIES = { "Clear", "Clouds", "Studio", "Void" }
local PATTERNS = { "Grid", "Checker", "Plain" }

local function label(_skin, text: string, style: Tokens.TypeStyle, order: number, color: Color3?, transparency: number?)
	return e(ShadowText, {
		text = text,
		style = style,
		color = color,
		transparency = transparency,
		shadow = false,
		layoutOrder = order,
	})
end

local function row(skin, order: number, height: number, gap: number, children: { [string]: any })
	children.Layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, skin.px(gap)),
	})
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, skin.px(height)),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, children)
end

-- Static slider: track, orange fill, white knob (World options).
local function slider(skin, order: number, fraction: number)
	local knob = skin.px(22)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, knob),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Track = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, skin.px(6)),
			BackgroundColor3 = Tokens.color.inputWell,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Fill = e("Frame", {
				Size = UDim2.fromScale(fraction, 1),
				BackgroundColor3 = Tokens.color.accent,
				BorderSizePixel = 0,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
		}),
		Knob = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(fraction, 0.5),
			Size = UDim2.fromOffset(knob, knob),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Gradient = e("UIGradient", { Color = Tokens.gradient.knob, Rotation = Tokens.gradient.rotation }),
			Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1) }),
		}),
	})
end

local function toggle(skin, on: boolean, onActivated: () -> ())
	local w, h, k = skin.px(50), skin.px(28), skin.px(22)
	return e("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = if on then Tokens.color.white else Tokens.color.toggleOff,
		AutoButtonColor = false,
		Text = "",
		[React.Event.Activated] = onActivated,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Gradient = if on then e("UIGradient", { Color = Tokens.gradient.orange, Rotation = Tokens.gradient.rotation }) else nil,
		Stroke = e("UIStroke", { Color = Tokens.color.black, Thickness = skin.stroke(1) }),
		Knob = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, if on then w - k - skin.px(3) else skin.px(2), 0.5, 0),
			Size = UDim2.fromOffset(k, k),
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Gradient = e("UIGradient", { Color = Tokens.gradient.knob, Rotation = Tokens.gradient.rotation }),
		}),
	})
end

local function WorldPanel(props: { onClose: () -> () })
	local skin = useSkin()
	local sky, setSky = React.useState("Clear")
	local floor, setFloor = React.useState(1)
	local pattern, setPattern = React.useState("Grid")
	local shadows, setShadows = React.useState(true)

	local skyButtons: { [string]: any } = {}
	for index, name in SKIES do
		skyButtons[name] = e(PillButton, {
			variant = "pill",
			size = 36,
			width = 70,
			label = name,
			textStyle = Tokens.type.small,
			active = sky == name,
			layoutOrder = index,
			onActivated = function()
				setSky(name)
			end,
		})
	end

	local floorSwatches: { [string]: any } = {}
	for index, color in Tokens.floorSwatches do
		local selected = floor == index
		floorSwatches["Swatch" .. index] = e("TextButton", {
			Size = UDim2.fromOffset(skin.px(36), skin.px(36)),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			[React.Event.Activated] = function()
				setFloor(index)
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			-- Inferred: CSS double ring `0 0 0 2px #111, 0 0 0 4px #ffa64d` → one accent stroke.
			Ring = e("UIStroke", {
				Color = if selected then Tokens.color.accentText else Tokens.color.black,
				Thickness = skin.stroke(if selected then 3 else 1),
			}),
		})
	end

	local patternButtons: { [string]: any } = {}
	for index, name in PATTERNS do
		patternButtons[name] = e(PillButton, {
			variant = "pill",
			size = 36,
			width = 94,
			label = name,
			textStyle = Tokens.type.small,
			active = pattern == name,
			layoutOrder = index,
			onActivated = function()
				setPattern(name)
			end,
		})
	end

	return e(GlassPanel, {
		variant = "dark",
		cornerRadius = Tokens.radius.sidePanel,
		shadow = true,
		anchorPoint = Vector2.new(1, 0),
		position = UDim2.new(1, -skin.px(Tokens.size.edgeInset), 0, skin.px(88)),
		size = UDim2.new(0, skin.px(Tokens.size.sidePanelWidth), 1, -skin.px(88 + 112)),
		zIndex = 5,
	}, {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, skin.px(14)),
			PaddingBottom = UDim.new(0, skin.px(18)),
			PaddingLeft = UDim.new(0, skin.px(18)),
			PaddingRight = UDim.new(0, skin.px(14)),
		}),
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(14)) }),
		Header = e("Frame", {
			Size = UDim2.new(1, 0, 0, skin.px(36)),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Title = row(skin, 1, 36, 8, {
				Icon = e(Icon, { name = "landscape", size = 22, color = Tokens.color.accentIcon, layoutOrder = 1 }),
				Text = label(skin, "World options", Tokens.type.panelTitle, 2),
			}),
			Close = e(PillButton, {
				variant = "round",
				size = Tokens.size.small.size,
				icon = "close",
				iconSize = Tokens.size.small.icon,
				anchorPoint = Vector2.new(1, 0),
				position = UDim2.fromScale(1, 0),
				onActivated = props.onClose,
			}),
		}),
		TimeLabel = row(skin, 2, 20, 0, {
			Label = label(skin, "Time of day", Tokens.type.sectionLabel, 1),
			Value = e("TextLabel", {
				Size = UDim2.new(1, -skin.px(100), 1, 0),
				BackgroundTransparency = 1,
				Text = "13:00",
				TextColor3 = Tokens.color.accentText,
				TextSize = skin.textPx(Tokens.type.sectionLabel.size),
				FontFace = Tokens.font(800),
				TextXAlignment = Enum.TextXAlignment.Right,
				LayoutOrder = 2,
			}),
		}),
		TimeSlider = slider(skin, 3, 13 / 24),
		SkyLabel = label(skin, "Sky", Tokens.type.sectionLabel, 4),
		Skies = row(skin, 5, 36, 6, skyButtons),
		FloorLabel = label(skin, "Floor", Tokens.type.sectionLabel, 6),
		Floors = row(skin, 7, 36, 10, floorSwatches),
		Patterns = row(skin, 8, 36, 6, patternButtons),
		LightLabel = label(skin, "Lighting", Tokens.type.sectionLabel, 9),
		LightSlider = slider(skin, 10, 0.5),
		Shadows = e("Frame", {
			Size = UDim2.new(1, 0, 0, skin.px(28)),
			BackgroundTransparency = 1,
			LayoutOrder = 11,
		}, {
			Label = row(skin, 1, 28, 0, {
				Text = label(skin, "Shadows", Tokens.type.bodyStrong, 1),
			}),
			Toggle = toggle(skin, shadows, function()
				setShadows(not shadows)
			end),
		}),
		Hint = row(skin, 12, 20, 6, {
			Icon = e(Icon, { name = "flight", size = 18, color = Tokens.color.accentText, layoutOrder = 1 }),
			Text = label(skin, "Double-jump to fly. Use it to find a quiet spot.", Tokens.type.hint, 2, nil, Tokens.alpha.textSoft),
		}),
	})
end

local function Toast(props: { text: string })
	local skin = useSkin()
	return e(GlassPanel, {
		variant = "bar",
		cornerRadius = Tokens.size.toastHeight / 2,
		shadow = true,
		anchorPoint = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, skin.px(84)),
		size = UDim2.fromOffset(skin.px(250), skin.px(Tokens.size.toastHeight)),
		zIndex = 20,
	}, {
		Padding = e("UIPadding", { PaddingLeft = UDim.new(0, skin.px(12)), PaddingRight = UDim.new(0, skin.px(18)) }),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, skin.px(7)),
		}),
		Icon = e(Icon, { name = "check_circle", size = 20, color = Tokens.color.accentText, layoutOrder = 1 }),
		Text = label(skin, props.text, Tokens.type.toast, 2),
	})
end

local function FullPanel(props: { activeTab: string, onSelectTab: (string) -> (), onClose: () -> () })
	local skin = useSkin()
	local category, setCategory = React.useState("Featured")
	local sub, setSub = React.useState("All")

	local catTabs: { [string]: any } = {}
	for index, name in CATEGORIES do
		catTabs["Cat" .. index] = e(TextTab, {
			label = name,
			active = category == name,
			layoutOrder = index,
			onActivated = function()
				setCategory(name)
			end,
		})
	end

	local chips: { [string]: any } = {}
	for index, name in SUBS do
		chips["Sub" .. index] = e(Chip, {
			label = name,
			active = sub == name,
			layoutOrder = index,
			onActivated = function()
				setSub(name)
			end,
		})
	end

	local cards: { [string]: any } = {
		Grid = e("UIGridLayout", {
			CellSize = UDim2.new(1 / 6, -skin.px(10), 0, skin.px(118)),
			CellPadding = UDim2.fromOffset(skin.px(12), skin.px(12)),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	local swatchList = { Tokens.swatch.Orange, Tokens.swatch.Purple, Tokens.swatch.Blue, Tokens.swatch.Pink, Tokens.swatch.Green }
	for index = 1, 12 do
		cards["Card" .. index] = e("Frame", {
			BackgroundColor3 = Tokens.color.white,
			BorderSizePixel = 0,
			LayoutOrder = index,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, skin.px(Tokens.radius.itemCard)) }),
			-- Placeholder tint, as the mock's cards: linear-gradient(160deg, colour55, #1c1c1c 75%).
			Gradient = e("UIGradient", {
				Rotation = 70,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, swatchList[(index - 1) % #swatchList + 1]:Lerp(Color3.fromRGB(28, 28, 28), 0.66)),
					ColorSequenceKeypoint.new(0.75, Color3.fromRGB(28, 28, 28)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 28)),
				}),
			}),
			Wearing = if index % 4 == 1
				then e(Badge, {
					kind = "marker",
					tone = "orange",
					icon = "checkroom",
					position = UDim2.fromOffset(skin.px(6), skin.px(6)),
				})
				else nil,
			InBasket = if index % 5 == 2
				then e(Badge, {
					kind = "marker",
					tone = "white",
					icon = "shopping_basket",
					position = UDim2.fromOffset(skin.px(6), skin.px(6)),
				})
				else nil,
		})
	end

	local closeSize = Tokens.size.close
	return e("Frame", {
		Name = "FullPanel",
		Size = UDim2.fromScale(1, 1),
		Active = true, -- swallow input so nothing beneath reacts
		BackgroundColor3 = Tokens.color.white,
		-- In "blur" glass mode the panel lets a blurred world show through
		-- (a variant to judge — the design's panel is opaque).
		BackgroundTransparency = if skin.glass == "blur" then 0.25 else 0,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, {
		Gradient = e("UIGradient", { Color = Tokens.gradient.fullPanel, Rotation = Tokens.gradient.rotation }),
		Tabs = e(PillTabs, {
			tabs = TABS,
			activeId = props.activeTab,
			onSelect = props.onSelectTab,
			anchorPoint = Vector2.new(0.5, 0),
			position = UDim2.new(0.5, 0, 0, skin.px(16)),
			zIndex = 12,
		}),
		Close = e(PillButton, {
			variant = "round",
			size = closeSize.size,
			icon = "close",
			iconSize = closeSize.icon,
			glowRadius = closeSize.glow,
			anchorPoint = Vector2.new(1, 0),
			position = UDim2.new(1, -skin.px(Tokens.size.edgeInset), 0, skin.px(16)),
			onActivated = props.onClose,
			zIndex = 12,
		}),
		Body = e("Frame", {
			Position = UDim2.fromOffset(skin.px(28), skin.px(84)),
			Size = UDim2.new(1, -skin.px(56), 1, -skin.px(84 + 24)),
			BackgroundTransparency = 1,
			ZIndex = 11,
		}, {
			Left = e("Frame", {
				Size = UDim2.new(0, skin.px(250), 1, 0),
				BackgroundTransparency = 1,
				ZIndex = 11,
			}, {
				Preview = e(GlassPanel, {
					variant = "light",
					cornerRadius = Tokens.radius.contentPanel,
					size = UDim2.new(1, 0, 1, -skin.px(112 + 12)),
					zIndex = 11,
				}, {
					Undo = e(PillButton, {
						variant = "round",
						size = Tokens.size.undo.size,
						icon = "undo",
						iconSize = Tokens.size.undo.icon,
						glowRadius = Tokens.size.undo.glow,
						anchorPoint = Vector2.new(1, 0),
						position = UDim2.new(1, -skin.px(10), 0, skin.px(10)),
						zIndex = 13,
					}),
					WearingBar = e(GlassPanel, {
						variant = "bar",
						cornerRadius = Tokens.size.wearingBar / 2,
						anchorPoint = Vector2.new(0.5, 1),
						position = UDim2.new(0.5, 0, 1, -skin.px(10)),
						size = UDim2.new(1, -skin.px(20), 0, skin.px(Tokens.size.wearingBar)),
						zIndex = 13,
					}, {
						Padding = e("UIPadding", { PaddingLeft = UDim.new(0, skin.px(14)), PaddingRight = UDim.new(0, skin.px(10)) }),
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, skin.px(6)),
						}),
						Icon = e(Icon, { name = "checkroom", size = 19, color = Tokens.color.accentText, layoutOrder = 1 }),
						Text = label(skin, "Wearing · 4", Tokens.type.bodyStrong, 2),
					}),
				}),
				BasketCard = e(GlassPanel, {
					variant = "light",
					cornerRadius = Tokens.radius.basketCard,
					anchorPoint = Vector2.new(0, 1),
					position = UDim2.fromScale(0, 1),
					size = UDim2.new(1, 0, 0, skin.px(112)),
					zIndex = 11,
				}, {
					Padding = e("UIPadding", {
						PaddingTop = UDim.new(0, skin.px(12)),
						PaddingBottom = UDim.new(0, skin.px(12)),
						PaddingLeft = UDim.new(0, skin.px(14)),
						PaddingRight = UDim.new(0, skin.px(12)),
					}),
					Title = row(skin, 1, 22, 6, {
						Icon = e(Icon, { name = "shopping_basket", size = 20, color = Tokens.color.accentText, layoutOrder = 1 }),
						Text = label(skin, "Basket", Tokens.type.cardTitle, 2),
						Count = label(skin, "3 items", Tokens.type.small, 3, nil, Tokens.alpha.textDim),
					}),
					Cta = e(PillButton, {
						variant = "pill",
						size = Tokens.size.ctaHeight,
						label = "Open basket · 160 R$",
						active = true,
						anchorPoint = Vector2.new(0, 1),
						position = UDim2.fromScale(0, 1),
						zIndex = 12,
					}),
				}),
			}),
			Content = e(GlassPanel, {
				variant = "light",
				cornerRadius = Tokens.radius.contentPanel,
				position = UDim2.fromOffset(skin.px(250 + 16), 0),
				size = UDim2.new(1, -skin.px(250 + 16), 1, 0),
				zIndex = 11,
			}, {
				Padding = e("UIPadding", {
					PaddingTop = UDim.new(0, skin.px(14)),
					PaddingBottom = UDim.new(0, skin.px(14)),
					PaddingLeft = UDim.new(0, skin.px(16)),
					PaddingRight = UDim.new(0, skin.px(16)),
				}),
				Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, skin.px(10)) }),
				Categories = row(skin, 1, Tokens.size.textTabHeight, 20, catTabs),
				Subs = row(skin, 2, Tokens.size.chipHeight, 8, chips),
				Cards = e("Frame", {
					Size = UDim2.new(1, 0, 0, skin.px(118 * 2 + 12)),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, cards),
			}),
		}),
	})
end

local function GalleryHudMock(props: Props)
	local skin = useSkin()
	local activeTab, setActiveTab = React.useState(nil :: string?)
	local worldOpen, setWorldOpen = React.useState(false)
	local toastOn, setToastOn = React.useState(true)

	-- Tapping the highlighted tab closes the panel; any other tab switches to it.
	local function selectTab(id: string)
		setActiveTab(function(current: string?)
			if current == id then
				return nil
			end
			return id
		end)
	end

	local fullOpen = activeTab ~= nil
	React.useEffect(function()
		props.onFullPanelChanged(fullOpen)
	end, { fullOpen })

	local basket = Tokens.size.basket
	local action = Tokens.size.action
	local edge = skin.px(Tokens.size.edgeInset)

	return e("Frame", {
		Name = "HudMock",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Tabs = e(PillTabs, {
			tabs = TABS,
			activeId = activeTab,
			onSelect = selectTab,
			anchorPoint = Vector2.new(0.5, 0),
			position = UDim2.new(0.5, 0, 0, skin.px(16)),
			zIndex = 2,
		}),
		-- The world HUD sits under the full panel in the design; unmount it while
		-- the panel is open so it can't show through or take hover.
		BottomLeft = if fullOpen then nil else e("Frame", {
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
					setToastOn(not toastOn)
				end,
				-- Design: top -8px, right -18px of the 84 button.
				badge = e(Badge, {
					kind = "count",
					tone = "orange",
					icon = "toll",
					text = "160",
					anchorPoint = Vector2.new(1, 0),
					position = UDim2.fromOffset(skin.px(18), -skin.px(8)),
					zIndex = 6,
				}),
			}),
			CreateAvatar = e(PillButton, {
				variant = "round",
				size = action.size,
				icon = "person_add",
				iconSize = action.icon,
				glowRadius = action.glow,
				layoutOrder = 2,
				zIndex = 2,
			}),
			SaveToRoblox = e(PillButton, {
				variant = "round",
				size = action.size,
				icon = "cloud_upload",
				iconSize = action.icon,
				glowRadius = action.glow,
				layoutOrder = 3,
				zIndex = 2,
			}),
			Reset = e(PillButton, {
				variant = "round",
				size = action.size,
				icon = "restart_alt",
				iconSize = action.icon,
				glowRadius = action.glow,
				layoutOrder = 4,
				zIndex = 2,
			}),
		}),
		WorldToggle = if fullOpen then nil else e(PillButton, {
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
		World = if worldOpen and not fullOpen
			then e(WorldPanel, {
				onClose = function()
					setWorldOpen(false)
				end,
			})
			else nil,
		Toast = if toastOn and not fullOpen then e(Toast, { text = "Trying on Witch Hat" }) else nil,
		Full = if fullOpen
			then e(FullPanel, {
				activeTab = activeTab :: string,
				onSelectTab = selectTab,
				onClose = function()
					setActiveTab(nil)
				end,
			})
			else nil,
	})
end

return GalleryHudMock

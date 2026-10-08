--!strict

--[[
	Hud

	Root of the react-luau HUD, mounted by HudApp. Owns:
	  · navigation (useNavigation) and the panel's open/close motion — the panel
	    stays mounted through its exit animation, showing the screen it had
	  · the placeholder look (worn / basket) until the server models land,
	    wrapped so every change confirms itself with a sound
	  · the buy prompt, reachable anywhere through HudContext
	  · back input (mouse back button, Backspace): closes the buy prompt, then
	    pops a breadcrumb, then closes the panel
	  · World options (saved + live draft, useWorldOptions) and the renderer
	    that applies them to this client's world

	Renders inside a SkinRoot with the Task 1 decisions: `fill` sizing scaled
	by height, `blur` glass.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local Tokens = require(views:WaitForChild("Tokens"))
local Sounds = require(views:WaitForChild("Sounds"))
local HudContext = require(views:WaitForChild("HudContext"))
local SkinRoot = require(components:WaitForChild("SkinRoot"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useGlassBlur = require(hooks:WaitForChild("useGlassBlur"))
local useNavigation = require(hooks:WaitForChild("useNavigation"))
local useBackInput = require(hooks:WaitForChild("useBackInput"))
local useTransition = require(hooks:WaitForChild("useTransition"))
local useWorldOptions = require(hooks:WaitForChild("useWorldOptions"))
local PlaceholderData = require(views:WaitForChild("screens"):WaitForChild("PlaceholderData"))
local usePlaceholderLook = require(views:WaitForChild("screens"):WaitForChild("usePlaceholderLook"))
local WorldHud = require(views:WaitForChild("WorldHud"))
local FullPanel = require(views:WaitForChild("panel"):WaitForChild("FullPanel"))
local BuyPrompt = require(views:WaitForChild("BuyPrompt"))
local WorldRenderer = require(views:WaitForChild("WorldRenderer"))

local e = React.createElement

local TABS = {
	{ id = "Catalogue", label = "Catalogue", icon = "apparel" },
	{ id = "Stores", label = "Stores", icon = "storefront" },
	{ id = "Outfits", label = "Outfits", icon = "checkroom" },
}

-- Lives inside SkinRoot so it reads the glass mode from context.
local function BlurDriver(props: { active: boolean })
	local skin = useSkin()
	useGlassBlur(props.active and skin.glass == "blur")
	return nil
end

-- Wraps the placeholder look so each change plays its sound. No toasts:
-- confirmation lives where the player is looking (the item, the avatar).
local function withFeedback(look: any)
	local feedback = table.clone(look)
	feedback.toggleWear = function(id: number)
		Sounds.play(if look.isWorn(id) then "back" else "tryOn")
		look.toggleWear(id)
	end
	feedback.toggleBasket = function(id: number)
		Sounds.play(if look.inBasket(id) then "back" else "confirm")
		look.toggleBasket(id)
	end
	feedback.wearAll = function(ids: { number })
		if #ids == 0 then
			Sounds.play("error")
			return
		end
		Sounds.play("tryOn")
		look.wearAll(ids)
	end
	feedback.takeOffAll = function()
		Sounds.play("back")
		look.takeOffAll()
	end
	return feedback
end

local function Hud()
	local nav = useNavigation()
	local rawLook = usePlaceholderLook()
	local buyIds, setBuyIds = React.useState(nil :: { number }?)
	local world = useWorldOptions()
	local look = withFeedback(rawLook)

	useBackInput(function()
		if buyIds then
			Sounds.play("back")
			setBuyIds(nil)
		elseif #nav.stack > 0 then
			Sounds.play("back")
			nav.back()
		elseif nav.isOpen then
			nav.close() -- the close sound plays from the effect below
		end
	end)

	-- Open / close sounds on panel state changes.
	local wasOpen = React.useRef(false)
	React.useEffect(function()
		if nav.isOpen ~= wasOpen.current then
			Sounds.play(if nav.isOpen then "open" else "close")
			wasOpen.current = nav.isOpen
		end
	end, { nav.isOpen })

	-- Keep the last open navigation so the panel shows its screen while leaving.
	local lastOpenNav = React.useRef(nav)
	if nav.isOpen then
		lastOpenNav.current = nav
	end
	local panelTransitions = useTransition(nav.isOpen, {
		from = { t = 0 },
		enter = { t = 1 },
		leave = { t = 0 },
		config = Tokens.spring.panelIn,
		leaveConfig = Tokens.spring.panelOut,
	})

	local actions = React.useMemo(function()
		return {
			openBuy = function(itemIds: { number })
				local unowned = {}
				for _, id in itemIds do
					if not PlaceholderData.item(id).owned then
						table.insert(unowned, id)
					end
				end
				if #unowned == 0 then
					Sounds.play("error")
					return
				end
				setBuyIds(unowned)
			end,
		}
	end, {})

	local panels: { [string]: any } = {}
	for _, transition in panelTransitions do
		panels["Panel"] = e(FullPanel, {
			nav = if nav.isOpen then nav else lastOpenNav.current,
			look = look,
			tabs = TABS,
			t = transition.springProps.t,
			closing = not nav.isOpen,
		})
	end

	return e(HudContext.Provider, { value = actions }, {
		Skin = e(SkinRoot, {
			sizing = "fill",
			axis = "height",
			glass = "blur",
		}, {
			Blur = e(BlurDriver, { active = nav.isOpen }),
			Renderer = e(WorldRenderer, { options = world.options, config = world.config }),
			World = if nav.isOpen then nil else e(WorldHud, { nav = nav, look = look, tabs = TABS, world = world }),
			Panel = e(React.Fragment, nil, panels),
			Buy = e(BuyPrompt, {
				itemIds = buyIds,
				onCancel = function()
					setBuyIds(nil)
				end,
				onConfirm = function(ids: { number })
					setBuyIds(nil)
					rawLook.markOwned(ids)
					Sounds.play("purchase")
				end,
			}),
		}),
	})
end

return Hud

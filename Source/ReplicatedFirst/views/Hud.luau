--!strict

--[[
	Hud

	Root of the react-luau HUD, mounted by HudApp. Owns:
	  · navigation (useNavigation) and the panel's open/close motion — the panel
	    stays mounted through its exit animation, showing the screen it had
	  · the placeholder look (worn / basket) until the server models land,
	    wrapped so every change confirms itself with a toast + sound
	  · the toast and the buy prompt, reachable anywhere through HudContext

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
local useTransition = require(hooks:WaitForChild("useTransition"))
local PlaceholderData = require(views:WaitForChild("screens"):WaitForChild("PlaceholderData"))
local usePlaceholderLook = require(views:WaitForChild("screens"):WaitForChild("usePlaceholderLook"))
local WorldHud = require(views:WaitForChild("WorldHud"))
local FullPanel = require(views:WaitForChild("panel"):WaitForChild("FullPanel"))
local Toast = require(views:WaitForChild("Toast"))
local BuyPrompt = require(views:WaitForChild("BuyPrompt"))

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

-- Toast state: the latest toast, auto-cleared after Tokens.motion.toastSeconds.
local function useToast()
	local toast, setToast = React.useState(nil :: { id: number, text: string, icon: string }?)
	local counter = React.useRef(0)

	local showToast = React.useCallback(function(text: string, icon: string?)
		counter.current += 1
		local id = counter.current
		-- No sound of its own: every toast comes from an action that plays one.
		setToast({ id = id, text = text, icon = icon or "check_circle" })
		task.delay(Tokens.motion.toastSeconds, function()
			setToast(function(current)
				if current and current.id == id then
					return nil
				end
				return current
			end)
		end)
	end, {})

	return toast, showToast
end

-- Wraps the placeholder look so each change gives feedback (prototype copy).
local function withFeedback(look: any, showToast: (string, string?) -> ())
	local feedback = table.clone(look)
	feedback.toggleWear = function(id: number)
		local item = PlaceholderData.item(id)
		if look.isWorn(id) then
			Sounds.play("back")
			showToast("Took off " .. item.name, "remove")
		else
			Sounds.play("tryOn")
			showToast("Trying on " .. item.name, "checkroom")
		end
		look.toggleWear(id)
	end
	feedback.toggleBasket = function(id: number)
		local item = PlaceholderData.item(id)
		if look.inBasket(id) then
			Sounds.play("back")
			showToast("Removed " .. item.name .. " from basket", "remove_shopping_cart")
		else
			Sounds.play("confirm")
			showToast("Added " .. item.name .. " to basket", "add_shopping_cart")
		end
		look.toggleBasket(id)
	end
	feedback.wearAll = function(ids: { number }, name: string?)
		if #ids == 0 then
			Sounds.play("error")
			showToast("Nothing to try on", "close")
			return
		end
		Sounds.play("tryOn")
		showToast(if name then "Wearing " .. name else "Trying on " .. #ids .. " items", "checkroom")
		look.wearAll(ids)
	end
	feedback.takeOffAll = function()
		Sounds.play("back")
		showToast("Took everything off", "restart_alt")
		look.takeOffAll()
	end
	return feedback
end

local function Hud()
	local nav = useNavigation()
	local rawLook = usePlaceholderLook()
	local toast, showToast = useToast()
	local buyIds, setBuyIds = React.useState(nil :: { number }?)
	local look = withFeedback(rawLook, showToast)

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
			showToast = showToast,
			openBuy = function(itemIds: { number })
				local unowned = {}
				for _, id in itemIds do
					if not PlaceholderData.item(id).owned then
						table.insert(unowned, id)
					end
				end
				if #unowned == 0 then
					Sounds.play("error")
					showToast("You already own all of that", "lock")
					return
				end
				setBuyIds(unowned)
			end,
		}
	end, { showToast })

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
			World = if nav.isOpen then nil else e(WorldHud, { nav = nav, look = look, tabs = TABS }),
			Panel = e(React.Fragment, nil, panels),
			Toast = e(Toast, { toast = toast }),
			Buy = e(BuyPrompt, {
				itemIds = buyIds,
				onCancel = function()
					setBuyIds(nil)
				end,
				onConfirm = function(ids: { number })
					setBuyIds(nil)
					rawLook.markOwned(ids)
					Sounds.play("purchase")
					showToast(
						if #ids == 1 then "Purchased " .. PlaceholderData.item(ids[1]).name else "Purchased " .. #ids .. " items",
						"check_circle"
					)
				end,
			}),
		}),
	})
end

return Hud

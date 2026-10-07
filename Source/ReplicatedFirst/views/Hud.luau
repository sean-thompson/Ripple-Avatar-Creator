--!strict

--[[
	Hud

	Root of the react-luau HUD, mounted by HudApp. Owns navigation state
	(useNavigation) and, until the server models land, the placeholder look
	(what's worn / in the basket). Renders inside a SkinRoot with the Task 1
	decisions: `fill` sizing scaled by height, `blur` glass.

	World HUD when the panel is closed; FullPanel (blurring the world behind
	it) when a tab, Basket or Wearing is open.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local SkinRoot = require(components:WaitForChild("SkinRoot"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useGlassBlur = require(hooks:WaitForChild("useGlassBlur"))
local useNavigation = require(hooks:WaitForChild("useNavigation"))
local usePlaceholderLook = require(views:WaitForChild("screens"):WaitForChild("usePlaceholderLook"))
local WorldHud = require(views:WaitForChild("WorldHud"))
local FullPanel = require(views:WaitForChild("panel"):WaitForChild("FullPanel"))

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

local function Hud()
	local nav = useNavigation()
	local look = usePlaceholderLook()

	return e(SkinRoot, {
		sizing = "fill",
		axis = "height",
		glass = "blur",
	}, {
		Blur = e(BlurDriver, { active = nav.isOpen }),
		World = if nav.isOpen then nil else e(WorldHud, { nav = nav, look = look, tabs = TABS }),
		Panel = if nav.isOpen then e(FullPanel, { nav = nav, look = look, tabs = TABS }) else nil,
	})
end

return Hud

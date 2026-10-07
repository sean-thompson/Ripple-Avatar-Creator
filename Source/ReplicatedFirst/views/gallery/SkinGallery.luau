--!strict

--[[
	SkinGallery (THROWAWAY — Task 1 skin gallery)

	Renders the HUD mock (or the kit sheet) inside a SkinRoot with the settings
	below. Mounted by HudApp as the interim HUD until Task 2's shell replaces
	it. There are no on-screen controls: change SETTINGS here and replay.

	Removal: delete the whole views/gallery folder.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local components = views:WaitForChild("components")
local hooks = views:WaitForChild("hooks")
local SkinRoot = require(components:WaitForChild("SkinRoot"))
local useSkin = require(hooks:WaitForChild("useSkin"))
local useGlassBlur = require(hooks:WaitForChild("useGlassBlur"))
local GalleryHudMock = require(script.Parent:WaitForChild("GalleryHudMock"))
local GalleryKit = require(script.Parent:WaitForChild("GalleryKit"))

local e = React.createElement

local SETTINGS = {
	page = "hud", -- "hud" | "kit"
	sizing = "fill", -- "relative" | "fit" | "fill"
	axis = "height", -- "height" | "min"
	glass = "blur", -- "translucent" | "blur"
}

-- Lives inside SkinRoot so it reads the glass mode from context.
local function BlurDriver(props: { active: boolean })
	local skin = useSkin()
	useGlassBlur(props.active and skin.glass == "blur")
	return nil
end

local function SkinGallery()
	local fullPanelOpen, setFullPanelOpen = React.useState(false)

	return e(SkinRoot, {
		sizing = SETTINGS.sizing :: any,
		glass = SETTINGS.glass :: any,
		axis = SETTINGS.axis :: any,
	}, {
		Blur = e(BlurDriver, { active = fullPanelOpen }),
		Page = if SETTINGS.page == "hud"
			then e(GalleryHudMock, { onFullPanelChanged = setFullPanelOpen })
			else e(GalleryKit),
	})
end

return SkinGallery

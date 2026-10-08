--!strict

--[[
	HudContext

	HUD-wide actions any view can reach without prop-drilling, provided by Hud:

	  showToast(text, icon?)   confirm an action with a toast (replaces the
	                           current one)
	  openBuy(itemIds)         open the buy prompt for one or more items
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

export type HudActions = {
	showToast: (text: string, icon: string?) -> (),
	openBuy: (itemIds: { number }) -> (),
}

local HudContext = React.createContext({
	showToast = function(_text: string, _icon: string?) end,
	openBuy = function(_itemIds: { number }) end,
} :: HudActions)

return HudContext

--!strict

--[[
	HudContext

	HUD-wide actions any view can reach without prop-drilling, provided by Hud:

	  openBuy(itemIds)         open the buy prompt for one or more items
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

export type HudActions = {
	openBuy: (itemIds: { number }) -> (),
}

local HudContext = React.createContext({
	openBuy = function(_itemIds: { number }) end,
} :: HudActions)

return HudContext

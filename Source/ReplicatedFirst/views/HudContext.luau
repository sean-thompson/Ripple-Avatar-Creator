--!strict

--[[
	HudContext

	HUD-wide actions any view can reach without prop-drilling, provided by Hud:

	  buy(itemIds)             buy one or more items through Roblox's own
	                           purchase prompt (owned items are skipped)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

export type HudActions = {
	buy: (itemIds: { number }) -> (),
}

local HudContext = React.createContext({
	buy = function(_itemIds: { number }) end,
} :: HudActions)

return HudContext

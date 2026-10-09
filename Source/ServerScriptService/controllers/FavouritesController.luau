--!strict

--[[
	FavouritesController

	Favouriting catalogue items. The item arrives as { targetId, kind }; the
	server checks it's a real catalogue item (AvatarService.resolve, cached)
	before saving it, and drops requests closer together than COOLDOWN.
	Favourites are tracked as analytics (a strong "likes this" signal for the
	phase-3 recommendation engine).

	Actions:
		Toggle(item)   favourite it, or un-favourite it if it already is
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbstractController = require(script.Parent.AbstractController)
local FavouritesModel = require(script.Parent.Parent.models.user.FavouritesModel)
local AvatarService = require(ServerScriptService.services.game.AvatarService)
local Network = require(ReplicatedStorage.Network)

local FavouritesController = {}
FavouritesController.__index = FavouritesController
setmetatable(FavouritesController, AbstractController)

export type FavouritesController = typeof(setmetatable({}, FavouritesController)) & AbstractController.AbstractController

local COOLDOWN = 0.25 -- seconds between a player's requests

local lastRequest: { [Player]: number } = {}

-- Lazy, like AbstractController (avoids a load-order dependency).
local analytics: any = nil
local function track(player: Player, eventName: string, params: { [string]: any })
	if analytics == nil then
		local ok, service = pcall(function()
			return require(script.Parent.Parent.services.framework.AnalyticsService)
		end)
		analytics = if ok then service else false
	end
	if analytics and analytics.isEnabled then
		analytics:trackEvent(player, eventName, params)
	end
end

local function toggle(player: Player, model: any, raw: any)
	if type(raw) ~= "table" then
		return
	end
	local targetId, kind = raw.targetId, raw.kind
	if type(targetId) ~= "number" or targetId ~= targetId or targetId <= 0 or targetId % 1 ~= 0 then
		return
	end
	if kind ~= "Asset" and kind ~= "Bundle" then
		return
	end
	local key = kind .. ":" .. targetId
	-- Un-favouriting never needs a lookup; favouriting must be a real item.
	if not model:has(key) and not AvatarService.resolve(targetId, kind) then
		return
	end
	local on = model:toggle(key)
	track(player, if on then "favourite" else "unfavourite", { item_id = targetId, item_kind = kind })
end

local ACTIONS = {
	[Network.Actions.Favourites.Toggle] = toggle,
}

function FavouritesController:executeAction(player: Player, action: Network.FavouritesAction, raw: any)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < COOLDOWN then
		return
	end
	lastRequest[player] = now
	local model = FavouritesModel.get(tostring(player.UserId))
	if not model then
		return
	end
	self:dispatchAction(ACTIONS, action, player, player, model, raw)
end

function FavouritesController.new(): FavouritesController
	local self = AbstractController.new("FavouritesController") :: any
	setmetatable(self, FavouritesController)

	self.intentEvent.OnServerEvent:Connect(function(player: Player, action: Network.FavouritesAction, raw: any)
		self:executeAction(player, action, raw)
	end)

	return self :: FavouritesController
end

return FavouritesController

--!strict

--[[
	BasketController

	Changes to the player's basket. Items arrive as { targetId, kind }; the
	server looks each one up itself (AvatarService.resolve, cached) before
	saving it, so a client can't put made-up items or names in. Each player
	gets AvatarConfig.basketBudget changes per window; past that, requests
	are dropped.

	Actions:
		Add(item)            put it in the basket
		Remove(item)         take it out
		AddMany(items)       put several in (e.g. the unowned items being worn),
		                     up to AvatarConfig.maxWearMany
		RemoveMany(items)    take several out (e.g. after buying them)
		Clear()              empty the basket

	"Try on everything" isn't here: the client sends the basket to
	AvatarController's WearMany, which already applies the slot rules.
	Adds and removes are tracked as basket_add / basket_remove analytics
	events (item id and type, a "wants this" signal for phase 3).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbstractController = require(script.Parent.AbstractController)
local BasketModel = require(script.Parent.Parent.models.user.BasketModel)
local AvatarService = require(ServerScriptService.services.game.AvatarService)
local Network = require(ReplicatedStorage.Network)

local AvatarConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AvatarConfig"))

local BasketController = {}
BasketController.__index = BasketController
setmetatable(BasketController, AbstractController)

export type BasketController = typeof(setmetatable({}, BasketController)) & AbstractController.AbstractController

-- Recent request times per player, for the budget.
local recent: { [Player]: { number } } = {}

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

local function trackAll(player: Player, eventName: string, items: { BasketModel.BasketItem })
	for _, item in items do
		track(player, eventName, { item_id = item.targetId, item_kind = item.kind, item_type = item.typeName })
	end
end

-- { targetId, kind } from the client, shape-checked (not looked up).
local function refOf(raw: any): { targetId: number, kind: "Asset" | "Bundle" }?
	if type(raw) ~= "table" then
		return nil
	end
	local targetId, kind = raw.targetId, raw.kind
	if type(targetId) ~= "number" or targetId ~= targetId or targetId <= 0 or targetId % 1 ~= 0 then
		return nil
	end
	if kind ~= "Asset" and kind ~= "Bundle" then
		return nil
	end
	return { targetId = targetId, kind = kind }
end

-- A list of refs from the client, up to maxWearMany.
local function refsOf(raw: any): { { targetId: number, kind: "Asset" | "Bundle" } }
	local refs = {}
	if type(raw) ~= "table" then
		return refs
	end
	for index, entry in raw do
		if type(index) ~= "number" or index > AvatarConfig.maxWearMany then
			continue
		end
		local ref = refOf(entry)
		if ref then
			table.insert(refs, ref)
		end
	end
	return refs
end

-- Look refs up; only real catalogue items come back. Ones already in the
-- basket skip the lookup.
local function resolveAll(model: any, refs: { { targetId: number, kind: "Asset" | "Bundle" } }): { BasketModel.BasketItem }
	local items = {}
	for _, ref in refs do
		if model:indexOf(ref.targetId, ref.kind) then
			continue
		end
		local item = AvatarService.resolve(ref.targetId, ref.kind)
		if item then
			table.insert(items, item)
		end
	end
	return items
end

local function add(player: Player, model: any, raw: any)
	local ref = refOf(raw)
	if ref then
		trackAll(player, "basket_add", model:add(resolveAll(model, { ref })))
	end
end

local function remove(player: Player, model: any, raw: any)
	local ref = refOf(raw)
	if ref then
		trackAll(player, "basket_remove", model:take({ ref }))
	end
end

local function addMany(player: Player, model: any, raw: any)
	trackAll(player, "basket_add", model:add(resolveAll(model, refsOf(raw))))
end

local function removeMany(player: Player, model: any, raw: any)
	trackAll(player, "basket_remove", model:take(refsOf(raw)))
end

local function clear(player: Player, model: any, _raw: any)
	trackAll(player, "basket_remove", model.items)
	model:clear()
end

local ACTIONS = {
	[Network.Actions.Basket.Add] = add,
	[Network.Actions.Basket.Remove] = remove,
	[Network.Actions.Basket.AddMany] = addMany,
	[Network.Actions.Basket.RemoveMany] = removeMany,
	[Network.Actions.Basket.Clear] = clear,
}

-- True if the player still has budget for a change right now.
local function allowed(player: Player): boolean
	local budget = AvatarConfig.basketBudget
	local now = os.clock()
	local times = recent[player] or {}
	recent[player] = times
	while times[1] and now - times[1] > budget.seconds do
		table.remove(times, 1)
	end
	if #times >= budget.requests then
		return false
	end
	table.insert(times, now)
	return true
end

function BasketController:executeAction(player: Player, action: Network.BasketAction, raw: any)
	if not allowed(player) then
		return
	end
	local model = BasketModel.get(tostring(player.UserId))
	if not model then
		return
	end
	self:dispatchAction(ACTIONS, action, player, player, model, raw)
end

function BasketController.new(): BasketController
	local self = AbstractController.new("BasketController") :: any
	setmetatable(self, BasketController)

	self.intentEvent.OnServerEvent:Connect(function(player: Player, action: Network.BasketAction, raw: any)
		self:executeAction(player, action, raw)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		recent[player] = nil
	end)

	return self :: BasketController
end

return BasketController

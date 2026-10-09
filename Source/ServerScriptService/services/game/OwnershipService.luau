--!strict

--[[
	OwnershipService

	Asks Roblox whether a player owns catalogue items
	(MarketplaceService:PlayerOwnsAsset / PlayerOwnsBundle) and records the
	answers in their OwnershipModel, so each item is looked up once a
	session. Lookups run in parallel; one that errors is left unknown and
	can be asked again.

	API (used by PurchaseController):
		check(player, model, refs, fresh?)   look up refs ({ targetId, kind })
		                                     not already known (all of them
		                                     when `fresh`); waits for the answers
		keyOf(targetId, kind) -> string      "Asset:123" / "Bundle:45"
]]

local MarketplaceService = game:GetService("MarketplaceService")

local OwnershipService = {}

export type Ref = { targetId: number, kind: "Asset" | "Bundle" }

function OwnershipService.keyOf(targetId: number, kind: string): string
	return kind .. ":" .. targetId
end

-- Does the player own it? nil if Roblox couldn't say.
local function lookup(player: Player, ref: Ref): boolean?
	local ok, owned = pcall(function()
		if ref.kind == "Bundle" then
			return MarketplaceService:PlayerOwnsBundle(player, ref.targetId)
		end
		return MarketplaceService:PlayerOwnsAsset(player, ref.targetId)
	end)
	if not ok then
		return nil
	end
	return owned == true
end

function OwnershipService.check(player: Player, model: any, refs: { Ref }, fresh: boolean?): ()
	local todo = {}
	for _, ref in refs do
		if fresh or not model:knows(OwnershipService.keyOf(ref.targetId, ref.kind)) then
			table.insert(todo, ref)
		end
	end
	if #todo == 0 then
		return
	end
	local results: { [string]: boolean } = {}
	local remaining = #todo
	local caller = coroutine.running()
	local waiting = false -- the caller is yielded, waiting for the last answer
	for _, ref in todo do
		task.spawn(function()
			local owned = lookup(player, ref)
			if owned ~= nil then
				results[OwnershipService.keyOf(ref.targetId, ref.kind)] = owned
			end
			remaining -= 1
			if remaining == 0 and waiting then
				task.spawn(caller)
			end
		end)
	end
	if remaining > 0 then
		waiting = true
		coroutine.yield()
	end
	if player.Parent then
		model:record(results)
	end
end

function OwnershipService.init() end

return OwnershipService

--!strict

--[[
	usePlaceholderLook

	What the avatar is wearing and what's in the basket, for the HUD's badges,
	counts, lists and buttons.

	  · Wearing is real (Task 5): it mirrors Network.State.Avatar (persisted,
	    server-authoritative), and try on / take off / wear all / take
	    everything off / undo / reset are intents to AvatarController. The
	    character itself changes on the server, so everyone sees it. Worn
	    entries are turned into items with CatalogueClient.remember.
	  · The basket is still a local stand-in until Task 10 (Basket model).

	Mock items (the prototype's placeholder data, no thumbnail) can't be
	worn: toggleWear / wearAll skip them and report it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Network = require(ReplicatedStorage:WaitForChild("Network"))

local views = script.Parent.Parent
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))
local CatalogueClient = require(views:WaitForChild("catalogue"):WaitForChild("CatalogueClient"))
local useBoltState = require(views:WaitForChild("hooks"):WaitForChild("useBoltState"))

export type Look = {
	worn: { number }, -- item ids, in the order put on
	basket: { number },
	canUndo: boolean,
	isWorn: (id: number) -> boolean,
	inBasket: (id: number) -> boolean,
	canWear: (id: number) -> boolean, -- a real catalogue item (not a mock)
	toggleWear: (id: number) -> boolean, -- false if the item can't be worn
	wearAll: (ids: { number }) -> number, -- how many could be worn
	takeOffAll: () -> (),
	undo: () -> (),
	reset: () -> (), -- back to the player's own Roblox avatar
	toggleBasket: (id: number) -> (),
	markOwned: (ids: { number }) -> (),
	basketTotal: number, -- Robux for unowned basket items
}

local DEFAULT_AVATAR = { worn = {}, canUndo = false }

local function without(list: { number }, id: number): { number }
	local result = {}
	for _, other in list do
		if other ~= id then
			table.insert(result, other)
		end
	end
	return result
end

local function canWear(id: number): boolean
	local item = PlaceholderData.item(id)
	return item ~= nil and item.thumbnail ~= ""
end

local function ref(id: number)
	local item = PlaceholderData.item(id)
	return { targetId = item.targetId, kind = item.kind }
end

local function usePlaceholderLook(): Look
	local avatar = useBoltState(Network.State.Avatar, DEFAULT_AVATAR :: any)
	-- Prototype starting basket (1-based mock ids).
	local basket, setBasket = React.useState({ 9, 31, 23 })
	local _ownedVersion, setOwnedVersion = React.useState(0)

	local worn = {}
	local wornSet = {}
	for _, entry in avatar.worn or {} do
		local item = CatalogueClient.remember(entry)
		table.insert(worn, item.id)
		wornSet[item.id] = true
	end

	local function isWorn(id: number): boolean
		return wornSet[id] == true
	end
	local function inBasket(id: number): boolean
		return table.find(basket, id) ~= nil
	end

	local total = 0
	for _, id in basket do
		local item = PlaceholderData.item(id)
		if item and not item.owned then
			total += item.price
		end
	end

	local intent = Network.Intent.Avatar
	local actions = Network.Actions.Avatar

	return {
		worn = worn,
		basket = basket,
		canUndo = avatar.canUndo == true,
		isWorn = isWorn,
		inBasket = inBasket,
		canWear = canWear,
		toggleWear = function(id: number): boolean
			if not canWear(id) then
				return false
			end
			intent:FireServer(if isWorn(id) then actions.TakeOff else actions.TryOn, ref(id))
			return true
		end,
		wearAll = function(ids: { number }): number
			local refs = {}
			for _, id in ids do
				if canWear(id) then
					table.insert(refs, ref(id))
				end
			end
			if #refs > 0 then
				intent:FireServer(actions.WearMany, refs)
			end
			return #refs
		end,
		takeOffAll = function()
			intent:FireServer(actions.TakeOffAll)
		end,
		undo = function()
			intent:FireServer(actions.Undo)
		end,
		reset = function()
			intent:FireServer(actions.Reset)
		end,
		toggleBasket = function(id: number)
			setBasket(function(current: { number })
				if table.find(current, id) then
					return without(current, id)
				end
				local result = table.clone(current)
				table.insert(result, id)
				return result
			end)
		end,
		-- Pretend purchase (Task 3 feel test; Task 11 does it for real): flags the
		-- items owned and drops them from the basket.
		markOwned = function(ids: { number })
			for _, id in ids do
				local item = PlaceholderData.item(id)
				if item then
					item.owned = true
				end
			end
			setBasket(function(current: { number })
				local result = {}
				for _, id in current do
					if not table.find(ids, id) then
						table.insert(result, id)
					end
				end
				return result
			end)
			setOwnedVersion(function(n: number)
				return n + 1
			end)
		end,
		basketTotal = total,
	}
end

return usePlaceholderLook

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
	  · Favourites are real (Task 9): Network.State.Favourites (persisted),
	    toggled through FavouritesController.
	  · The basket is real (Task 10): Network.State.Basket (persisted),
	    changed through BasketController. "Try on everything" goes to
	    AvatarController's WearMany like any wear-all.

	Mock items (the prototype's placeholder data, no thumbnail) can't be
	worn or put in the basket: the intents skip them and report it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Network = require(ReplicatedStorage:WaitForChild("Network"))

local views = script.Parent.Parent
local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))
local CatalogueClient = require(views:WaitForChild("catalogue"):WaitForChild("CatalogueClient"))
local useBoltState = require(views:WaitForChild("hooks"):WaitForChild("useBoltState"))

local AvatarConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AvatarConfig"))

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
	isFavourite: (id: number) -> boolean,
	toggleFavourite: (id: number) -> boolean, -- false for mock items
	toggleBasket: (id: number) -> boolean, -- false for mock items
	addToBasket: (ids: { number }) -> number, -- how many were sent
	markOwned: (ids: { number }) -> (),
	basketTotal: number, -- Robux for unowned basket items
}

local DEFAULT_AVATAR = { worn = {}, canUndo = false }
local DEFAULT_FAVOURITES = { items = {} }
local DEFAULT_BASKET = { items = {} }

-- An item's favourites key: "Asset:123" / "Bundle:45" (nil for mock items).
local function favouriteKey(id: number): string?
	local item = PlaceholderData.item(id)
	if not item or item.thumbnail == "" then
		return nil
	end
	return item.kind .. ":" .. item.targetId
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
	local favourites = useBoltState(Network.State.Favourites, DEFAULT_FAVOURITES :: any)
	local favouriteSet = {}
	for _, key in favourites.items or {} do
		favouriteSet[key] = true
	end
	local basketState = useBoltState(Network.State.Basket, DEFAULT_BASKET :: any)
	local _ownedVersion, setOwnedVersion = React.useState(0)

	-- Re-render when a worn or basket item's details (name, price) arrive.
	React.useEffect(function()
		local connection = CatalogueClient.changed:Connect(function()
			setOwnedVersion(function(n: number)
				return n + 1
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	local worn = {}
	local wornSet = {}
	for _, entry in avatar.worn or {} do
		local item = CatalogueClient.remember(entry)
		table.insert(worn, item.id)
		wornSet[item.id] = true
	end

	local basket = {}
	local basketSet = {}
	for _, entry in basketState.items or {} do
		local item = CatalogueClient.remember(entry)
		table.insert(basket, item.id)
		basketSet[item.id] = true
	end

	local function isWorn(id: number): boolean
		return wornSet[id] == true
	end
	local function inBasket(id: number): boolean
		return basketSet[id] == true
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
			-- The server takes up to maxWearMany; keep the most recent.
			while #refs > AvatarConfig.maxWearMany do
				table.remove(refs, 1)
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
		isFavourite = function(id: number): boolean
			local key = favouriteKey(id)
			return key ~= nil and favouriteSet[key] == true
		end,
		toggleFavourite = function(id: number): boolean
			if not favouriteKey(id) then
				return false
			end
			Network.Intent.Favourites:FireServer(Network.Actions.Favourites.Toggle, ref(id))
			return true
		end,
		toggleBasket = function(id: number): boolean
			if not canWear(id) then
				return false
			end
			local basketActions = Network.Actions.Basket
			Network.Intent.Basket:FireServer(if inBasket(id) then basketActions.Remove else basketActions.Add, ref(id))
			return true
		end,
		addToBasket = function(ids: { number }): number
			local refs = {}
			for _, id in ids do
				if canWear(id) and not inBasket(id) then
					table.insert(refs, ref(id))
				end
			end
			if #refs > 0 then
				Network.Intent.Basket:FireServer(Network.Actions.Basket.AddMany, refs)
			end
			return #refs
		end,
		-- Pretend purchase (Task 3 feel test; Task 11 does it for real): flags the
		-- items owned and takes them out of the basket.
		markOwned = function(ids: { number })
			local refs = {}
			for _, id in ids do
				local item = PlaceholderData.item(id)
				if item then
					item.owned = true
					if canWear(id) and inBasket(id) then
						table.insert(refs, ref(id))
					end
				end
			end
			if #refs > 0 then
				Network.Intent.Basket:FireServer(Network.Actions.Basket.RemoveMany, refs)
			end
			setOwnedVersion(function(n: number)
				return n + 1
			end)
		end,
		basketTotal = total,
	}
end

return usePlaceholderLook

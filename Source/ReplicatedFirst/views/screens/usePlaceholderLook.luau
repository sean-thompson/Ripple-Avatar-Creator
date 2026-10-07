--!strict

--[[
	usePlaceholderLook (Task 2 — replaced by server models in Tasks 5 and 10)

	Local stand-in for what the avatar is wearing and what's in the basket, so
	the shell's badges, counts and lists behave believably. Slot rules follow
	the prototype: one item per slot (hair is a single slot; clothing and head
	by sub-category), while accessories and emotes stack.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local PlaceholderData = require(script.Parent:WaitForChild("PlaceholderData"))

export type Look = {
	worn: { number },
	basket: { number },
	isWorn: (id: number) -> boolean,
	inBasket: (id: number) -> boolean,
	toggleWear: (id: number) -> (),
	wearAll: (ids: { number }) -> (),
	takeOffAll: () -> (),
	toggleBasket: (id: number) -> (),
	basketTotal: number, -- Robux for unowned basket items
}

local function slotKey(item: PlaceholderData.Item): string?
	if item.main == "Accessories" or item.main == "Emotes" then
		return nil -- these stack
	elseif item.main == "Hair" then
		return "Hair"
	end
	return item.main .. "/" .. item.sub
end

local function wearOne(worn: { number }, id: number): { number }
	local item = PlaceholderData.item(id)
	local key = slotKey(item)
	local result = {}
	for _, other in worn do
		if other ~= id and (key == nil or slotKey(PlaceholderData.item(other)) ~= key) then
			table.insert(result, other)
		end
	end
	table.insert(result, id)
	return result
end

local function without(list: { number }, id: number): { number }
	local result = {}
	for _, other in list do
		if other ~= id then
			table.insert(result, other)
		end
	end
	return result
end

local function usePlaceholderLook(): Look
	-- Prototype starting state (1-based ids).
	local worn, setWorn = React.useState({ 6, 13, 26, 34 })
	local basket, setBasket = React.useState({ 9, 31, 23 })

	local function isWorn(id: number): boolean
		return table.find(worn, id) ~= nil
	end
	local function inBasket(id: number): boolean
		return table.find(basket, id) ~= nil
	end

	local total = 0
	for _, id in basket do
		local item = PlaceholderData.item(id)
		if not item.owned then
			total += item.price
		end
	end

	return {
		worn = worn,
		basket = basket,
		isWorn = isWorn,
		inBasket = inBasket,
		toggleWear = function(id: number)
			setWorn(function(current: { number })
				if table.find(current, id) then
					return without(current, id)
				end
				return wearOne(current, id)
			end)
		end,
		wearAll = function(ids: { number })
			setWorn(function(current: { number })
				local result = current
				for _, id in ids do
					result = wearOne(result, id)
				end
				return result
			end)
		end,
		takeOffAll = function()
			setWorn({})
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
		basketTotal = total,
	}
end

return usePlaceholderLook

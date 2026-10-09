--!strict

--[[
	BasketModel (User scope — persisted per player)

	The items the player means to buy, oldest first, saved across sessions.
	Each entry is the same short record as a worn item ({ targetId, kind,
	typeName, name }); prices aren't saved, so clients always show the
	catalogue's current price. Capped at AvatarConfig.basketLimit; past the
	cap the oldest item drops off.

	Items arrive already resolved and validated by BasketController.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbstractModel = require(script.Parent.Parent.AbstractModel)

local AvatarConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AvatarConfig"))

local BasketModel = {}
BasketModel.__index = BasketModel
setmetatable(BasketModel, AbstractModel)

export type BasketItem = {
	targetId: number,
	kind: "Asset" | "Bundle",
	typeName: string,
	name: string,
}

export type BasketModel = typeof(setmetatable({} :: {
	items: { BasketItem },
}, BasketModel)) & AbstractModel.AbstractModel

function BasketModel.new(ownerId: string): BasketModel
	local self = AbstractModel.new("BasketModel", ownerId, "User") :: any
	setmetatable(self, BasketModel)
	self.items = {}
	return self :: BasketModel
end

function BasketModel.get(ownerId: string): BasketModel?
	return AbstractModel.getOrWait("BasketModel", ownerId, function()
		return BasketModel.new(ownerId)
	end) :: BasketModel?
end

function BasketModel.remove(ownerId: string): ()
	AbstractModel.removeInstance("BasketModel", ownerId)
end

function BasketModel:indexOf(targetId: number, kind: string): number?
	for index, item in self.items do
		if item.targetId == targetId and item.kind == kind then
			return index
		end
	end
	return nil
end

-- Add the items not already in the basket. Returns the ones added.
function BasketModel:add(items: { BasketItem }): { BasketItem }
	local added = {}
	for _, item in items do
		if not self:indexOf(item.targetId, item.kind) then
			table.insert(self.items, {
				targetId = item.targetId,
				kind = item.kind,
				typeName = item.typeName,
				name = item.name,
			})
			table.insert(added, item)
		end
	end
	if #added > 0 then
		while #self.items > AvatarConfig.basketLimit do
			table.remove(self.items, 1)
		end
		self:syncState()
	end
	return added
end

-- Remove these { targetId, kind } items. Returns the ones removed.
function BasketModel:take(refs: { { targetId: number, kind: string } }): { BasketItem }
	local removed = {}
	for _, ref in refs do
		local index = self:indexOf(ref.targetId, ref.kind)
		if index then
			table.insert(removed, table.remove(self.items, index))
		end
	end
	if #removed > 0 then
		self:syncState()
	end
	return removed
end

function BasketModel:clear(): ()
	if #self.items > 0 then
		self.items = {}
		self:syncState()
	end
end

return BasketModel

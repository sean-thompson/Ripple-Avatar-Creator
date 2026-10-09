--!strict

--[[
	FavouritesModel (User scope — persisted per player)

	The player's favourite catalogue items, as keys "Asset:123" /
	"Bundle:45" (an asset and a bundle can share an id), most recent last.
	Capped at MAX_ITEMS so the saved record stays small; past the cap the
	oldest favourite drops off. (Favourite stores join this in Task 18.)

	Keys arrive validated by FavouritesController.
]]

local AbstractModel = require(script.Parent.Parent.AbstractModel)

local FavouritesModel = {}
FavouritesModel.__index = FavouritesModel
setmetatable(FavouritesModel, AbstractModel)

local MAX_ITEMS = 500

export type FavouritesModel = typeof(setmetatable({} :: {
	items: { string },
}, FavouritesModel)) & AbstractModel.AbstractModel

function FavouritesModel.new(ownerId: string): FavouritesModel
	local self = AbstractModel.new("FavouritesModel", ownerId, "User") :: any
	setmetatable(self, FavouritesModel)
	self.items = {}
	return self :: FavouritesModel
end

function FavouritesModel.get(ownerId: string): FavouritesModel?
	return AbstractModel.getOrWait("FavouritesModel", ownerId, function()
		return FavouritesModel.new(ownerId)
	end) :: FavouritesModel?
end

function FavouritesModel.remove(ownerId: string): ()
	AbstractModel.removeInstance("FavouritesModel", ownerId)
end

function FavouritesModel:has(key: string): boolean
	return table.find(self.items, key) ~= nil
end

-- Favourite it, or un-favourite it if it already is. Returns the new state.
function FavouritesModel:toggle(key: string): boolean
	local index = table.find(self.items, key)
	if index then
		table.remove(self.items, index)
	else
		table.insert(self.items, key)
		while #self.items > MAX_ITEMS do
			table.remove(self.items, 1)
		end
	end
	self:syncState()
	return index == nil
end

return FavouritesModel

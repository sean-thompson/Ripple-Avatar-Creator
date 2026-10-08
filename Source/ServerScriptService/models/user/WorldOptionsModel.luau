--!strict

--[[
	WorldOptionsModel (User scope — persisted per player)

	The player's saved World options: time of day, sky preset, floor colour,
	pattern (+ its colour and strength), brightness and shadows. Logical state only — each client renders
	its own world from it (nothing here touches the Workspace), so one player's
	settings never reach another's screen.

	Values arrive already validated by WorldOptionsController.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbstractModel = require(script.Parent.Parent.AbstractModel)

local WorldOptionsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldOptionsConfig"))

local WorldOptionsModel = {}
WorldOptionsModel.__index = WorldOptionsModel
setmetatable(WorldOptionsModel, AbstractModel)

export type Changes = {
	time: number?,
	sky: string?,
	floor: string?,
	floorLightness: number?,
	pattern: string?,
	patternColor: string?,
	patternLightness: number?,
	patternStrength: number?,
	brightness: number?,
	shadows: boolean?,
}

export type WorldOptionsModel = typeof(setmetatable({} :: {
	time: number,
	sky: string,
	floor: string,
	floorLightness: number,
	pattern: string,
	patternColor: string,
	patternLightness: number,
	patternStrength: number,
	brightness: number,
	shadows: boolean,
}, WorldOptionsModel)) & AbstractModel.AbstractModel

local function applyDefaults(self: any)
	local defaults = WorldOptionsConfig.defaults
	self.time = defaults.time
	self.sky = defaults.sky
	self.floor = defaults.floor
	self.floorLightness = defaults.floorLightness
	self.pattern = defaults.pattern
	self.patternColor = defaults.patternColor
	self.patternLightness = defaults.patternLightness
	self.patternStrength = defaults.patternStrength
	self.brightness = defaults.brightness
	self.shadows = defaults.shadows
end

function WorldOptionsModel.new(ownerId: string): WorldOptionsModel
	local self = AbstractModel.new("WorldOptionsModel", ownerId, "User") :: any
	setmetatable(self, WorldOptionsModel)
	applyDefaults(self)
	return self :: WorldOptionsModel
end

function WorldOptionsModel.get(ownerId: string): WorldOptionsModel?
	return AbstractModel.getOrWait("WorldOptionsModel", ownerId, function()
		return WorldOptionsModel.new(ownerId)
	end) :: WorldOptionsModel?
end

function WorldOptionsModel.remove(ownerId: string): ()
	AbstractModel.removeInstance("WorldOptionsModel", ownerId)
end

-- Apply a partial set of (validated) changes.
function WorldOptionsModel:apply(changes: Changes): ()
	for key, value in changes :: { [string]: any } do
		(self :: any)[key] = value
	end
	self:syncState()
end

function WorldOptionsModel:reset(): ()
	applyDefaults(self)
	self:syncState()
end

return WorldOptionsModel

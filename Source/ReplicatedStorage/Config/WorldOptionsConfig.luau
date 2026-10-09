--!strict
-- REFERENCE COPY. The live module is Studio-authored at
-- ReplicatedStorage.Config.WorldOptionsConfig (configs aren't Rojo-synced in
-- this template — see docs/CONFIG_GUIDE.md). Keep the two in step.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigTypes = ReplicatedStorage:WaitForChild("Config"):WaitForChild("ConfigTypes")
local WorldOptionsConfigTypes = require(ConfigTypes:WaitForChild("WorldOptionsConfigTypes"))

type WorldOptionsConfig = WorldOptionsConfigTypes.WorldOptionsConfig

local config: WorldOptionsConfig = {
	timeMin = 0,
	timeMax = 24,
	timeStep = 0.25,
	brightnessMin = 0,
	brightnessMax = 200,
	brightnessStep = 5,
	skies = { "Clear", "Clouds", "Studio", "Void" },
	patterns = { "Grid", "Studs", "Checker" },
	-- Both palettes share one order: orange, yellow, green, teal, purple, white.
	-- No black: each colour has a lightness multiplier that takes it down to
	-- black. Orange is the place's own Baseplate colour (the default floor).
	-- Saved as the hex itself, so reordering never swaps choices.
	floorColors = { "#cc5f00", "#f2c94c", "#3fbf8a", "#26a6b5", "#7a5cff", "#e9e6e1" },
	-- Pattern drawn over the floor: colour + lightness, texture + strength.
	-- Defaults match the modern baseplate: black grid (white at 0% lightness)
	-- at 0.8 transparency (20% strength).
	patternColors = { "#cc5f00", "#f2c94c", "#3fbf8a", "#26a6b5", "#7a5cff", "#ffffff" },
	lightnessMin = 0,
	lightnessMax = 100,
	lightnessStep = 5,
	patternStrengthMin = 0,
	patternStrengthMax = 100,
	patternStrengthStep = 5,
	defaults = {
		time = 14.5, -- the place's Lighting.ClockTime
		sky = "Clear",
		floor = "#cc5f00",
		floorLightness = 100,
		pattern = "Grid",
		patternColor = "#ffffff",
		patternLightness = 0,
		patternStrength = 20,
		brightness = 100,
		shadows = true,
	},
	flight = {
		enabled = true,
		speed = 40,
		climbSpeed = 24,
		doubleJumpWindow = 0.5,
	},
	sprint = {
		enabled = true,
		walkSpeed = 16, -- Roblox's default
		runSpeed = 28,
		flightMultiplier = 1.75,
	},
}

return config

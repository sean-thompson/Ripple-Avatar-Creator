--!strict

--[[
	Network - Central networking module using Bolt

	This module provides:
	- Auto-generation of Bolt ReliableEvents for controller intents
	- Auto-generation of Bolt RemoteProperties for model state
	- Type-safe action constants and state types
	- Single source of truth for all networking (replaces IntentActions + StateEvents)

	To add new controllers or models, simply add them to NetworkConfig below.

	Usage in Controllers:
		local Network = require(ReplicatedStorage.Network)
		self.intentEvent = Network.registerIntent("CashMachine")

	Usage in Models:
		local Network = require(ReplicatedStorage.Network)
		self._stateProperty = Network.registerState("Inventory", defaultState)

	Usage in Views:
		local Network = require(ReplicatedStorage.Network)
		local cashMachineIntent = Network.Intent.CashMachine
		cashMachineIntent:FireServer(Network.Actions.CashMachine.Withdraw, amount)

		local inventoryState = Network.State.Inventory
		inventoryState:Observe(function(data) ... end)
]]

-- WaitForChild, not direct indexing: Network is required very early from
-- ReplicatedFirst (HudApp), before ReplicatedStorage is guaranteed to have
-- replicated its siblings to the client. Direct indexing raised an intermittent
-- "Bolt is not a valid member of ReplicatedStorage" on startup.
local Bolt = require(script.Parent:WaitForChild("Bolt"))
local NetworkBuilder = require(script.Parent:WaitForChild("NetworkBuilder"))

-- ============================================================================
-- GAME CONFIGURATION: Add new controllers and models here
-- ============================================================================

-- Network Configuration: Single source of truth for all controllers and state
local NetworkConfig = {
	Controllers = {
		Avatar = { "TryOn", "TakeOff", "WearMany", "TakeOffAll", "Undo", "Reset" },
		Bazaar = { "BuyTreasure" },
		CashMachine = { "Withdraw", "Deposit" },
		Shrine = { "Donate" },
		SlashCommand = {},  -- No actions, just the intent
		WorldOptions = { "Set", "Reset" },
	},

	States = {
		-- What the player is wearing (persisted; AvatarModel). `worn` is a list
		-- of { targetId, kind, typeName, name } in the order put on.
		Avatar = {
			ownerId = "",
			worn = {},
			seeded = false,
			canUndo = false,
		},
		Candles = {
			ownerId = "",
			modelId = "",
			creator = "",
			positionX = 0,
			positionY = 0,
			positionZ = 0,
			createdTime = 0,
		},
		Favours = {
			ownerId = "",
			modelId = "",
			favourType = "",
		},
		Inventory = {
			ownerId = "",
			gold = 0,
			treasure = 0,
			favourIds = {},
		},
		Shrine = {
			ownerId = "",
			treasure = 0,
			userId = "",
		},
		SlashCommand = {
			ownerId = "",
			message = "",
		},
		-- Defaults mirror WorldOptionsConfig.defaults (the model loads them).
		WorldOptions = {
			ownerId = "",
			time = 14.5,
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
	},
}

-- ============================================================================
-- BUILD NETWORK MODULE (Engine code - do not modify)
-- ============================================================================

local Network = NetworkBuilder.build(NetworkConfig, Bolt)

-- ============================================================================
-- TYPE EXPORTS: Add type definitions for new actions and states
-- ============================================================================

-- Action Type Exports (manually defined for type safety)
export type AvatarAction = "TryOn" | "TakeOff" | "WearMany" | "TakeOffAll" | "Undo" | "Reset"
export type BazaarAction = "BuyTreasure"
export type CashMachineAction = "Withdraw" | "Deposit"
export type ShrineAction = "Donate"
export type WorldOptionsAction = "Set" | "Reset"

-- State Type Exports (manually defined for type safety)
export type WornItem = {
	targetId: number, -- the catalogue asset / bundle id
	kind: "Asset" | "Bundle",
	typeName: string, -- AvatarAssetType / BundleType name
	name: string,
	owned: boolean?, -- known owned (it came from the player's own avatar)
}

export type AvatarState = {
	ownerId: string,
	worn: { WornItem }, -- in the order put on
	seeded: boolean, -- filled from the player's own avatar on first join
	canUndo: boolean,
}

export type CandlesState = {
	ownerId: string,
	modelId: string,
	creator: string,
	positionX: number,
	positionY: number,
	positionZ: number,
	createdTime: number,
}

export type FavoursState = {
	ownerId: string,
	modelId: string,
	favourType: string,
}

export type InventoryState = {
	ownerId: string,
	gold: number,
	treasure: number,
	favourIds: {string},
}

export type ShrineState = {
	ownerId: string,
	treasure: number,
	userId: string,
}

export type WorldOptionsState = {
	ownerId: string,
	time: number, -- ClockTime, 0..24
	sky: string, -- WorldOptionsConfig.skies
	floor: string, -- hex, one of WorldOptionsConfig.floorColors
	floorLightness: number, -- percent multiplier on the floor colour
	pattern: string, -- WorldOptionsConfig.patterns
	patternColor: string, -- hex, one of WorldOptionsConfig.patternColors
	patternLightness: number, -- percent multiplier on the pattern colour
	patternStrength: number, -- percent opacity of the pattern
	brightness: number, -- percent
	shadows: boolean,
}

-- ============================================================================

return Network

--!strict

--[[
	DebugRunner

	Sets up DebugTools authorization and delegates action discovery to
	DebugActionBuilder, which auto-generates actions from `debugActions`
	descriptor tables on each model class. No manual registration needed
	when new models are added.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugTools = require(ReplicatedStorage.Packages.DebugTools)
local DebugActionBuilder = require(script.Parent.DebugActionBuilder)

local TEST_GROUP_ID = 13711091
local MIN_RANK = 200

DebugTools.Authorization:SetAuthorizationCallback(function(player: Player)
	return player:GetRankInGroupAsync(TEST_GROUP_ID) >= MIN_RANK
end)

local modelsFolder = script.Parent.Parent.models
DebugActionBuilder.buildAll(modelsFolder)

print("[DebugRunner] Debug actions registered")

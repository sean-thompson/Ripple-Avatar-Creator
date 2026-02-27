--!strict

--[[
	DebugRunner

	Bootstraps all debug actions by requiring each module in the actions directory.
	Each action module returns a registration function that is called to register its actions.
	Authorization is restricted to members with rank >= 200 in the test group.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugTools = require(ReplicatedStorage.Packages.DebugTools)

local TEST_GROUP_ID = 13711091
local MIN_RANK = 200

DebugTools.Authorization:SetAuthorizationCallback(function(player: Player)
	return player:GetRankInGroupAsync(TEST_GROUP_ID) >= MIN_RANK
end)

local actions = script.Parent.actions

for _, actionModule in actions:GetChildren() do
	if actionModule:IsA("ModuleScript") then
		local register = require(actionModule)
		register()
	end
end

print("[DebugRunner] Debug actions registered")

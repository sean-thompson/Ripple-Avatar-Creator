--!strict

--[[
	SprintView (client, Pattern A — no server component)

	Hold Shift to run: WalkSpeed goes from sprint.walkSpeed to
	sprint.runSpeed while either Shift key is held (Roblox's Animate script
	blends walk into run by speed on its own). Flying is faster too:
	FlightView reads the character's "Sprinting" attribute and multiplies its
	speed by sprint.flightMultiplier.

	Shift is also Roblox's default shift-lock key, so shift-lock is moved to
	Ctrl (the PlayerModule's MouseLockController "BoundKeys") — still there
	for players who use it, without fighting the run key.

	Typing in a text box (chat, search) doesn't start a run. It's the
	player's own character, so the speed replicates like any movement. Turn
	it off with sprint.enabled.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local WorldOptionsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldOptionsConfig"))

local sprint = WorldOptionsConfig.sprint
if not sprint or not sprint.enabled then
	return
end

local SHIFT = { [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.RightShift] = true }
local SHIFT_LOCK_KEYS = "LeftControl,RightControl"

local player = Players.LocalPlayer
local held: { [Enum.KeyCode]: boolean } = {}

local function running(): boolean
	return next(held) ~= nil
end

local function apply()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then
		return
	end
	local on = running()
	humanoid.WalkSpeed = if on then sprint.runSpeed else sprint.walkSpeed
	character:SetAttribute("Sprinting", on)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if SHIFT[input.KeyCode] and not gameProcessed and not UserInputService:GetFocusedTextBox() then
		held[input.KeyCode] = true
		apply()
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if held[input.KeyCode] then
		held[input.KeyCode] = nil
		apply()
	end
end)

-- Losing focus (alt-tab, opening a text box) can swallow the key-up.
UserInputService.WindowFocusReleased:Connect(function()
	table.clear(held)
	apply()
end)
UserInputService.TextBoxFocused:Connect(function()
	table.clear(held)
	apply()
end)

player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	apply()
end)
if player.Character then
	task.spawn(apply)
end

-- Move shift-lock off Shift. The MouseLockController reads its keys from a
-- "BoundKeys" StringValue it creates (and listens to), so wait for it.
task.spawn(function()
	local scripts = player:WaitForChild("PlayerScripts")
	local playerModule = scripts:WaitForChild("PlayerModule", 30)
	local cameraModule = playerModule and playerModule:WaitForChild("CameraModule", 30)
	local mouseLock = cameraModule and cameraModule:WaitForChild("MouseLockController", 30)
	local boundKeys = mouseLock and mouseLock:WaitForChild("BoundKeys", 30)
	if boundKeys and boundKeys:IsA("StringValue") then
		boundKeys.Value = SHIFT_LOCK_KEYS
	else
		warn("[SprintView] Couldn't move shift-lock off Shift; it may clash with running")
	end
end)

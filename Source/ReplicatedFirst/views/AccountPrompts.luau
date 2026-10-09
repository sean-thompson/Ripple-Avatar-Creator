--!strict

--[[
	AccountPrompts

	The HUD's Save to Roblox and Create avatar buttons, through Roblox's own
	avatar-editor prompts (never imitated). Both take the look the character
	is wearing right now (Humanoid:GetAppliedDescription).

	  saveAvatar()     AvatarEditorService:PromptSaveAvatar: makes this look
	                   the player's Roblox avatar
	  createOutfit()   AvatarEditorService:PromptCreateOutfit: saves it as a
	                   new outfit in their Roblox account (our "Create avatar")

	Roblox's prompt says what happened; we only play a sound when it ends
	(success / failure; a dismissed prompt stays quiet). One prompt at a time.
]]

local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")

local Sounds = require(script.Parent:WaitForChild("Sounds"))

local AccountPrompts = {}

local open = false

local function look(): (HumanoidDescription?, Enum.HumanoidRigType?)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end
	local ok, description = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	return if ok then description else nil, humanoid.RigType
end

local function finish(result: Enum.AvatarPromptResult)
	open = false
	if result == Enum.AvatarPromptResult.Success then
		Sounds.play("confirm")
	elseif result == Enum.AvatarPromptResult.Failed then
		Sounds.play("error")
	end
end

AvatarEditorService.PromptSaveAvatarCompleted:Connect(finish)
AvatarEditorService.PromptCreateOutfitCompleted:Connect(finish)

local function prompt(show: (HumanoidDescription, Enum.HumanoidRigType) -> ())
	if open then
		return
	end
	local description, rigType = look()
	if not description or not rigType then
		Sounds.play("error")
		return
	end
	open = true
	local ok, err = pcall(show, description, rigType)
	if not ok then
		open = false
		warn("[AccountPrompts]", err)
		Sounds.play("error")
	end
end

function AccountPrompts.saveAvatar()
	prompt(function(description, rigType)
		AvatarEditorService:PromptSaveAvatar(description, rigType)
	end)
end

function AccountPrompts.createOutfit()
	prompt(function(description, rigType)
		AvatarEditorService:PromptCreateOutfit(description, rigType)
	end)
end

return AccountPrompts

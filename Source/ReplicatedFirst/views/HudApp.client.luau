--!strict

--[[
	HudApp

	Entry point for the react-luau HUD: mounts views/Hud into its OWN
	ScreenGui. Never createRoot(PlayerGui) — React clears its container's
	existing children on first render, which deletes any other ScreenGui
	already there.

	Also starts background preloads of the UI sounds and icons, so their first
	use isn't delayed by downloading the asset.
]]

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local Hud = require(script.Parent:WaitForChild("Hud"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))
local SkinAssets = require(script.Parent:WaitForChild("SkinAssets"))

Sounds.preload()
task.spawn(function()
	local icons = {}
	for _, name in SkinAssets.iconNames() do
		table.insert(icons, SkinAssets.iconImage(name) :: string)
	end
	ContentProvider:PreloadAsync(icons)
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HudApp"
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(Hud))

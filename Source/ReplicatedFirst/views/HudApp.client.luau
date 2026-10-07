--!strict

--[[
	HudApp

	Entry point for the react-luau HUD: mounts views/Hud into its OWN
	ScreenGui. Never createRoot(PlayerGui) — React clears its container's
	existing children on first render, which deletes any other ScreenGui
	already there.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local Hud = require(script.Parent:WaitForChild("Hud"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HudApp"
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(Hud))

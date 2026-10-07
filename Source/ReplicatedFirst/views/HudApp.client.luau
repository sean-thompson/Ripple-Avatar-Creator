--!strict

--[[
	HudApp

	Entry point for the react-luau HUD. Mounts into its OWN ScreenGui — not
	createRoot(PlayerGui), because React clears its container's existing
	children on first render, which deletes any other ScreenGui already there.

	Phase 1 interim: renders the Task 1 skin HUD mock (views/gallery) in place
	of the template HUD while the real shell is built (Task 2 onwards). The
	template's StatusBar/Favours/Candles views are no longer mounted; their
	files are removed in the phase 1 tidy-up.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local SkinGallery = require(script.Parent:WaitForChild("gallery"):WaitForChild("SkinGallery"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HudApp"
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(screenGui)
root:render(React.createElement(SkinGallery))

--!strict

--[[
	HudApp

	Entry point for the react-luau HUD. Mounts a single ScreenGui into PlayerGui
	containing the StatusBar (always visible) and modal windows (Favours, Candles).

	Replaces the former Studio-authored ScreenGuis and their imperative view scripts:
	- StatusBarView.client.luau → StatusBarView.luau (React)
	- FavoursView.client.luau  → FavoursView.luau  (React)
	- CandlesView.client.luau  → CandlesView.luau  (React)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local Network = require(ReplicatedStorage:WaitForChild("Network"))

local viewsFolder = script.Parent
local useBoltState = require(viewsFolder:WaitForChild("hooks"):WaitForChild("useBoltState"))
local StatusBarView = require(viewsFolder:WaitForChild("StatusBarView"))
local FavoursView = require(viewsFolder:WaitForChild("FavoursView"))
local CandlesView = require(viewsFolder:WaitForChild("CandlesView"))
local ModalWindow = require(viewsFolder:WaitForChild("components"):WaitForChild("ModalWindow"))

local e = React.createElement

local INVENTORY_DEFAULT: Network.InventoryState = {
	ownerId = "",
	gold = 0,
	treasure = 0,
	favourIds = {},
}

local FAVOURS_DEFAULT: { [string]: Network.FavoursState } = {}

local function HudApp()
	local activeModal, setActiveModal = React.useState(nil :: string?)

	local inventory = useBoltState(Network.State.Inventory, INVENTORY_DEFAULT)
	local favoursDict = useBoltState(Network.State.Favours, FAVOURS_DEFAULT)

	local toggleModal = React.useCallback(function(modalName: string)
		setActiveModal(function(current: string?)
			if current == modalName then
				return nil
			end
			return modalName
		end)
	end, {})

	local closeModal = React.useCallback(function()
		setActiveModal(nil)
	end, {})

	-- Count total favours for subtitle
	local favourCount = 0
	for _ in favoursDict do
		favourCount += 1
	end

	-- Build modal content
	local modalElement = nil
	if activeModal == "favours" then
		modalElement = e(ModalWindow, {
			title = "Favours",
			subtitle = `{favourCount} \u{00B7} BLESSINGS EARNED AT THE SHRINE`,
			gold = inventory.gold,
			treasure = inventory.treasure,
			onClose = closeModal,
			windowWidth = 560,
			windowHeight = 460,
			footerText = "Blessings earned at the shrine",
			bodyContent = e(FavoursView, {
				favoursData = favoursDict,
			}),
		})
	elseif activeModal == "candles" then
		modalElement = e(ModalWindow, {
			title = "Candles",
			subtitle = "OFFERINGS",
			gold = inventory.gold,
			treasure = inventory.treasure,
			onClose = closeModal,
			windowWidth = 520,
			windowHeight = 440,
			footerText = "Light a candle at the shrine",
			bodyContent = e(CandlesView),
		})
	end

	return e("ScreenGui", {
		Name = "HudApp",
		DisplayOrder = 100,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		StatusBar = e(StatusBarView, {
			gold = inventory.gold,
			treasure = inventory.treasure,
			activeModal = activeModal,
			onToggleModal = toggleModal,
		}),
		Modal = modalElement,
	})
end

-- Mount into PlayerGui
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local root = ReactRoblox.createRoot(playerGui)
root:render(e(HudApp))

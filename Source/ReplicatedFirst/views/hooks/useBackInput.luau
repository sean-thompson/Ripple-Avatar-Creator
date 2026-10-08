--!strict

--[[
	useBackInput

	Calls `onBack` for the "go back" inputs: the mouse's back (side) button,
	and Backspace while no text box has focus (Backspace is also the Mac
	"delete" key). Inputs Roblox has already used — typing in a text box,
	chat, the Roblox menu — are ignored.

	The mouse back button only arrives through the Input Action System
	(InputContext → InputAction → InputBinding): UserInputService.InputBegan
	never reports the mouse-button KeyCodes (a known, won't-fix legacy
	behaviour). Backspace stays on InputBegan for its gameProcessed flag.

	`onBack` is read fresh on every press, so it can close over current state.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local function useBackInput(onBack: () -> ())
	local latest = React.useRef(onBack)
	latest.current = onBack

	React.useEffect(function()
		local keyboard = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed or input.KeyCode ~= Enum.KeyCode.Backspace or UserInputService:GetFocusedTextBox() then
				return
			end
			latest.current()
		end)

		local context = Instance.new("InputContext")
		context.Name = "BackInput"
		context.Sink = false -- don't swallow the button from anything else
		local action = Instance.new("InputAction")
		action.Name = "Back"
		action.Parent = context
		local binding = Instance.new("InputBinding")
		binding.KeyCode = Enum.KeyCode.MouseBackButton
		binding.Parent = action
		-- Under the Player, which always exists here (no yield inside an effect).
		context.Parent = Players.LocalPlayer
		local mouse = action.Pressed:Connect(function()
			if not UserInputService:GetFocusedTextBox() then
				latest.current()
			end
		end)

		return function()
			keyboard:Disconnect()
			mouse:Disconnect()
			context:Destroy()
		end
	end, {})
end

return useBackInput

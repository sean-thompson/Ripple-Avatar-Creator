--!strict

--[[
	useBackInput

	Handles the "go back" inputs: the mouse's back (side) button, and
	Backspace while no text box has focus (Backspace is also the Mac "delete"
	key). Inputs Roblox has already used — typing in a text box, chat, the
	Roblox menu — are ignored.

	Handlers stack: the most recently mounted one is asked first and returns
	true if it dealt with the press, or false to pass it down. So a screen can
	close its own overlay (a card menu, a popover) before Hud pops a
	breadcrumb or closes the panel. Each handler is read fresh on every press,
	so it can close over current state.

	The mouse back button only arrives through the Input Action System
	(InputContext → InputAction → InputBinding): UserInputService.InputBegan
	never reports the mouse-button KeyCodes (a known, won't-fix legacy
	behaviour). In Studio, a plug-and-play IntelliMouse's side buttons didn't
	reach Roblox at all; the binding stays in case the live client differs.
	Backspace stays on InputBegan for its gameProcessed flag.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

type Handler = { current: () -> boolean }

local stack: { Handler } = {}
local listening = false

local function dispatch()
	if UserInputService:GetFocusedTextBox() then
		return
	end
	for index = #stack, 1, -1 do
		if stack[index].current() then
			return
		end
	end
end

-- One set of input connections for the whole client, made on first use.
local function listen()
	if listening then
		return
	end
	listening = true

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Backspace then
			dispatch()
		end
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
	context.Parent = Players.LocalPlayer -- always exists here; no yield
	action.Pressed:Connect(dispatch)
end

local function useBackInput(onBack: () -> boolean)
	local handler = React.useRef(onBack) :: Handler
	handler.current = onBack

	React.useEffect(function()
		listen()
		table.insert(stack, handler)
		return function()
			local index = table.find(stack, handler)
			if index then
				table.remove(stack, index)
			end
		end
	end, {})
end

return useBackInput

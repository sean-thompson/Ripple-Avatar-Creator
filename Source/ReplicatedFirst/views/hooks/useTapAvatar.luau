--!strict

--[[
	useTapAvatar

	Calls `onTap` when the player taps or clicks their own character in the
	world (design 5a: "Tap your avatar in the world" opens Wearing).

	  · mouse: on left-button press, like the HUD's buttons
	  · touch: on release, and only if the finger barely moved and wasn't
	    held long, so dragging to turn the camera never counts as a tap

	Presses that Roblox or the HUD already used (gameProcessed) are ignored,
	and so is everything while `enabled` is false (e.g. the panel is open).
	The hit test is a raycast from the camera through the press point that
	only considers the local character.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local TOUCH_SLOP = 12 -- pixels a tap may drift
local TOUCH_TIME = 0.35 -- seconds a tap may last
local REACH = 500 -- studs

local function hitsOwnCharacter(screenPosition: Vector3): boolean
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	if not camera or not character then
		return false
	end
	-- Input positions exclude the top-bar inset, as ScreenPointToRay expects.
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { character }
	return workspace:Raycast(ray.Origin, ray.Direction * REACH, params) ~= nil
end

local function useTapAvatar(onTap: () -> (), enabled: boolean)
	local latest = React.useRef({ onTap = onTap, enabled = enabled })
	latest.current = { onTap = onTap, enabled = enabled }

	React.useEffect(function()
		local touches: { [InputObject]: { position: Vector3, at: number } } = {}
		local began = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed or not latest.current.enabled then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if hitsOwnCharacter(input.Position) then
					latest.current.onTap()
				end
			elseif input.UserInputType == Enum.UserInputType.Touch then
				touches[input] = { position = input.Position, at = os.clock() }
			end
		end)
		local ended = UserInputService.InputEnded:Connect(function(input: InputObject)
			local start = touches[input]
			if not start then
				return
			end
			touches[input] = nil
			local quick = os.clock() - start.at <= TOUCH_TIME
			local still = (input.Position - start.position).Magnitude <= TOUCH_SLOP
			if quick and still and latest.current.enabled and hitsOwnCharacter(input.Position) then
				latest.current.onTap()
			end
		end)
		return function()
			began:Disconnect()
			ended:Disconnect()
		end
	end, {})
end

return useTapAvatar

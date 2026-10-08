--!strict

--[[
	Press

	Buttons fire on press, not release, for immediacy:

	  · mouse: on button-down
	  · touch: on touch-down — except inside a ScrollingFrame, where a touch
	    might be the start of a scroll, so it fires on release (Roblox's
	    Activated, which already cancels when the finger scrolls)
	  · gamepad / keyboard selection: on Activated, as before

	Usage — in place of `[React.Event.Activated] = onPress`:

		[React.Event.InputBegan] = Press.began(onPress),
		[React.Event.Activated] = Press.activated(onPress),

	Activated reports the input that triggered it, so presses already fired
	on down are skipped there rather than firing twice.
]]

local Press = {}

local function firesOnDown(rbx: Instance, inputType: Enum.UserInputType): boolean
	if inputType == Enum.UserInputType.MouseButton1 then
		return true
	elseif inputType == Enum.UserInputType.Touch then
		return rbx:FindFirstAncestorWhichIsA("ScrollingFrame") == nil
	end
	return false
end

function Press.began(onPress: (() -> ())?)
	return function(rbx: GuiObject, input: InputObject)
		if onPress and input.UserInputState == Enum.UserInputState.Begin and firesOnDown(rbx, input.UserInputType) then
			onPress()
		end
	end
end

function Press.activated(onPress: (() -> ())?)
	return function(rbx: GuiObject, input: InputObject?)
		if onPress and not (input and firesOnDown(rbx, input.UserInputType)) then
			onPress()
		end
	end
end

return Press

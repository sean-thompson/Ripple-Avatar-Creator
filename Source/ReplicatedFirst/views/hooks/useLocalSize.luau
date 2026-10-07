--!strict

--[[
	useLocalSize

	Tracks a GuiObject's size in LOCAL units — design px under a SkinRoot
	canvas (AbsoluteSize divided by the canvas scale), real px in relative
	mode. Use it to lay out things Roblox can't size for us under a UIScale
	(grid cells, scroll extents) instead of AutomaticSize/AutomaticCanvasSize.

	Usage:
		local ref = React.useRef(nil :: GuiObject?)
		local size = useLocalSize(ref)
		e("Frame", { ref = ref, ... })
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local useSkin = require(script.Parent:WaitForChild("useSkin"))

local function useLocalSize(ref: { current: GuiObject? }): Vector2
	local skin = useSkin()
	local absolute, setAbsolute = React.useState(Vector2.zero)

	React.useEffect(function()
		local instance = ref.current
		if not instance then
			return
		end
		setAbsolute(instance.AbsoluteSize)
		local connection = instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			setAbsolute(instance.AbsoluteSize)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return Vector2.new(skin.fromScreen(absolute.X), skin.fromScreen(absolute.Y))
end

return useLocalSize

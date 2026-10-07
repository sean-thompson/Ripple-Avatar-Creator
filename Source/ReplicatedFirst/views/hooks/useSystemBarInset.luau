--!strict

--[[
	useSystemBarInset

	The top-left area Roblox's own top-bar buttons occupy, in REAL screen
	pixels. That UI is fixed-size, so a design-px reservation scaled down for a
	phone would overlap it — convert with useSkin().fromScreen before laying
	anything out against it.

	GuiService.TopbarInset is the UNOCCUPIED part of the top bar, so Roblox's
	buttons span x = 0..TopbarInset.Min.X and y = 0..TopbarInset.Max.Y.
	It reads as zero outside Play (e.g. Edit mode); then we fall back to the
	design's placeholder (Tokens.size.systemBar) in raw pixels.

	Returns: { width: number, height: number, measured: boolean }
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local Tokens = require(script.Parent.Parent:WaitForChild("Tokens"))

export type SystemBarInset = {
	width: number,
	height: number,
	measured: boolean,
}

local function read(): SystemBarInset
	local inset = GuiService.TopbarInset
	if inset.Min.X > 0 and inset.Max.Y > 0 then
		return { width = inset.Min.X, height = inset.Max.Y, measured = true }
	end
	local fallback = Tokens.size.systemBar
	return { width = fallback.x + fallback.width, height = fallback.y + fallback.height, measured = false }
end

local function useSystemBarInset(): SystemBarInset
	local value, setValue = React.useState(read)

	React.useEffect(function()
		local connection = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
			setValue(read())
		end)
		setValue(read())
		return function()
			connection:Disconnect()
		end
	end, {})

	return value
end

return useSystemBarInset

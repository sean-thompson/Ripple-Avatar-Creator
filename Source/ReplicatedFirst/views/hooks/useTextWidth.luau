--!strict

--[[
	useTextWidth

	Width of a string at a given font + size, in UNSCALED units (the same
	units as TextSize), measured with TextService and cached.

	Why not AutomaticSize? Under an ancestor UIScale (SkinRoot's canvas modes)
	Roblox sizes auto-sized text from its on-screen bounds, so anything that
	auto-sizes after the scale is applied comes out scale× too wide (labels in a
	freshly opened panel were ~1.4x, pushing centred content left). Sizing text
	explicitly from this hook is correct in every sizing mode.

	Returns an estimate on the first render of an unseen string, then the
	measured width (re-render) once TextService answers.

	Usage:
		local width = useTextWidth(text, Tokens.font(900), textSize)
		Size = UDim2.fromOffset(width, textSize)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local cache: { [string]: number } = {}

local function keyFor(text: string, font: Font, size: number): string
	return table.concat({ font.Family, font.Weight.Name, font.Style.Name, tostring(size), text }, "|")
end

local function estimate(text: string, size: number): number
	return math.ceil(utf8.len(text) or #text) * size * 0.55
end

local function useTextWidth(text: string, font: Font, size: number): number
	local key = keyFor(text, font, size)
	local width, setWidth = React.useState(cache[key] or estimate(text, size))

	React.useEffect(function()
		local cached = cache[key]
		if cached then
			setWidth(cached)
			return
		end
		local alive = true
		task.spawn(function()
			local params = Instance.new("GetTextBoundsParams")
			params.Text = text
			params.Font = font
			params.Size = size
			params.Width = 100000
			local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
			if ok then
				-- +1: TextBounds can round a hair under what the glyphs need.
				cache[key] = math.ceil(bounds.X) + 1
				if alive then
					setWidth(cache[key])
				end
			end
		end)
		return function()
			alive = false
		end
	end, { key })

	return cache[key] or width
end

return useTextWidth

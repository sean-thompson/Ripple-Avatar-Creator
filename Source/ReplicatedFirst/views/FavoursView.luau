--!strict

--[[
	FavoursView

	Body content for the Favours modal window.
	Aggregates favour data by type and renders a grid of FavourTile cards.

	Props:
		favoursData: { [string]: Network.FavoursState }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local Network = require(ReplicatedStorage:WaitForChild("Network"))
local FavourTile = require(script.Parent:WaitForChild("components"):WaitForChild("FavourTile"))

local e = React.createElement

local COLOR_TEXT_MUTE = Color3.fromRGB(243, 241, 236)

export type Props = {
	favoursData: { [string]: Network.FavoursState },
}

-- Aggregate counts by favour type from the favours dictionary
local function getCountsByType(favours: { [string]: Network.FavoursState }): { [string]: number }
	local counts: { [string]: number } = {}
	for _, favour in pairs(favours) do
		local favourType = favour.favourType
		if favourType and favourType ~= "" then
			counts[favourType] = (counts[favourType] or 0) + 1
		end
	end
	return counts
end

-- Stable sort order for favour types
local TYPE_ORDER: { [string]: number } = {
	Blessing = 1,
	Fortune = 2,
	Miracle = 3,
}

local function FavoursView(props: Props)
	local counts = getCountsByType(props.favoursData)

	-- Check if there are any favours
	local hasFavours = false
	for _ in counts do
		hasFavours = true
		break
	end

	if not hasFavours then
		-- Empty state
		return e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			Icon = e("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = "\u{2B50}",
				TextSize = 32,
				LayoutOrder = 1,
			}),
			Message = e("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = "No favours yet",
				TextColor3 = COLOR_TEXT_MUTE,
				TextTransparency = 0.38,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				LayoutOrder = 2,
			}),
			Hint = e("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = "Donate at the shrine to earn blessings",
				TextColor3 = COLOR_TEXT_MUTE,
				TextTransparency = 0.62,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				LayoutOrder = 3,
			}),
		})
	end

	-- Build tile elements
	local tiles: { [string]: any } = {}
	for favourType, count in counts do
		tiles[favourType] = e(FavourTile, {
			favourType = favourType,
			count = count,
			layoutOrder = TYPE_ORDER[favourType] or 99,
		})
	end

	-- Add grid layout
	tiles["_Layout"] = e("UIGridLayout", {
		CellSize = UDim2.new(0, 118, 0, 128),
		CellPadding = UDim2.new(0, 10, 0, 10),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, tiles)
end

return FavoursView

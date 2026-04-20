--!strict

--[[
	FavourTile

	A single favour card in the Favours grid.
	Shows a cream-colored card with rarity bar, count badge, art placeholder, and name.

	Props:
		favourType: string  (e.g., "Blessing", "Fortune", "Miracle")
		count: number
		layoutOrder: number?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local e = React.createElement

export type Props = {
	favourType: string,
	count: number,
	layoutOrder: number?,
}

-- Rarity colour mapping
local RARITY_COLORS: { [string]: Color3 } = {
	Blessing = Color3.fromRGB(184, 190, 200), -- common
	Fortune = Color3.fromRGB(111, 214, 199),   -- uncommon
	Miracle = Color3.fromRGB(233, 180, 76),    -- legendary
}

local COLOR_TILE_TOP = Color3.fromRGB(245, 241, 232)
local COLOR_TILE_BOTTOM = Color3.fromRGB(232, 225, 208)
local COLOR_TILE_TEXT = Color3.fromRGB(44, 38, 32)
local COLOR_BADGE_BG = Color3.fromRGB(11, 13, 16)
local COLOR_BADGE_TEXT = Color3.fromRGB(246, 213, 138)
local COLOR_ART_BG = Color3.fromRGB(220, 214, 200)

local function FavourTile(props: Props)
	local rarityColor = RARITY_COLORS[props.favourType] or RARITY_COLORS.Blessing
	local initials = string.upper(string.sub(props.favourType, 1, 2))

	return e("Frame", {
		Size = UDim2.new(0, 118, 0, 128), -- ~1:1.08 aspect
		BackgroundColor3 = COLOR_TILE_TOP,
		LayoutOrder = props.layoutOrder or 0,
		ClipsDescendants = true,
	}, {
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		Gradient = e("UIGradient", {
			Color = ColorSequence.new(COLOR_TILE_TOP, COLOR_TILE_BOTTOM),
			Rotation = 90,
		}),
		Stroke = e("UIStroke", {
			Color = Color3.new(0, 0, 0),
			Transparency = 0.92,
			Thickness = 1,
		}),

		-- Rarity bar at top
		RarityBar = e("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = rarityColor,
			BorderSizePixel = 0,
		}),

		-- Count badge (top-right)
		CountBadge = e("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 9),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 22, 0, 22),
			BackgroundColor3 = COLOR_BADGE_BG,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(233, 180, 76),
				Transparency = 0.6,
				Thickness = 1,
			}),
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
			Label = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(props.count),
				TextColor3 = COLOR_BADGE_TEXT,
				TextSize = 12,
				Font = Enum.Font.GothamBold,
			}),
		}),

		-- Art placeholder (initials)
		Art = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 34),
			Size = UDim2.new(0, 56, 0, 56),
			BackgroundColor3 = COLOR_ART_BG,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Initials = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = initials,
				TextColor3 = COLOR_TILE_TEXT,
				TextTransparency = 0.3,
				TextSize = 22,
				Font = Enum.Font.GothamBold,
			}),
		}),

		-- Name label at bottom
		NameLabel = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 28),
			BackgroundTransparency = 1,
			Text = props.favourType,
			TextColor3 = COLOR_TILE_TEXT,
			TextSize = 11,
			Font = Enum.Font.GothamMedium,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

return FavourTile

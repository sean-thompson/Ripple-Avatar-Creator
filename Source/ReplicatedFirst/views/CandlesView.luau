--!strict

--[[
	CandlesView

	Empty-state body content for the Candles modal window.
	Displays a centered message indicating no candles are available.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local useViewportScale = require(script.Parent:WaitForChild("hooks"):WaitForChild("useViewportScale"))

local e = React.createElement

local COLOR_TEXT_MUTE = Color3.fromRGB(243, 241, 236)

local function CandlesView()
	local scale = useViewportScale()
	local function px(n: number): number
		return math.floor(n * scale + 0.5)
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, px(8)),
		}),

		Icon = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = "\u{1F56F}",
			TextSize = math.max(16, px(32)),
			LayoutOrder = 1,
		}),

		Message = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = "No candles to display",
			TextColor3 = COLOR_TEXT_MUTE,
			TextTransparency = 0.38,
			TextSize = math.max(9, px(14)),
			Font = Enum.Font.GothamMedium,
			LayoutOrder = 2,
		}),

		Hint = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = "Light a candle at the shrine",
			TextColor3 = COLOR_TEXT_MUTE,
			TextTransparency = 0.62,
			TextSize = math.max(8, px(12)),
			Font = Enum.Font.GothamMedium,
			LayoutOrder = 3,
		}),
	})
end

return CandlesView

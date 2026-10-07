--!strict

--[[
	useSkin

	The skin components' one dependency on the sizing decision. Returns:

	  px(n)        design px -> local units (rounded). Relative mode scales;
	               canvas modes return n because a UIScale does the scaling.
	  stroke(n)    like px, never below 1 (hairlines must stay visible).
	  textPx(n)    like px, floored at Tokens.type.minPx in relative mode.
	  fromScreen(n) real screen pixels (e.g. Roblox's top bar) -> local units.
	  scale, sizing, glass  straight from SkinContext.

	Usage:
		local skin = useSkin()
		Size = UDim2.fromOffset(skin.px(64), skin.px(64))
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local SkinContext = require(views:WaitForChild("SkinContext"))
local Tokens = require(views:WaitForChild("Tokens"))

export type Skin = {
	sizing: SkinContext.Sizing,
	glass: SkinContext.Glass,
	scale: number,
	px: (number) -> number,
	stroke: (number) -> number,
	textPx: (number) -> number,
	fromScreen: (number) -> number,
}

local function useSkin(): Skin
	local settings: SkinContext.SkinSettings = React.useContext(SkinContext)
	local scale = settings.scale
	local isRelative = settings.sizing == "relative"

	local function px(n: number): number
		if isRelative then
			return math.floor(n * scale + 0.5)
		end
		return n
	end

	return {
		sizing = settings.sizing,
		glass = settings.glass,
		scale = scale,
		px = px,
		stroke = function(n: number): number
			return math.max(1, px(n))
		end,
		textPx = function(n: number): number
			if isRelative then
				return math.max(Tokens.type.minPx, px(n))
			end
			return n
		end,
		fromScreen = function(n: number): number
			if isRelative or scale <= 0 then
				return n
			end
			return n / scale
		end,
	}
end

return useSkin

--!strict

--[[
	useAppear

	A 0→1 spring that runs once when the component mounts. Map it onto
	whatever should animate in (position offset, transparency) — key a
	component to remount it and it plays again (e.g. a screen after a tab or
	breadcrumb change).

	Usage:
		local t = useAppear(Tokens.spring.screen)
		Position = t:map(function(v) return UDim2.fromOffset((1 - v) * 18, 0) end)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local useSpring = require(script.Parent:WaitForChild("useSpring"))

local function useAppear(config: { force: number, dampening: number, mass: number? }?): any
	local shown, setShown = React.useState(false)
	React.useEffect(function()
		setShown(true)
	end, {})
	local spring = useSpring({ t = if shown then 1 else 0 }, config)
	return spring.t
end

return useAppear

--!strict

--[[
	SkinContext

	Carries the skin's sizing mode, glass mode and current scale from SkinRoot
	down to every skin component (read via hooks/useSkin).

	sizing:
	  "relative" — components multiply design px by `scale` themselves
	               (per-element pixels; the template's VIEW_GUIDE approach).
	  "fit"      — design px under one UIScale on a 1180x820 canvas, letterboxed
	               (html-to-react-luau Pattern 2).
	  "fill"     — design px under one UIScale, canvas stretched to the screen's
	               aspect so corner pins reach the real edges.
	glass:
	  "translucent" — denser fills, no post-processing.
	  "blur"        — design alphas, plus a scene blur behind full-screen panels.

	The default (no provider) is relative at scale 1, so components still render
	outside a SkinRoot.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

export type Sizing = "relative" | "fit" | "fill"
export type Glass = "translucent" | "blur"

export type SkinSettings = {
	sizing: Sizing,
	glass: Glass,
	scale: number,
}

local SkinContext = React.createContext({
	sizing = "relative",
	glass = "translucent",
	scale = 1,
} :: SkinSettings)

return SkinContext

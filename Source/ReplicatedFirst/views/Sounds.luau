--!strict

--[[
	Sounds

	Plays the HUD's UI sounds locally (SoundService:PlayLocalSound — only this
	player hears them). Sound IDs live in SkinAssets.sounds; a slot with ID 0
	is silent, so triggers can be wired before the assets exist.

	Usage:
		Sounds.play("confirm")
		Sounds.setMuted(true)

	Throttled per slot so rapid repeats (e.g. scrubbing through tabs) don't
	stack into a buzz.

	Call Sounds.preload() once at startup: it creates every slot's Sound and
	downloads them in the background (ContentProvider:PreloadAsync), so the
	first play of each isn't delayed by fetching the asset.
]]

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local views = script.Parent
local SkinAssets = require(views:WaitForChild("SkinAssets"))
local Tokens = require(views:WaitForChild("Tokens"))

local Sounds = {}

export type Name =
	"press"
	| "tab"
	| "open"
	| "close"
	| "back"
	| "confirm"
	| "tryOn"
	| "purchase"
	| "error"
	| "switch"
	| "worldIn"
	| "worldOut"

local MIN_INTERVAL = 0.05 -- seconds between plays of the same slot

local cache: { [string]: Sound } = {}
local lastPlayed: { [string]: number } = {}
local muted = false

local function soundFor(name: string): Sound?
	local id = SkinAssets.sounds[name]
	if id == nil or id == 0 then
		return nil
	end
	local sound = cache[name]
	if sound == nil then
		local created = Instance.new("Sound")
		created.Name = "UI_" .. name
		created.SoundId = "rbxassetid://" .. id
		created.Volume = (Tokens.sound.volume :: any)[name] or Tokens.sound.volume.default
		created.Parent = SoundService
		cache[name] = created
		sound = created
	end
	return sound
end

function Sounds.play(name: Name)
	if muted then
		return
	end
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < MIN_INTERVAL then
		return
	end
	lastPlayed[name] = now
	local sound = soundFor(name)
	if sound then
		SoundService:PlayLocalSound(sound)
	end
end

-- Create every slot's Sound and download them in the background.
function Sounds.preload()
	local instances = {}
	for name in SkinAssets.sounds do
		local sound = soundFor(name)
		if sound then
			table.insert(instances, sound)
		end
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(instances)
	end)
end

function Sounds.setMuted(value: boolean)
	muted = value
end

function Sounds.isMuted(): boolean
	return muted
end

return Sounds

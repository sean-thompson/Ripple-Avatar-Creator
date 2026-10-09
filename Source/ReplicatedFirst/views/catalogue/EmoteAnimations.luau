--!strict

--[[
	EmoteAnimations (client)

	The animation inside an emote, so the panel's avatar preview can play
	it. An emote's catalogue id isn't itself an animation, and the client
	can't open the asset, so the server looks it up (AvatarService's
	"AvatarEmoteAnimations" remote function). Results are cached.

	  get(emoteId)   "rbxassetid://…" or nil (yields the first time)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bolt = require(ReplicatedStorage:WaitForChild("Bolt"))

local EmoteAnimations = {}

local lookup = Bolt.RemoteFunction("AvatarEmoteAnimations")
local cache: { [number]: string } = {}
local inFlight: { [number]: boolean } = {}

function EmoteAnimations.get(emoteId: number): string?
	-- Someone's already asking for this one: wait for their answer rather
	-- than sending a second request.
	local waited = 0
	while inFlight[emoteId] and waited < 10 do
		waited += task.wait()
	end
	local cached = cache[emoteId]
	if cached then
		return cached
	end
	inFlight[emoteId] = true
	local ok, result = pcall(function()
		return lookup:InvokeServer({ emoteId })
	end)
	inFlight[emoteId] = nil
	local animation: string? = nil
	if ok and type(result) == "table" then
		for _, entry in result do
			if entry.id == emoteId then
				animation = entry.animation
			end
		end
	end
	-- Only remember answers: an empty reply may just be the server's
	-- request cooldown, so it's worth asking again later.
	if animation then
		cache[emoteId] = animation
	end
	return animation
end

return EmoteAnimations

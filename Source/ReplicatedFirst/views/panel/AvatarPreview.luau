--!strict

--[[
	AvatarPreview (panel left column: the live preview of your look)

	A client-only copy of the player's own character in a ModelViewer: exactly
	what everyone else sees (it's cloned from the real, server-dressed
	character), posed at rest and turned to face the camera. It rebuilds
	whenever the character's appearance changes (try on, take off, respawn),
	keeping the angle you'd turned it to. Drag to turn, wheel to zoom, hold
	the middle mouse button and drag to move it.

	The real character is never touched: the copy lives only in the viewport.
	A worn avatar background shows behind it. It plays `animation` (looped)
	— one of the character's own animations, read from its Animate script so
	a worn animation pack shows, or an emote (looked up via EmoteAnimations).
	The copy's joints stay live (only its root is anchored) so it can move.

	Props:
		backdrop: string?      avatar background image, if one is worn
		cornerRadius: number?  design px, to match the card it fills
		animation: AnimationBar.Choice?  what to play (default: idle)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local ModelViewer = require(views:WaitForChild("components"):WaitForChild("ModelViewer"))
local ItemModel = require(views:WaitForChild("catalogue"):WaitForChild("ItemModel"))
local EmoteAnimations = require(views:WaitForChild("catalogue"):WaitForChild("EmoteAnimations"))
local AnimationBar = require(script.Parent:WaitForChild("AnimationBar"))

local e = React.createElement

-- Appearance changes arrive as bursts of added/removed parts; wait for the
-- burst to settle before copying.
local SETTLE = 0.35

local function copyCharacter(): Model?
	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end
	local wasArchivable = character.Archivable
	character.Archivable = true -- characters can't be cloned otherwise
	local copy = character:Clone()
	character.Archivable = wasArchivable
	if not copy then
		return nil
	end
	for _, descendant in copy:GetDescendants() do
		if descendant:IsA("BaseScript") or descendant:IsA("ModuleScript") or descendant:IsA("Sound") then
			descendant:Destroy()
		elseif descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			descendant.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
	end
	ItemModel.restPose(copy)
	for _, descendant in copy:GetDescendants() do
		if descendant:IsA("BasePart") then
			-- Only the root is pinned; the rest hangs off its joints so the
			-- Animator can move it (nothing simulates in a viewport, so it
			-- doesn't fall).
			descendant.Anchored = descendant.Name == "HumanoidRootPart"
			descendant.CanCollide = false
		end
	end
	-- Face -Z at the origin, so the viewer's yaw 180 is the front.
	copy:PivotTo(CFrame.new())
	return copy
end

-- A number that changes whenever the character's look does.
local function useCharacterVersion(): number
	local version, setVersion = React.useState(0)
	React.useEffect(function()
		local player = Players.LocalPlayer
		local pending: thread? = nil
		local characterConnections: { RBXScriptConnection } = {}

		local function bump()
			if pending then
				task.cancel(pending)
			end
			pending = task.delay(SETTLE, function()
				pending = nil
				setVersion(function(v: number)
					return v + 1
				end)
			end)
		end

		local function watch(character: Model?)
			for _, connection in characterConnections do
				connection:Disconnect()
			end
			table.clear(characterConnections)
			if character then
				table.insert(characterConnections, character.DescendantAdded:Connect(bump))
				table.insert(characterConnections, character.DescendantRemoving:Connect(bump))
			end
			bump()
		end

		watch(player.Character)
		local added = player.CharacterAdded:Connect(watch)
		return function()
			added:Disconnect()
			for _, connection in characterConnections do
				connection:Disconnect()
			end
			if pending then
				task.cancel(pending)
			end
		end
	end, {})
	return version
end

-- The animation id for a choice: from the live character's Animate script
-- (so a worn animation pack shows), or the server's emote lookup (yields).
local function animationIdFor(choice: AnimationBar.Choice): string?
	if choice.emoteId then
		return EmoteAnimations.get(choice.emoteId)
	end
	local character = Players.LocalPlayer.Character
	local animate = character and character:FindFirstChild("Animate")
	local folder = animate and choice.folder and animate:FindFirstChild(choice.folder)
	local animation = folder and choice.name and folder:FindFirstChild(choice.name)
	return if animation and animation:IsA("Animation") then animation.AnimationId else nil
end

local function AvatarPreview(props: { backdrop: string?, cornerRadius: number?, animation: AnimationBar.Choice? })
	local version = useCharacterVersion()
	local model, setModel = React.useState(nil :: Model?)
	local choice = props.animation or AnimationBar.DEFAULT

	-- Play the chosen animation on the current copy (again after a rebuild).
	React.useEffect(function()
		if not model then
			return nil
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			return nil
		end
		local alive = true
		local track: AnimationTrack? = nil
		task.spawn(function()
			local id = animationIdFor(choice)
			if not alive or not id then
				return
			end
			local animation = Instance.new("Animation")
			animation.AnimationId = id
			local ok, loaded = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			if ok and alive then
				track = loaded
				loaded.Looped = true
				loaded:Play()
			end
		end)
		return function()
			alive = false
			if track then
				track:Stop(0)
				track:Destroy()
			end
		end
	end, { model, choice.key } :: { any })

	return e(ModelViewer, {
		onModel = setModel,
		buildKey = version,
		build = copyCharacter,
		keepView = true,
		autoSpin = false,
		yaw = 180 - 20,
		pitch = -8,
		fill = 0.9,
		backdrop = props.backdrop,
		backgroundColor = Color3.fromHex("#141414"),
		cornerRadius = props.cornerRadius or 18,
		loadingText = "",
	})
end

return AvatarPreview

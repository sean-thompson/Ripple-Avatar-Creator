--!strict

--[[
	FlightView (client, Pattern A — no server component)

	Double-jump to fly: press jump twice within
	WorldOptionsConfig.flight.doubleJumpWindow to take off; again to drop.
	The second press doesn't have to wait until the character is airborne — a
	fast double-tap arrives before Roblox has switched it to Jumping.
	While flying you move where the camera faces (pitch included), hold jump
	to climb, and hover when idle. Touching the ground ends the flight.

	Emotes work mid-air: while flying the Humanoid is kept out of Freefall
	(Roblox's Animate script only lets emotes play from a standing / running
	pose, and refuses them while falling), so the emote menu works when you
	hover. The flip side is the run/walk animation while moving in the air.

	It's the player's own character, so physics stays client-owned and Roblox
	replicates the movement like any other — nothing is mirrored into a model.
	Player collisions are unchanged. Turn it off with flight.enabled.

	Mechanics: a LinearVelocity on the HumanoidRootPart drives the character;
	Humanoid.Jump (set by Roblox's controls while jump is held, on every
	device) reads as "climb". A new press is a JumpRequest after a short gap,
	because holding jump repeats the request every frame (PRESS_GAP sits just
	above two frames, so quick taps still count separately).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local WorldOptionsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("WorldOptionsConfig"))

local flight = WorldOptionsConfig.flight
if not flight.enabled then
	return
end

local PRESS_GAP = 0.06 -- seconds of silence that separate two jump presses
-- Just after take-off: lift off the ground and ignore the landing check, in
-- case both taps came before the character left the floor.
local TAKEOFF_GRACE = 0.35

local player = Players.LocalPlayer

local function setUpCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	local attachment = Instance.new("Attachment")
	attachment.Name = "FlightAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "FlightVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = math.huge
	velocity.Enabled = false
	velocity.Parent = root

	local flying = false
	local takeoffAt = 0
	local lastRequest = 0
	local lastPress = -math.huge

	local function setFlying(on: boolean)
		flying = on
		velocity.Enabled = on
		-- No Freefall while flying, so emotes can play (see header).
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, not on)
		if on then
			takeoffAt = os.clock()
			velocity.VectorVelocity = Vector3.zero
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		elseif humanoid.FloorMaterial == Enum.Material.Air and humanoid.Health > 0 then
			-- Dropped mid-air: fall (with the fall pose) rather than "run".
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end

	local jumpConnection = UserInputService.JumpRequest:Connect(function()
		local now = os.clock()
		local isNewPress = now - lastRequest > PRESS_GAP
		lastRequest = now
		if not isNewPress then
			return
		end
		if now - lastPress <= flight.doubleJumpWindow then
			setFlying(not flying)
			lastPress = -math.huge -- a third press starts a new double-jump
		else
			lastPress = now
		end
	end)

	local stepConnection = RunService.RenderStepped:Connect(function()
		if not flying then
			return
		end
		if humanoid.Health <= 0 then
			setFlying(false)
			return
		end

		local move = humanoid.MoveDirection -- camera-relative, flat, on every device
		local climbing = humanoid.Jump
		local look = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or Vector3.zAxis
		local flatLook = Vector3.new(look.X, 0, look.Z)
		local forward = if flatLook.Magnitude > 0 then math.max(0, move:Dot(flatLook.Unit)) else 0

		local vertical = if climbing then flight.climbSpeed else look.Y * forward * flight.speed
		local launching = os.clock() - takeoffAt < TAKEOFF_GRACE
		if launching then
			vertical = math.max(vertical, flight.climbSpeed * 0.6)
		end
		velocity.VectorVelocity = move * flight.speed + Vector3.new(0, vertical, 0)

		-- Back on the ground (and not climbing away from it): stop flying.
		if not launching and not climbing and vertical <= 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
			setFlying(false)
		end
	end)

	humanoid.Died:Connect(function()
		setFlying(false)
	end)

	character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			jumpConnection:Disconnect()
			stepConnection:Disconnect()
		end
	end)
end

if player.Character then
	task.spawn(setUpCharacter, player.Character)
end
player.CharacterAdded:Connect(setUpCharacter)

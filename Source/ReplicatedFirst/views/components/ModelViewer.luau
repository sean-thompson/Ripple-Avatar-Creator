--!strict

--[[
	ModelViewer

	A turnable 3D view of a model in a ViewportFrame, framed to fit its
	bounding sphere. Turns slowly on its own until touched (optional); drag
	(mouse or touch) to turn it any way, mouse wheel to zoom, hold the middle
	mouse button and drag to move it up / down / sideways. Used by the item
	page's 3D view and the panel's avatar preview.

	The model comes from `build` (may yield; returns a Model the viewer may
	keep, or nil), re-run whenever `buildKey` changes. With `keepView`, a
	rebuild keeps the current angle and zoom (the avatar preview updating as
	you try things on); otherwise the view resets each build.

	Over a transparent background, dark models get a pale fringe where their
	edges blend, so the viewer paints `backgroundColor` unless a `backdrop`
	image is shown behind it.

	Props:
		build: () -> Model?
		buildKey: any
		keepView: boolean?
		autoSpin: boolean?        default true
		yaw: number?              starting angle, degrees (0 looks at the model's back; 180 its front)
		pitch: number?            starting tilt, degrees (negative looks down)
		fill: number?             how much of the view the model fills (default 1.05 = a little margin)
		backgroundColor: Color3?
		backdrop: string?         image behind the model (e.g. an avatar background)
		cornerRadius: number?     design px
		loadingText: string?      shown while building
		failedText: string?       shown when build returns nil
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))

local e = React.createElement

local FOV = 40
local AUTO_SPIN = 25 -- degrees per second until the first drag
local DRAG_SPEED = 0.4 -- degrees per screen pixel
local PITCH_LIMIT = 80
local ZOOM_MIN, ZOOM_MAX = 0.55, 1.8
-- Middle-drag pan: how far from centre the view may go (share of the
-- model's size). The pan itself tracks the cursor exactly (see below).
local PAN_LIMIT = 0.6
local CARD = Color3.fromHex("#1c1c1c")

export type Props = {
	build: () -> Model?,
	buildKey: any,
	keepView: boolean?,
	autoSpin: boolean?,
	yaw: number?,
	pitch: number?,
	fill: number?,
	backgroundColor: Color3?,
	backdrop: string?,
	cornerRadius: number?,
	loadingText: string?,
	failedText: string?,
}

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function ModelViewer(props: Props)
	local skin = useSkin()
	local viewportRef = React.useRef(nil :: ViewportFrame?)
	local status, setStatus = React.useState("loading" :: "loading" | "ready" | "failed")
	local latest = React.useRef(props)
	latest.current = props
	-- Shared between the input/camera effect and the build effect.
	local view = React.useRef({
		camera = nil :: Camera?,
		model = nil :: Model?,
		yaw = props.yaw or 30,
		pitch = props.pitch or -12,
		zoom = 1,
		centre = Vector3.zero,
		distance = 10,
		size = 1, -- the model's bounding size (for the pan limit)
		pan = Vector3.zero, -- middle-drag offset, in world space
		touched = false,
		place = function() end,
	})

	-- Camera and input: once.
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return nil
		end
		local v = view.current
		local camera = Instance.new("Camera")
		camera.FieldOfView = FOV
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		v.camera = camera
		v.place = function()
			local orbit = CFrame.Angles(0, math.rad(v.yaw), 0) * CFrame.Angles(math.rad(v.pitch), 0, 0)
			camera.CFrame = CFrame.new(v.centre + v.pan) * orbit * CFrame.new(0, 0, v.distance * v.zoom)
		end
		v.place()

		local dragging: InputObject? = nil
		local lastPosition: Vector3? = nil
		local panning = false
		local lastPan: Vector3? = nil
		local connections = {
			RunService.RenderStepped:Connect(function(dt: number)
				if latest.current.autoSpin ~= false and not v.touched and not dragging and v.model then
					v.yaw += AUTO_SPIN * dt
					v.place()
				end
			end),
			viewport.InputBegan:Connect(function(input: InputObject)
				if isPress(input) then
					dragging = input
					lastPosition = input.Position
					v.touched = true
				elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
					panning = true
					lastPan = input.Position
					v.touched = true
				end
			end),
			viewport.InputChanged:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					v.zoom = math.clamp(v.zoom * (1 - input.Position.Z * 0.1), ZOOM_MIN, ZOOM_MAX)
					v.place()
				end
			end),
			UserInputService.InputChanged:Connect(function(input: InputObject)
				if panning and lastPan and input.UserInputType == Enum.UserInputType.MouseMovement then
					-- Move the view in the camera's own plane: right and up.
					local delta = input.Position - lastPan
					lastPan = input.Position
					-- World units per screen pixel at the model's depth, so the
					-- model stays under the cursor.
					local height = math.max(viewport.AbsoluteSize.Y, 1)
					local scale = 2 * v.distance * v.zoom * math.tan(math.rad(FOV / 2)) / height
					local look = camera.CFrame
					local pan = v.pan - look.RightVector * delta.X * scale + look.UpVector * delta.Y * scale
					local limit = v.size * PAN_LIMIT
					if pan.Magnitude > limit then
						pan = pan.Unit * limit
					end
					v.pan = pan
					v.place()
					return
				end
				if not dragging or not lastPosition then
					return
				end
				local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
					or (input.UserInputType == Enum.UserInputType.Touch and input == dragging)
				if isMove then
					local delta = input.Position - lastPosition
					lastPosition = input.Position
					v.yaw -= delta.X * DRAG_SPEED
					v.pitch = math.clamp(v.pitch - delta.Y * DRAG_SPEED, -PITCH_LIMIT, PITCH_LIMIT)
					v.place()
				end
			end),
			UserInputService.InputEnded:Connect(function(input: InputObject)
				if dragging and isPress(input) then
					dragging = nil
					lastPosition = nil
				elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
					panning = false
					lastPan = nil
				end
			end),
		}
		return function()
			for _, connection in connections do
				connection:Disconnect()
			end
			camera:Destroy()
			if v.model then
				v.model:Destroy()
				v.model = nil
			end
		end
	end, {})

	-- The model: on every buildKey change.
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return nil
		end
		local alive = true
		local v = view.current
		if not v.model then
			setStatus("loading")
		end
		task.spawn(function()
			local model = latest.current.build()
			if not alive then
				if model then
					model:Destroy()
				end
				return
			end
			if v.model then
				v.model:Destroy()
				v.model = nil
			end
			if not model then
				setStatus("failed")
				return
			end
			model.Parent = viewport
			v.model = model
			local boxCFrame, size = model:GetBoundingBox()
			v.centre = boxCFrame.Position
			v.size = size.Magnitude
			-- Far enough back that the whole bounding sphere fits the view.
			v.distance = (size.Magnitude / 2) / math.sin(math.rad(FOV / 2)) * (latest.current.fill or 1.05)
			if not latest.current.keepView then
				v.yaw = latest.current.yaw or 30
				v.pitch = latest.current.pitch or -12
				v.zoom = 1
				v.pan = Vector3.zero
				v.touched = false
			end
			v.place()
			setStatus("ready")
		end)
		return function()
			alive = false
		end
	end, { props.buildKey })

	local hasBackdrop = props.backdrop ~= nil and props.backdrop ~= ""
	local radius = UDim.new(0, skin.px(props.cornerRadius or 18))
	return e("Frame", {
		Name = "ModelViewer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Backdrop = if hasBackdrop
			then e("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = props.backdrop,
				ScaleType = Enum.ScaleType.Crop,
			}, { Corner = e("UICorner", { CornerRadius = radius }) })
			else nil,
		Viewport = e("ViewportFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = props.backgroundColor or CARD,
			BackgroundTransparency = if hasBackdrop then 1 else 0,
			Ambient = Color3.fromRGB(150, 150, 150),
			LightColor = Color3.fromRGB(255, 255, 255),
			LightDirection = Vector3.new(-1, -1.5, -1),
			ZIndex = 2,
			-- Swallow presses, so dragging the model doesn't also press a
			-- button underneath (the preview card opens Wearing).
			Active = true,
			ref = viewportRef,
		}, {
			Corner = e("UICorner", { CornerRadius = radius }),
			Status = if status ~= "ready"
				then e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = if status == "loading" then props.loadingText or "Loading 3D…" else props.failedText or "No 3D view",
					TextColor3 = Tokens.color.white,
					TextTransparency = Tokens.alpha.textDim,
					TextSize = skin.textPx(13),
					FontFace = Tokens.font(800),
				})
				else nil,
		}),
	})
end

return ModelViewer

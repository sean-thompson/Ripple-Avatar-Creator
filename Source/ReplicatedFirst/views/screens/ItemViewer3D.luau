--!strict

--[[
	ItemViewer3D (item page: the 3D alternative to the thumbnail)

	Shows the item's model (catalogue/ItemModel) in a ViewportFrame, framed
	to fit. It turns slowly on its own until you drag it; drag (mouse or
	touch) to turn it any way, mouse wheel to zoom. A spinner shows while the
	model is being built; if it can't be built it says so.

	Props:
		item: Item
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local Tokens = require(views:WaitForChild("Tokens"))
local useSkin = require(views:WaitForChild("hooks"):WaitForChild("useSkin"))
local ItemModel = require(views:WaitForChild("catalogue"):WaitForChild("ItemModel"))

local e = React.createElement

local FOV = 40
local AUTO_SPIN = 25 -- degrees per second until the first drag
local DRAG_SPEED = 0.4 -- degrees per screen pixel
local PITCH_LIMIT = 80
local ZOOM_MIN, ZOOM_MAX = 0.55, 1.8

local function isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function ItemViewer3D(props: { item: any })
	local skin = useSkin()
	local viewportRef = React.useRef(nil :: ViewportFrame?)
	local status, setStatus = React.useState("loading" :: "loading" | "ready" | "failed")

	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return nil
		end
		local alive = true
		local connections: { RBXScriptConnection } = {}
		local camera = Instance.new("Camera")
		camera.FieldOfView = FOV
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		local yaw, pitch, zoom = 30, -12, 1
		local dragging: InputObject? = nil
		local lastPosition: Vector3? = nil
		local touched = false
		local centre, distance = Vector3.zero, 10

		local function place()
			local orbit = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
			camera.CFrame = CFrame.new(centre) * orbit * CFrame.new(0, 0, distance * zoom)
		end

		task.spawn(function()
			local template = ItemModel.build(props.item)
			if not alive then
				return
			end
			if not template then
				setStatus("failed")
				return
			end
			local model = template:Clone()
			model.Parent = viewport
			local boxCFrame, size = model:GetBoundingBox()
			centre = boxCFrame.Position
			-- Far enough back that the whole bounding sphere fits the view.
			local radius = size.Magnitude / 2
			distance = radius / math.sin(math.rad(FOV / 2)) * 1.05
			place()
			setStatus("ready")
		end)

		table.insert(
			connections,
			RunService.RenderStepped:Connect(function(dt: number)
				if not touched and not dragging then
					yaw += AUTO_SPIN * dt
					place()
				end
			end)
		)
		table.insert(
			connections,
			viewport.InputBegan:Connect(function(input: InputObject)
				if isPress(input) then
					dragging = input
					lastPosition = input.Position
					touched = true
				end
			end)
		)
		table.insert(
			connections,
			viewport.InputChanged:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					zoom = math.clamp(zoom * (1 - input.Position.Z * 0.1), ZOOM_MIN, ZOOM_MAX)
					place()
				end
			end)
		)
		table.insert(
			connections,
			UserInputService.InputChanged:Connect(function(input: InputObject)
				if not dragging or not lastPosition then
					return
				end
				local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
					or (input.UserInputType == Enum.UserInputType.Touch and input == dragging)
				if isMove then
					local delta = input.Position - lastPosition
					lastPosition = input.Position
					yaw -= delta.X * DRAG_SPEED
					pitch = math.clamp(pitch - delta.Y * DRAG_SPEED, -PITCH_LIMIT, PITCH_LIMIT)
					place()
				end
			end)
		)
		table.insert(
			connections,
			UserInputService.InputEnded:Connect(function(input: InputObject)
				if dragging and isPress(input) then
					dragging = nil
					lastPosition = nil
				end
			end)
		)

		return function()
			alive = false
			for _, connection in connections do
				connection:Disconnect()
			end
			for _, child in viewport:GetChildren() do
				if child:IsA("Model") or child:IsA("Camera") then
					child:Destroy()
				end
			end
		end
	end, { props.item.id })

	-- An opaque background in the card's colour: over a transparent one, dark
	-- items get a pale fringe where their edges blend.
	return e("ViewportFrame", {
		Name = "ItemViewer3D",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromHex("#1c1c1c"),
		BackgroundTransparency = 0,
		Ambient = Color3.fromRGB(150, 150, 150),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, -1.5, -1),
		ref = viewportRef,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, skin.px(18)) }),
		Status = if status ~= "ready"
			then e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = if status == "loading" then "Loading 3D…" else "No 3D view for this item",
				TextColor3 = Tokens.color.white,
				TextTransparency = Tokens.alpha.textDim,
				TextSize = skin.textPx(13),
				FontFace = Tokens.font(800),
			})
			else nil,
	})
end

return ItemViewer3D

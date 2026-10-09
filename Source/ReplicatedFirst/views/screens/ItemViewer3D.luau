--!strict

--[[
	ItemViewer3D (item page: the 3D alternative to the thumbnail)

	The item's model (catalogue/ItemModel) in a ModelViewer: turns slowly on
	its own until you drag it; drag to turn it any way, mouse wheel to zoom.

	Props:
		item: Item
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local views = script.Parent.Parent
local ModelViewer = require(views:WaitForChild("components"):WaitForChild("ModelViewer"))
local ItemModel = require(views:WaitForChild("catalogue"):WaitForChild("ItemModel"))

local e = React.createElement

local function ItemViewer3D(props: { item: any })
	return e(ModelViewer, {
		buildKey = props.item.id,
		build = function()
			-- The template is cached and shared; the viewer gets its own copy.
			local template = ItemModel.build(props.item)
			return if template then template:Clone() else nil
		end,
		failedText = "No 3D view for this item",
	})
end

return ItemViewer3D

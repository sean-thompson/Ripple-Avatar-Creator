--!strict
-- REFERENCE COPY. The live module is Studio-authored at
-- ReplicatedStorage.Config.CatalogueConfig (configs aren't Rojo-synced in
-- this template — see docs/CONFIG_GUIDE.md). Keep the two in step.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigTypes = ReplicatedStorage:WaitForChild("Config"):WaitForChild("ConfigTypes")
local CatalogueConfigTypes = require(ConfigTypes:WaitForChild("CatalogueConfigTypes"))

type CatalogueConfig = CatalogueConfigTypes.CatalogueConfig

-- Categories follow the Roblox marketplace menu
-- (catalog.roblox.com/v1/search/navigation-menu-items), with Classic split
-- out of Clothing. Bodysuits is left out: the API has no type for it.
local config: CatalogueConfig = {
	categories = {
		{
			name = "Body",
			chips = {
				{ name = "Full Bodies", bundleTypes = { "BodyParts" } },
				{ name = "Hair", assetTypes = { "HairAccessory" } },
				{ name = "Heads", bundleTypes = { "DynamicHead" } },
			},
		},
		{
			name = "Clothing",
			chips = {
				{ name = "Shirts", assetTypes = { "ShirtAccessory" } },
				{ name = "T-Shirts", assetTypes = { "TShirtAccessory" } },
				{ name = "Sweaters", assetTypes = { "SweaterAccessory" } },
				{ name = "Jackets", assetTypes = { "JacketAccessory" } },
				{ name = "Pants", assetTypes = { "PantsAccessory" } },
				{ name = "Dresses & Skirts", assetTypes = { "DressSkirtAccessory" } },
				{ name = "Shorts", assetTypes = { "ShortsAccessory" } },
				{ name = "Shoes", bundleTypes = { "Shoes" } },
			},
		},
		{
			name = "Classic",
			chips = {
				{ name = "Shirts", assetTypes = { "Shirt" } },
				{ name = "T-Shirts", assetTypes = { "TShirt" } },
				{ name = "Pants", assetTypes = { "Pants" } },
			},
		},
		{
			name = "Accessories",
			chips = {
				{ name = "Head", assetTypes = { "Hat" } },
				{ name = "Face", assetTypes = { "FaceAccessory" } },
				{ name = "Neck", assetTypes = { "NeckAccessory" } },
				{ name = "Shoulder", assetTypes = { "ShoulderAccessory" } },
				{ name = "Front", assetTypes = { "FrontAccessory" } },
				{ name = "Back", assetTypes = { "BackAccessory" } },
				{ name = "Waist", assetTypes = { "WaistAccessory" } },
				{ name = "Gear", assetTypes = { "Gear" } },
			},
		},
		{
			name = "Backgrounds",
			chips = {
				{ name = "Backgrounds", assetTypes = { "AvatarBackground" } },
			},
		},
		{
			name = "Animations",
			chips = {
				{ name = "Bundles", bundleTypes = { "Animations" } },
				{ name = "Emotes", assetTypes = { "EmoteAnimation" } },
			},
		},
		{
			name = "Makeup",
			chips = {
				{ name = "Eyes", assetTypes = { "EyeMakeup" } },
				{ name = "Lips", assetTypes = { "LipMakeup" } },
				{ name = "Face", assetTypes = { "FaceMakeup" } },
				{ name = "Eyelashes", assetTypes = { "EyelashAccessory" } },
				{ name = "Eyebrows", assetTypes = { "EyebrowAccessory" } },
			},
		},
	},
	pageSize = 60,
	sort = "Relevance",
	sortAggregation = "AllTime",
	includeOffSale = false,
	cacheSeconds = 300,
	searchDebounce = 0.4,
	backoffSeconds = 30,
	thumbnailSize = 150,
}

return config

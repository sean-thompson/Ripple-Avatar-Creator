--!strict

--[[
	CatalogueClient (client, Pattern A — no server component)

	Searches the Roblox catalogue directly from this client
	(AvatarEditorService:SearchCatalog), so each player browses on their own
	rate-limit budget instead of sharing the server's (a few active browsers
	would exhaust one shared budget; see PLAN.md open question 10). Item
	try-on is still validated by the server (Task 5).

	  search(query)      first page for a query (yields); cached per query
	  loadMore(query)    next page appended to that query's results (yields)
	  item(id)           any item this client has seen, by id
	  similar(item, n)   up to n seen items from the same category

	Item ids: assets keep their asset id; bundles are negated (-bundleId), as
	asset and bundle ids can collide. `targetId` + `kind` carry the real id.

	When the catalogue throttles us (HTTP 429) every call waits out
	CatalogueConfig.backoffSeconds and retries once.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

local CatalogueConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CatalogueConfig"))

local CatalogueClient = {}

export type Item = {
	id: number,
	kind: "Asset" | "Bundle",
	targetId: number,
	name: string,
	main: string, -- top-level category (CatalogueConfig.categories[].name)
	sub: string, -- chip name within it
	typeName: string, -- AvatarAssetType / BundleType name
	price: number,
	creator: string,
	description: string,
	favourites: number,
	thumbnail: string,
	colour: string, -- dominant colour name; "" until colour analysis lands (Task 8)
	owned: boolean, -- false until ownership checks land (Task 11)
}

export type Query = {
	category: string,
	chip: string?, -- nil = "All"
	keyword: string?,
}

export type Result = {
	items: { Item },
	exhausted: boolean, -- no more pages
}

type Entry = {
	items: { Item },
	pages: CatalogPages?,
	exhausted: boolean,
	fetchedAt: number,
}

-- typeName -> where it sits in the menu (first chip that lists it).
local placement: { [string]: { main: string, sub: string } } = {}
for _, category in CatalogueConfig.categories do
	for _, chip in category.chips do
		for _, name in chip.assetTypes or {} do
			placement[name] = placement[name] or { main = category.name, sub = chip.name }
		end
		for _, name in chip.bundleTypes or {} do
			placement[name] = placement[name] or { main = category.name, sub = chip.name }
		end
	end
end

local seen: { [number]: Item } = {}
local cache: { [string]: Entry } = {}
local blockedUntil = 0

local function enumItems(enum: Enum, names: { string }, into: { EnumItem })
	for _, name in names do
		local ok, value = pcall(function()
			return (enum :: any)[name]
		end)
		if ok and value then
			table.insert(into, value)
		else
			warn(`[CatalogueClient] Unknown {enum} "{name}" in CatalogueConfig`)
		end
	end
end

local function chipsFor(query: Query): { any }
	for _, category in CatalogueConfig.categories do
		if category.name == query.category then
			if query.chip == nil then
				return category.chips
			end
			for _, chip in category.chips do
				if chip.name == query.chip then
					return { chip }
				end
			end
		end
	end
	error(`[CatalogueClient] Unknown category/chip {query.category}/{tostring(query.chip)}`)
end

local function paramsFor(query: Query): CatalogSearchParams
	local assetTypes, bundleTypes = {}, {}
	for _, chip in chipsFor(query) do
		enumItems(Enum.AvatarAssetType, chip.assetTypes or {}, assetTypes)
		enumItems(Enum.BundleType, chip.bundleTypes or {}, bundleTypes)
	end
	local params = CatalogSearchParams.new()
	params.AssetTypes = assetTypes :: any
	params.BundleTypes = bundleTypes :: any
	params.SearchKeyword = query.keyword or ""
	params.SortType = (Enum.CatalogSortType :: any)[CatalogueConfig.sort]
	params.SortAggregation = (Enum.CatalogSortAggregation :: any)[CatalogueConfig.sortAggregation]
	params.IncludeOffSale = CatalogueConfig.includeOffSale
	params.Limit = CatalogueConfig.pageSize
	return params
end

local function keyFor(query: Query): string
	return `{query.category}|{query.chip or "All"}|{string.lower(query.keyword or "")}`
end

local function typeNameOf(value: any): string
	-- Results carry the type as a string or an EnumItem depending on the field.
	if typeof(value) == "EnumItem" then
		return value.Name
	end
	return tostring(value)
end

local function toItem(raw: any): Item
	local isBundle = raw.ItemType == "Bundle" or raw.ItemType == Enum.AvatarItemType.Bundle
	local typeName = typeNameOf(if isBundle then raw.BundleType else raw.AssetType)
	local where = placement[typeName] or { main = "", sub = typeName }
	local size = CatalogueConfig.thumbnailSize
	local item: Item = {
		id = if isBundle then -raw.Id else raw.Id,
		kind = if isBundle then "Bundle" else "Asset",
		targetId = raw.Id,
		name = raw.Name,
		main = where.main,
		sub = where.sub,
		typeName = typeName,
		price = raw.Price or raw.LowestPrice or 0,
		creator = raw.CreatorName or "",
		description = raw.Description or "",
		favourites = raw.FavoriteCount or 0,
		thumbnail = `rbxthumb://type={if isBundle then "BundleThumbnail" else "Asset"}&id={raw.Id}&w={size}&h={size}`,
		colour = "",
		owned = false,
	}
	-- Keep the existing object, so anything holding it stays current.
	local existing = seen[item.id]
	if existing then
		for k, v in item :: any do
			(existing :: any)[k] = v
		end
		return existing
	end
	seen[item.id] = item
	return item
end

local function appendPage(entry: Entry, page: { any })
	local have = {}
	for _, item in entry.items do
		have[item.id] = true
	end
	for _, raw in page do
		local item = toItem(raw)
		if not have[item.id] then
			have[item.id] = true
			table.insert(entry.items, item)
		end
	end
end

-- Runs a catalogue call, waiting out (and retrying once after) a throttle.
local function call<T>(fn: () -> T): (boolean, T | string)
	for attempt = 1, 2 do
		local wait = blockedUntil - os.clock()
		if wait > 0 then
			task.wait(wait)
		end
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		local message = tostring(result)
		if string.find(message, "429", 1, true) and attempt == 1 then
			blockedUntil = os.clock() + CatalogueConfig.backoffSeconds
		else
			return false, message
		end
	end
	return false, "throttled"
end

local function result(entry: Entry): Result
	return { items = entry.items, exhausted = entry.exhausted }
end

-- First page for a query. Yields; returns (ok, Result or error message).
function CatalogueClient.search(query: Query): (boolean, Result | string)
	local key = keyFor(query)
	local cached = cache[key]
	if cached and os.clock() - cached.fetchedAt < CatalogueConfig.cacheSeconds then
		return true, result(cached)
	end
	local params = paramsFor(query)
	local ok, pages = call(function()
		return AvatarEditorService:SearchCatalog(params)
	end)
	if not ok then
		return false, pages :: string
	end
	local catalogPages = pages :: CatalogPages
	local entry: Entry = { items = {}, pages = catalogPages, exhausted = catalogPages.IsFinished, fetchedAt = os.clock() }
	appendPage(entry, catalogPages:GetCurrentPage())
	cache[key] = entry
	return true, result(entry)
end

-- Appends the next page to a query already searched. Yields.
function CatalogueClient.loadMore(query: Query): (boolean, Result | string)
	local entry = cache[keyFor(query)]
	if not entry or not entry.pages then
		return CatalogueClient.search(query)
	end
	if entry.exhausted then
		return true, result(entry)
	end
	local pages = entry.pages :: CatalogPages
	local ok, err = call(function()
		pages:AdvanceToNextPageAsync()
		return true
	end)
	if not ok then
		return false, err :: string
	end
	appendPage(entry, pages:GetCurrentPage())
	entry.exhausted = pages.IsFinished
	return true, result(entry)
end

function CatalogueClient.item(id: number): Item?
	return seen[id]
end

function CatalogueClient.similar(item: Item, count: number): { Item }
	local sameSub, sameMain = {}, {}
	for _, other in seen do
		if other.id ~= item.id and other.main == item.main then
			table.insert(if other.sub == item.sub then sameSub else sameMain, other)
		end
	end
	local list = {}
	for _, group in { sameSub, sameMain } do
		for _, other in group do
			if #list >= count then
				return list
			end
			table.insert(list, other)
		end
	end
	return list
end

return CatalogueClient

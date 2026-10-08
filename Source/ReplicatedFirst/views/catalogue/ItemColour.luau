--!strict

--[[
	ItemColour (client)

	Works out an item's colours from its catalogue thumbnail, for the
	Catalogue's colour filter (the catalogue API has no colour facet). The
	thumbnail is read with AssetService:CreateEditableImageAsync (needs Game
	Settings › Security › Allow Mesh & Image APIs), sampled every few pixels,
	and each opaque pixel is sorted into a named colour bucket by HSV.

	  classify(item)        start working out an item's colours (no yield);
	                        fills item.colour (dominant) and item.colours
	                        (every bucket with a big enough share) when done
	  isDone(item)          classification finished (or failed) for this item
	  available()           false once reading thumbnails has failed for a
	                        permissions reason (then the filter can't work)
	  changed               signal fired (no args) whenever an item finishes,
	                        so views can re-render

	Loads run in parallel up to MAX_IN_FLIGHT; each image is destroyed as
	soon as it's read (EditableImage memory is budgeted).

	Bucket names match Tokens.swatch and CatalogueConfig.colours.
]]

local AssetService = game:GetService("AssetService")

local ItemColour = {}

-- An item is "that colour" if the colour covers this share of its opaque
-- pixels (after weighting); the biggest bucket is always included.
local SHARE = 0.22
-- Chromatic colours count a little more than black/grey/white, so shading
-- and outlines don't drown out a garment's actual colour.
local CHROMA_WEIGHT = 1.3
local SAMPLE_STEP = 3 -- read every 3rd pixel in each direction
local MAX_IN_FLIGHT = 12

type Entry = { done: boolean, colours: { string }? }

local entries: { [number]: Entry } = {}
local queue: { any } = {}
local inFlight = 0
local permitted = true

local changedEvent = Instance.new("BindableEvent")
ItemColour.changed = changedEvent.Event

-- Skin-tone pixels (bare arms, legs, feet in thumbnails) count this much,
-- so skin only decides an item's colour when there's nothing else to see.
local SKIN_WEIGHT = 0.15

-- Tuned against real thumbnails: pale skin is low-saturation (so the grey
-- line is s < 0.2, not lower), light skin is an orange hue at modest
-- saturation, and very dark reds read as brown.
local function bucket(r: number, g: number, b: number): (string, number)
	local h, s, v = Color3.fromRGB(r, g, b):ToHSV()
	local deg = h * 360
	if v < 0.2 or (v < 0.3 and s < 0.35) then
		return "Black", 1
	elseif s < 0.2 then
		return if v >= 0.72 then "White" else "Grey", 1
	end
	local skin = deg >= 5 and deg < 40 and s < 0.5 and v >= 0.45
	local weight = if skin then SKIN_WEIGHT else CHROMA_WEIGHT
	if (deg >= 10 and deg < 45 and v < 0.62 and s >= 0.3) or ((deg < 10 or deg >= 350) and v < 0.4) then
		return "Brown", weight
	elseif deg < 12 or deg >= 345 then
		return if s < 0.5 and v > 0.75 then "Pink" else "Red", weight
	elseif deg < 40 then
		return "Orange", weight
	elseif deg < 70 then
		return "Yellow", weight
	elseif deg < 165 then
		return "Green", weight
	elseif deg < 255 then
		return "Blue", weight
	elseif deg < 290 then
		return "Purple", weight
	end
	return "Pink", weight
end

local function read(item: any): { string }
	local image = AssetService:CreateEditableImageAsync(Content.fromUri(item.thumbnail))
	local size = image.Size
	local pixels = image:ReadPixelsBuffer(Vector2.zero, size)
	image:Destroy()

	local weights: { [string]: number } = {}
	local total = 0
	for y = 0, size.Y - 1, SAMPLE_STEP do
		for x = 0, size.X - 1, SAMPLE_STEP do
			local i = (y * size.X + x) * 4
			if buffer.readu8(pixels, i + 3) > 128 then
				local name, weight = bucket(buffer.readu8(pixels, i), buffer.readu8(pixels, i + 1), buffer.readu8(pixels, i + 2))
				weights[name] = (weights[name] or 0) + weight
				total += weight
			end
		end
	end

	local ranked = {}
	for name, weight in weights do
		table.insert(ranked, { name = name, share = weight / math.max(total, 1) })
	end
	table.sort(ranked, function(a, b)
		return a.share > b.share
	end)
	local colours = {}
	for index, entry in ranked do
		if index == 1 or entry.share >= SHARE then
			table.insert(colours, entry.name)
		end
	end
	return colours
end

local pump

local function finish(item: any, colours: { string }?)
	local entry = entries[item.id]
	entry.done = true
	entry.colours = colours
	if colours then
		item.colours = colours
		item.colour = colours[1] or ""
	end
	inFlight -= 1
	changedEvent:Fire()
	pump()
end

function pump()
	while inFlight < MAX_IN_FLIGHT and #queue > 0 do
		local item = table.remove(queue, 1)
		inFlight += 1
		task.spawn(function()
			local ok, result = pcall(read, item)
			if ok then
				finish(item, result)
			else
				local message = tostring(result)
				-- Permission failures mean the filter can't work here at all.
				if string.find(string.lower(message), "permission") or string.find(message, "not accessible") then
					if permitted then
						warn("[ItemColour] Can't read thumbnails: " .. message)
					end
					permitted = false
				end
				finish(item, nil)
			end
		end)
	end
end

function ItemColour.classify(item: any)
	if entries[item.id] or item.thumbnail == "" or not permitted then
		return
	end
	entries[item.id] = { done = false }
	table.insert(queue, item)
	pump()
end

function ItemColour.isDone(item: any): boolean
	local entry = entries[item.id]
	return entry ~= nil and entry.done
end

-- Whether a classified item counts as `colour`.
function ItemColour.matches(item: any, colour: string): boolean
	local entry = entries[item.id]
	if not entry or not entry.colours then
		return false
	end
	return table.find(entry.colours, colour) ~= nil
end

function ItemColour.available(): boolean
	return permitted
end

return ItemColour

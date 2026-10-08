--!strict

--[[
	useColourFilter

	Narrows useCatalogue's results to one colour, client-side: the catalogue
	API has no colour facet, so each loaded item's thumbnail is classified by
	ItemColour and only matches are shown. While a colour is picked it keeps
	loading pages (as the classifications come in) until
	CatalogueConfig.colourTarget items match or colourMaxPages pages have been
	looked through, so the paging stays out of sight. Scrolling to the end
	still loads more past that.

	With no colour ("") it passes the catalogue's results straight through.

	Returns the same shape as useCatalogue, plus status "unavailable" when
	thumbnails can't be read here (permissions).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local CatalogueConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CatalogueConfig"))

local ItemColour = require(script.Parent.Parent:WaitForChild("catalogue"):WaitForChild("ItemColour"))

local function useColourFilter(catalogue: any, colour: string)
	local _version, setVersion = React.useState(0)
	local active = colour ~= ""

	-- Re-render as classifications finish (batched to one per frame).
	React.useEffect(function()
		if not active then
			return nil
		end
		local queued = false
		local connection = ItemColour.changed:Connect(function()
			if not queued then
				queued = true
				task.defer(function()
					queued = false
					setVersion(function(v: number)
						return v + 1
					end)
				end)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { active })

	-- Classify whatever is loaded.
	React.useEffect(function()
		if active then
			for _, item in catalogue.items do
				ItemColour.classify(item)
			end
		end
	end, { active, #catalogue.items } :: { any })

	local matched = {}
	local allDone = true
	if active then
		for _, item in catalogue.items do
			if not ItemColour.isDone(item) then
				allDone = false
			elseif ItemColour.matches(item, colour) then
				table.insert(matched, item)
			end
		end
	end
	local pages = math.ceil(#catalogue.items / CatalogueConfig.pageSize)
	local wantMore = active
		and #matched < CatalogueConfig.colourTarget
		and not catalogue.exhausted
		and pages < CatalogueConfig.colourMaxPages

	-- Keep fetching until enough match (or the page cap).
	React.useEffect(function()
		if wantMore and allDone and catalogue.status == "ready" then
			catalogue.loadMore()
		end
	end, { wantMore, allDone, catalogue.status, #catalogue.items } :: { any })

	if not active then
		return catalogue
	end

	local status = catalogue.status
	if not ItemColour.available() then
		status = "unavailable"
	elseif status == "ready" and (not allDone or wantMore) then
		status = "loading"
	end
	return {
		items = matched,
		status = status,
		exhausted = catalogue.exhausted,
		loadMore = catalogue.loadMore,
	}
end

return useColourFilter

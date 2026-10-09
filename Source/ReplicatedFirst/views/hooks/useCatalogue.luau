--!strict

--[[
	useCatalogue

	Live catalogue results for a query (category, chip, keyword and filters),
	via CatalogueClient. Changes to the typed fields (keyword, creator) wait
	CatalogueConfig.searchDebounce before searching; everything else (tab,
	chip, sort, price, sales type, off-sale) searches at once. A slower, older
	search never overwrites a newer one. An empty category means "don't
	search" (e.g. a mock item's More like this): no items, status "ready".

	Returns:
		items: { Item }
		status: "loading" | "ready" | "error"
		exhausted: boolean      no more pages
		loadMore: () -> ()      fetch the next page (no-op while loading)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local CatalogueConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CatalogueConfig"))

local CatalogueClient = require(script.Parent.Parent:WaitForChild("catalogue"):WaitForChild("CatalogueClient"))

export type Status = "loading" | "ready" | "error"

local function trim(text: string?): string
	return string.match(text or "", "^%s*(.-)%s*$") or ""
end

local function useCatalogue(input: CatalogueClient.Query)
	local state, setState = React.useState({
		items = {} :: { CatalogueClient.Item },
		status = "loading" :: Status,
		exhausted = false,
	})
	local generation = React.useRef(0)
	local loading = React.useRef(nil :: number?) -- generation of the fetch in flight

	local query: CatalogueClient.Query = table.clone(input)
	query.keyword = trim(input.keyword)
	query.creator = trim(input.creator)
	local typed = query.keyword .. "\0" .. query.creator
	local lastTyped = React.useRef(typed)

	local function run(fetch: (CatalogueClient.Query) -> (boolean, any), q: CatalogueClient.Query, mine: number)
		loading.current = mine
		local ok, result = fetch(q)
		if loading.current == mine then
			loading.current = nil
		end
		if generation.current ~= mine then
			return -- a newer search took over
		end
		if ok then
			setState({ items = table.clone(result.items), status = "ready", exhausted = result.exhausted })
		else
			warn("[useCatalogue] " .. tostring(result))
			setState(function(current)
				return { items = current.items, status = "error", exhausted = current.exhausted }
			end)
		end
	end

	React.useEffect(function()
		generation.current += 1
		local mine = generation.current
		local typing = lastTyped.current ~= typed
		lastTyped.current = typed
		-- Typing keeps the old results up while the new ones load; any other
		-- change clears them, so another tab's or filter's items never linger.
		if query.category == "" then
			setState({ items = {}, status = "ready", exhausted = true })
			return nil
		end
		setState(function(current)
			return { items = if typing then current.items else {}, status = "loading", exhausted = false }
		end)
		local started = false
		local thread = task.delay(if typing then CatalogueConfig.searchDebounce else 0, function()
			started = true
			run(CatalogueClient.search, query, mine)
		end)
		return function()
			-- Only cancel the wait; a search already under way finishes and is
			-- ignored by the generation check.
			if not started then
				task.cancel(thread)
			end
		end
	end, {
		query.category,
		query.chip or "",
		query.keyword,
		query.creator,
		tostring(query.minPrice),
		tostring(query.maxPrice),
		query.sort or "",
		query.sortWindow or "",
		query.salesType or "",
		tostring(query.includeOffSale),
	} :: { any })

	local function loadMore()
		if query.category == "" or loading.current ~= nil or state.exhausted or state.status ~= "ready" then
			return
		end
		local mine = generation.current
		task.spawn(run, CatalogueClient.loadMore, query, mine)
	end

	return {
		items = state.items,
		status = state.status,
		exhausted = state.exhausted,
		loadMore = loadMore,
	}
end

return useCatalogue

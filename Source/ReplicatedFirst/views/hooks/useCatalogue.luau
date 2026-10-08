--!strict

--[[
	useCatalogue

	Live catalogue results for a category / chip / keyword, via CatalogueClient.
	Keyword changes wait CatalogueConfig.searchDebounce before searching;
	category and chip changes search at once. A slower, older search never
	overwrites a newer one.

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

local function useCatalogue(category: string, chip: string?, keyword: string)
	local state, setState = React.useState({
		items = {} :: { CatalogueClient.Item },
		status = "loading" :: Status,
		exhausted = false,
	})
	local generation = React.useRef(0)
	local loading = React.useRef(nil :: number?) -- generation of the fetch in flight
	local trimmed = string.gsub(keyword, "^%s*(.-)%s*$", "%1")
	local lastKeyword = React.useRef(trimmed)
	local query: CatalogueClient.Query = { category = category, chip = chip, keyword = trimmed }

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
		local typing = lastKeyword.current ~= trimmed
		lastKeyword.current = trimmed
		-- Typing keeps the old results up while the new ones load; a new
		-- category or chip clears them, so another tab's items never linger.
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
	end, { category, chip or "", trimmed } :: { any })

	local function loadMore()
		if loading.current ~= nil or state.exhausted or state.status ~= "ready" then
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

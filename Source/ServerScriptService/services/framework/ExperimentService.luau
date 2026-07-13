--!strict

--[[
	ExperimentService
	Deterministic A/B & multivariate test assignment.

	A player's cohort is a pure function of (UserId, experiment salt) — nothing is
	stored. This gives sticky assignment for free: the same player hashes to the
	same cohort on every server, forever, surviving DataStore wipes and needing no
	migration. To reshuffle a live test (or start a fresh generation), bump the
	experiment's `salt` in ExperimentsConfig.

	Config lives in Studio at ReplicatedStorage.Config.ExperimentsConfig (designer-
	editable); its schema + validation are in ExperimentsConfigTypes. When the
	config module is absent, every lookup is a no-op (nil) — experiments are simply
	inactive. When it's present but fails validation, the service warns and stays
	inactive rather than letting a malformed config error mid-assignment.

	Typical use:
	  local dur = ExperimentService.getNumber(player, "match_length")  -- numericRange
	  local key = ExperimentService.getVariantKey(player, "some_test") -- for analytics
	  local a   = ExperimentService.getAssignment(player, "some_test") -- { key, value }

	See ExperimentsConfigTypes for the config shape and the numericRange / variants
	semantics.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExperimentService = {}

export type Assignment = {
	key: string,   -- cohort label (variant key, or the numeric value as a string)
	value: any,    -- variant payload, the numeric value, or nil for control
}

type ExperimentDef = {
	enabled: boolean,
	salt: string,
	exposure: number?,
	kind: string,
	range: { min: number, max: number, step: number }?,
	variants: { { key: string, weight: number, payload: any? } }?,
}

-- Lazily-resolved config (nil until first access). `_loaded` distinguishes
-- "not yet looked up" from "looked up, absent/invalid" so we only probe the tree
-- once.
local _config: { experiments: { [string]: ExperimentDef } }? = nil
local _loaded = false

local function getConfig(): { experiments: { [string]: ExperimentDef } }?
	if not _loaded then
		_loaded = true
		local configFolder = ReplicatedStorage:FindFirstChild("Config")
		local module = configFolder and configFolder:FindFirstChild("ExperimentsConfig")
		if module and module:IsA("ModuleScript") then
			local loaded = require(module) :: any

			-- Validate on load. On failure, warn and leave experiments inactive
			-- rather than letting a malformed config error deep inside an
			-- assignment call. (UEFA validates in ModelRunner at startup; the
			-- template has no such harness, so the service self-validates.)
			local configTypes = configFolder :: any
			local typesModule = configTypes:FindFirstChild("ConfigTypes")
				and configTypes.ConfigTypes:FindFirstChild("ExperimentsConfigTypes")
			if typesModule and typesModule:IsA("ModuleScript") then
				local ok, err = pcall(function()
					(require(typesModule) :: any).validate(loaded)
				end)
				if not ok then
					warn("[ExperimentService] ExperimentsConfig failed validation — experiments inactive:\n" .. tostring(err))
					return nil
				end
			end

			_config = loaded
		end
	end
	return _config
end

-- Map an arbitrary string to a well-distributed value in [0, 1).
--
-- DJB2 accumulation in a 32-bit lane (every intermediate stays under 2^53, so
-- double precision is exact), finished with Knuth's multiplicative constant to
-- avalanche the low bits — otherwise near-identical inputs (userId + ":variant"
-- vs userId + ":enroll") would land in adjacent buckets. This is a bucketing
-- hash, not a cryptographic one.
local function hashUnit(input: string): number
	local h = 5381
	for i = 1, #input do
		h = ((h * 33) + string.byte(input, i)) % 4294967296
	end
	h = (h * 2654435761) % 4294967296 -- Knuth multiplicative finalizer
	return h / 4294967296
end

--[[
	getAssignment - Resolve a player's cohort for one experiment.
	Returns nil when the experiment is missing/disabled/misconfigured or no
	config exists. Held-out (non-enrolled) players return { key = "control" } with
	a nil value.
]]
function ExperimentService.getAssignment(player: Player, experimentKey: string): Assignment?
	local config = getConfig()
	if not config then
		return nil
	end
	local exp = config.experiments[experimentKey]
	if not exp or not exp.enabled then
		return nil
	end

	local base = tostring(player.UserId) .. ":" .. exp.salt

	-- Enrollment gate (independent hash lane so tuning exposure doesn't reshuffle
	-- which variant an enrolled player receives).
	local exposure = exp.exposure or 1
	if exposure < 1 and hashUnit(base .. ":enroll") >= exposure then
		return { key = "control", value = nil }
	end

	local u = hashUnit(base .. ":variant")

	if exp.kind == "numericRange" and exp.range then
		local r = exp.range
		-- Number of grid points across [min, max] inclusive.
		local buckets = math.floor((r.max - r.min) / r.step + 1e-9) + 1
		local idx = math.floor(u * buckets)
		if idx >= buckets then
			idx = buckets - 1 -- guard the u→1 edge
		end
		local value = r.min + idx * r.step
		return { key = tostring(value), value = value }
	elseif exp.kind == "variants" and exp.variants then
		local total = 0
		for _, variant in exp.variants do
			total += variant.weight
		end
		local pick = u * total
		local acc = 0
		for _, variant in exp.variants do
			acc += variant.weight
			if pick < acc then
				return { key = variant.key, value = variant.payload }
			end
		end
		-- Floating-point edge: fall back to the last variant.
		local last = exp.variants[#exp.variants]
		return { key = last.key, value = last.payload }
	end

	return nil
end

--[[
	getNumber - Convenience for numericRange experiments. Returns the assigned
	number, or nil when unassigned / held out (caller should use its own default).
]]
function ExperimentService.getNumber(player: Player, experimentKey: string): number?
	local assignment = ExperimentService.getAssignment(player, experimentKey)
	if assignment and type(assignment.value) == "number" then
		return assignment.value
	end
	return nil
end

--[[
	getVariantKey - The cohort label for analytics stamping, or nil when the
	experiment is inactive for this player.
]]
function ExperimentService.getVariantKey(player: Player, experimentKey: string): string?
	local assignment = ExperimentService.getAssignment(player, experimentKey)
	return if assignment then assignment.key else nil
end

--[[
	getEnabledKeys - Ordered-agnostic list of enabled experiment keys, used by the
	analytics wiring to auto-register one cohort dimension per experiment.
]]
function ExperimentService.getEnabledKeys(): { string }
	local keys = {}
	local config = getConfig()
	if config then
		for key, exp in config.experiments do
			if exp.enabled then
				table.insert(keys, key)
			end
		end
	end
	return keys
end

return ExperimentService

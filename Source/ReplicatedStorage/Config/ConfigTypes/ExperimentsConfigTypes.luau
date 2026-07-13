--!strict

--[[
	ExperimentsConfigTypes - Type definitions for the A/B & multivariate test config

	This file contains the type definitions and validation logic for the
	experiment system. The actual configuration data is stored separately in
	ExperimentsConfig (Roblox Studio, ReplicatedStorage.Config) so designers can
	tune it without a code change.

	Assignment is deterministic: a player's cohort is a pure hash of
	(UserId, experiment salt) — see ExperimentService. No cohort is ever stored,
	so a player always lands in the same cohort on any server, forever. To
	re-shuffle a live test (or start a fresh generation) bump the experiment's
	`salt`.

	Two experiment shapes cover ~every test:
	  - "numericRange" — assigns a number in [min, max] on a `step` grid. Use for
	    dose-response sweeps (e.g. match length 10..60s by 1s). The cohort key is
	    the assigned number as a string ("42").
	  - "variants"     — classic A/B/n. Weighted list; each variant carries an
	    arbitrary `payload` the consumer reads. The cohort key is the variant key.

	`exposure` (0..1, default 1) is the fraction of players enrolled; the rest are
	held out as "control" (numericRange → no value, consumer uses its default;
	variants → key "control", nil payload). Enrollment uses an independent hash
	lane from variant selection, so changing `exposure` does not reshuffle which
	variant an already-enrolled player gets.

	Example ExperimentsConfig (author this in Studio at
	ReplicatedStorage.Config.ExperimentsConfig):

		return {
			experiments = {
				match_length = {
					enabled = true,
					salt = "match_length_v1",
					kind = "numericRange",
					range = { min = 15, max = 60, step = 1 },
				},
				reward_style = {
					enabled = false,
					salt = "reward_style_v1",
					exposure = 0.5,
					kind = "variants",
					variants = {
						{ key = "A", weight = 1, payload = { multiplier = 1.0 } },
						{ key = "B", weight = 1, payload = { multiplier = 1.5 } },
					},
				},
			},
		}
]]

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

export type VariantDef = {
	key: string,       -- cohort label emitted to analytics
	weight: number,    -- relative selection weight (> 0)
	payload: any?,     -- arbitrary value handed to the consumer for this variant
}

export type NumericRange = {
	min: number,       -- inclusive low end
	max: number,       -- inclusive high end
	step: number,      -- grid granularity (> 0)
}

export type ExperimentDef = {
	enabled: boolean,          -- off = never assigned, never stamped
	salt: string,              -- hashing seed; bump to reshuffle / new generation
	exposure: number?,         -- fraction enrolled, 0..1 (default 1 = everyone)
	kind: string,              -- "numericRange" | "variants"
	range: NumericRange?,      -- required when kind == "numericRange"
	variants: { VariantDef }?, -- required when kind == "variants"
}

export type ExperimentsConfig = {
	experiments: { [string]: ExperimentDef },
}

-- ============================================================================
-- VALIDATION
-- ============================================================================

local function validate(config: ExperimentsConfig)
	local errors = {}

	if type(config) ~= "table" or type(config.experiments) ~= "table" then
		error("ExperimentsConfig validation failed:\nconfig.experiments must be a table")
	end

	for key, exp in config.experiments do
		local prefix = string.format("experiment '%s': ", tostring(key))

		if type(exp.enabled) ~= "boolean" then
			table.insert(errors, prefix .. "enabled must be a boolean")
		end
		if type(exp.salt) ~= "string" or exp.salt == "" then
			table.insert(errors, prefix .. "salt must be a non-empty string")
		end
		if exp.exposure ~= nil then
			if type(exp.exposure) ~= "number" or exp.exposure < 0 or exp.exposure > 1 then
				table.insert(errors, prefix .. "exposure must be a number in [0, 1]")
			end
		end

		if exp.kind == "numericRange" then
			local r = exp.range
			if type(r) ~= "table" then
				table.insert(errors, prefix .. "range must be a table for kind 'numericRange'")
			else
				if type(r.min) ~= "number" or type(r.max) ~= "number" or type(r.step) ~= "number" then
					table.insert(errors, prefix .. "range.min/max/step must all be numbers")
				elseif r.step <= 0 then
					table.insert(errors, prefix .. "range.step must be > 0")
				elseif r.max < r.min then
					table.insert(errors, prefix .. "range.max must be >= range.min")
				end
			end
		elseif exp.kind == "variants" then
			local v = exp.variants
			if type(v) ~= "table" or #v == 0 then
				table.insert(errors, prefix .. "variants must be a non-empty array for kind 'variants'")
			else
				local seenKeys: { [string]: boolean } = {}
				for i, variant in v do
					if type(variant.key) ~= "string" or variant.key == "" then
						table.insert(errors, prefix .. string.format("variants[%d].key must be a non-empty string", i))
					elseif seenKeys[variant.key] then
						table.insert(errors, prefix .. string.format("duplicate variant key '%s'", variant.key))
					else
						seenKeys[variant.key] = true
					end
					if type(variant.weight) ~= "number" or variant.weight <= 0 then
						table.insert(errors, prefix .. string.format("variants[%d].weight must be a number > 0", i))
					end
				end
			end
		else
			table.insert(errors, prefix .. "kind must be 'numericRange' or 'variants' (got " .. tostring(exp.kind) .. ")")
		end
	end

	if #errors > 0 then
		error("ExperimentsConfig validation failed:\n" .. table.concat(errors, "\n"))
	end

	print("✓ ExperimentsConfig validated successfully")
end

-- ============================================================================

return { validate = validate }

--!strict

--[[
	AnalyticsDimensions

	EXAMPLE / TEMPLATE — customise this per game.

	Game-specific wiring for AnalyticsService "global dimensions": absolute model
	values (gold, xp, level, …) stamped onto (almost) every analytics event, so
	ANY event can be segmented by player progression in BigQuery (e.g. "what do
	players with 0 gold do vs 10k+"). Registering a resolver here keeps
	AnalyticsService itself model-agnostic and reusable across games — swap this
	module's resolvers for your game's models.

	How it fits together:
	  1. Register a resolver per dimension key below (registerDimension).
	  2. Turn each one ON by listing its key in AnalyticsConfig.globalParams,
	     e.g. globalParams = { "gold" }. A registered key that ISN'T in
	     globalParams is simply never stamped — registering is harmless.
	  3. AnalyticsService stamps the enabled keys onto every event except the
	     aggregate / pre-hydration events it excludes (heatmap_summary,
	     player_join — where there's no meaningful per-player value yet).

	Resolvers MUST be non-yielding — they run inline while an event is queued.
	Reading a per-player model is safe here: by the time a player is firing
	events their models are already loaded, so Model.get returns immediately
	rather than waiting. Return nil to omit the param (model absent / not ready).

	This module is a game service: ServiceRunner auto-discovers it and calls
	init() — no manual wiring needed.
]]

local AnalyticsService = require(script.Parent.Parent.framework.AnalyticsService)
local ExperimentService = require(script.Parent.Parent.framework.ExperimentService)
local InventoryModel = require(script.Parent.Parent.Parent.models.user.InventoryModel)

local AnalyticsDimensions = {}

function AnalyticsDimensions.init()
	-- Example dimension. Enable it by adding "gold" to AnalyticsConfig.globalParams.
	-- Replace / extend with your game's own progression values.
	AnalyticsService.registerDimension("gold", function(player: Player): any
		local model = InventoryModel.get(tostring(player.UserId))
		return if model then model.gold else nil
	end)

	-- Experiment cohorts: one dimension per enabled experiment, keyed "exp_<name>"
	-- (e.g. "exp_match_length"). Registered with always = true so the cohort rides
	-- every event (cohorts are deterministic — no model hydration needed — so this
	-- is safe pre-hydration; see ExperimentService). Auto-derived from
	-- ExperimentsConfig, so adding a test needs no analytics or globalParams edit.
	for _, experimentKey in ExperimentService.getEnabledKeys() do
		local paramKey = "exp_" .. experimentKey
		AnalyticsService.registerDimension(paramKey, function(player: Player): any
			return ExperimentService.getVariantKey(player, experimentKey)
		end, true)
	end
end

return AnalyticsDimensions

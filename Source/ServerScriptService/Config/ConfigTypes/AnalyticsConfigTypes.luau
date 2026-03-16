--!strict
--[[
	AnalyticsConfigTypes
	Type definitions for GA4 analytics configuration

	The AnalyticsConfig lives in ServerScriptService (not ReplicatedStorage) because
	it contains an API secret that should not be visible to clients.

	Create the config in Studio: ServerScriptService > Config > AnalyticsConfig (ModuleScript)
]]

export type AnalyticsConfig = {
	enabled: boolean,
	measurementId: string,
	apiSecret: string,
	hashSalt: string,
	flushIntervalSeconds: number,
	maxBatchSize: number,
	debug: boolean,
}

return nil

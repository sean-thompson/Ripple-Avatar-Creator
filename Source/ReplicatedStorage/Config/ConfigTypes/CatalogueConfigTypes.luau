--!strict
--[[
    CatalogueConfigTypes
    Type definitions for the catalogue: the marketplace-style category tabs,
    their chips (each a set of catalogue item types to search), and search
    tuning. Read by the client, which searches the catalogue directly.

    Type names are Enum.AvatarAssetType / Enum.BundleType item names
    ("HairAccessory", "DynamicHead"), kept as strings so the config stays data.
]]

export type CatalogueChip = {
    name: string,
    assetTypes: { string }?, -- Enum.AvatarAssetType names
    bundleTypes: { string }?, -- Enum.BundleType names
}

export type CatalogueCategory = {
    name: string, -- top-level tab
    chips: { CatalogueChip }, -- in display order; "All" (every chip's types) is implicit
}

export type CatalogueConfig = {
    categories: { CatalogueCategory },
    pageSize: number, -- items per catalogue page (10–120)
    sort: string, -- Enum.CatalogSortType name
    sortAggregation: string, -- Enum.CatalogSortAggregation name (for sorts over a time window)
    includeOffSale: boolean,
    cacheSeconds: number, -- how long a query's results are reused
    searchDebounce: number, -- seconds of no typing before a keyword search runs
    backoffSeconds: number, -- pause after the catalogue throttles us (HTTP 429)
    thumbnailSize: number, -- rbxthumb size: 48, 60, 150 or 420
}

return nil

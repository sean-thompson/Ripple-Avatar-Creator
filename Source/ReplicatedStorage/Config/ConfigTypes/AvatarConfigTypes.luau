--!strict
--[[
    AvatarConfigTypes
    Type definitions for try-on: which catalogue item types can be worn, how
    they replace or stack with each other, and request limits. Read by the
    server (AvatarController / AvatarModel / AvatarService).

    Type names are the catalogue's Enum.AvatarAssetType / Enum.BundleType
    item names ("HairAccessory", "Shoes"), as CatalogueClient reports them.
]]

export type AvatarConfig = {
    -- One at a time: wearing an item replaces whatever is in its slot.
    slots: { [string]: string }, -- typeName -> slot name
    -- Several at once, up to the group's limit (the oldest goes first).
    groups: { [string]: string }, -- typeName -> group name
    groupLimits: { [string]: number }, -- group name -> how many
    tryOnCooldown: number, -- seconds between a player's try-on requests
    undoDepth: number, -- how many changes Undo can step back through
    maxWearMany: number, -- most items in one Wear-all request
}

return nil

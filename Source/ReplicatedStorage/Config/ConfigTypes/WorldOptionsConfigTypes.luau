--!strict
--[[
    WorldOptionsConfigTypes
    Type definitions for the World options panel, its saved preferences and
    double-jump flight. Shared: the server validates against it, the client
    builds the panel and renders from it.
]]

export type WorldOptionsDefaults = {
    time: number,
    sky: string,
    floor: string, -- hex, one of floorColors
    floorLightness: number, -- percent multiplier on the floor colour
    pattern: string,
    patternColor: string, -- hex, one of patternColors
    patternLightness: number, -- percent multiplier on the pattern colour
    patternStrength: number, -- percent opacity of the pattern
    brightness: number,
    shadows: boolean,
}

export type FlightConfig = {
    enabled: boolean,
    speed: number, -- studs/s while moving
    climbSpeed: number, -- studs/s while holding jump
    doubleJumpWindow: number, -- seconds between jump presses to toggle flight
}

export type WorldOptionsConfig = {
    timeMin: number,
    timeMax: number,
    timeStep: number,
    brightnessMin: number, -- percent
    brightnessMax: number,
    brightnessStep: number,
    skies: { string }, -- preset names, in panel order
    patterns: { string },
    floorColors: { string }, -- hex, in panel order; saved as the hex itself
    lightnessMin: number, -- percent, shared by floor and pattern lightness
    lightnessMax: number,
    lightnessStep: number,
    patternColors: { string }, -- hex, in panel order; saved as the hex itself
    patternStrengthMin: number, -- percent
    patternStrengthMax: number,
    patternStrengthStep: number,
    defaults: WorldOptionsDefaults,
    flight: FlightConfig,
}

return nil

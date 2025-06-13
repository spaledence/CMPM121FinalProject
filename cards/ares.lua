-- cards/ares.lua

local BaseCard = require("cards.baseCard")
local Ares = setmetatable({}, { __index = BaseCard })
Ares.__index = Ares

function Ares:new()
    local o = BaseCard:new(
        "Ares",
        3,
        4,
        "When Revealed: Gain +1 power for each other friendly card at this location."
    )
    setmetatable(o, Ares)
    return o
end

function Ares:onReveal(gameState)
    -- Find the location this card is in
    local location = gameState.locations[self.location]
    if not location then return end

    local slots = (self.owner == "player") and location.playerSlots or location.aiSlots
    local count = 0

    for _, card in pairs(slots) do
        if card ~= self then
            count = count + 1
        end
    end

    self.power = self.power + count
end

return Ares
-- cards/medusa.lua

local BaseCard = require("cards.baseCard")
local Medusa = setmetatable({}, { __index = BaseCard })
Medusa.__index = Medusa

function Medusa:new()
    local o = BaseCard:new(
        "Medusa",
        4,
        3,
        "When Revealed: Reduce the power of all other cards at this location by 1."
    )
    setmetatable(o, Medusa)
    return o
end

function Medusa:onReveal(gameState)
    local location = gameState.locations[self.location]
    if not location then return end

    local allSlots = {}

    for _, card in pairs(location.playerSlots) do
        table.insert(allSlots, card)
    end
    for _, card in pairs(location.aiSlots) do
        table.insert(allSlots, card)
    end

    for _, card in ipairs(allSlots) do
        if card and card ~= self then
            card.power = math.max(0, (card.power or 0) - 1)
        end
    end
end

return Medusa
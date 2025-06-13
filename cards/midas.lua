-- cards/midas.lua

local BaseCard = require("cards.baseCard")

local Midas = {}
Midas.__index = Midas
setmetatable(Midas, {
    __index = BaseCard,
    __call = function(_, ...)
        return Midas:new(...)
    end
})

function Midas:new()
    local card = BaseCard:new("Midas", 5, 2, "Set all cards in this location to 3 power.")
    setmetatable(card, Midas)
    return card
end

function Midas:onReveal(gameState)
    for _, loc in ipairs(gameState.locations) do
        if loc.id == self.location then
            for _, card in pairs(loc.playerSlots) do
                if card then
                    card.power = 3
                end
            end
            for _, card in pairs(loc.aiSlots) do
                if card then
                    card.power = 3
                end
            end
        end
    end
end

return Midas
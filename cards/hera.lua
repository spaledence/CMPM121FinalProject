-- cards/hera.lua

local BaseCard = require("cards.baseCard")

local Hera = {}
Hera.__index = Hera
setmetatable(Hera, {
    __index = BaseCard,
    __call = function(_, ...)
        return Hera:new(...)
    end
})

function Hera:new()
    local card = BaseCard:new("Hera", 3, 2, "On reveal: Increase the power of all cards in your hand by 1.")
    setmetatable(card, Hera)
    return card
end

function Hera:onReveal(gameState)
    local ownerRef = self.owner == "player" and gameState.player or gameState.ai
    for _, card in ipairs(ownerRef.hand) do
        card.power = card.power + 1
    end
end

return Hera
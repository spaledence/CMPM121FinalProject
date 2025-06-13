-- cards/apollo.lua

local BaseCard = require("cards.baseCard")

local Apollo = {}
Apollo.__index = Apollo
setmetatable(Apollo, {
    __index = BaseCard,
    __call = function(_, ...)
        return Apollo:new(...)
    end
})

function Apollo:new()
    local card = BaseCard:new("Apollo", 2, 2, "On reveal: Gain 1 extra mana next turn.")
    setmetatable(card, Apollo)
    return card
end

function Apollo:onReveal(gameState)
    local ownerRef = self.owner == "player" and gameState.player or gameState.ai
    ownerRef.bonusMana = (ownerRef.bonusMana or 0) + 1
end

return Apollo
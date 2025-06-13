-- cards/hermes.lua

local BaseCard = require("cards.baseCard")
local Hermes = {}
Hermes.__index = Hermes
setmetatable(Hermes, { __index = BaseCard })

function Hermes:new()
    local this = BaseCard:new("Hermes", 3, 4, "On reveal: Trash 1 random opponent card from their hand.")
    setmetatable(this, Hermes)
    return this
end

function Hermes:onReveal(gameState)
    local opponent = self.owner == "player" and gameState.ai or gameState.player
    if #opponent.hand > 0 then
        local index = math.random(#opponent.hand)
        local removed = table.remove(opponent.hand, index)
        -- Optionally discard it if you want
        table.insert(opponent.discardPile, removed)
    end
end

return Hermes
-- cards/hades.lua

local BaseCard = require("cards.baseCard")
local Hades = setmetatable({}, { __index = BaseCard })
Hades.__index = Hades

function Hades:new()
    local o = BaseCard:new(
        "Hades",
        5,
        4,
        "When Revealed: Gain +1 power for each card in your discard pile."
    )
    setmetatable(o, Hades)
    return o
end

function Hades:onReveal(gameState)
    local discard = (self.owner == "player") and gameState.player.discardPile
                                              or gameState.ai.discardPile
    self.power = self.power + #discard
end

return Hades
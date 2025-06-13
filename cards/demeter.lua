-- cards/demeter.lua

local BaseCard = require("cards.baseCard")
local Demeter = setmetatable({}, { __index = BaseCard })
Demeter.__index = Demeter

function Demeter:new()
    local o = BaseCard:new(
        "Demeter",
        1,
        1,
        "When Revealed: Both players draw a card."
    )
    setmetatable(o, Demeter)
    return o
end

function Demeter:onReveal(gameState)
    gameState.player:drawCard()
    gameState.ai:drawCard()
end

return Demeter
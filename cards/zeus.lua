-- cards/zeus.lua

local BaseCard = require("cards.baseCard")
local Zeus = setmetatable({}, { __index = BaseCard })
Zeus.__index  = Zeus

function Zeus:new()
    -- name, cost, power, text
    local o = BaseCard:new(
        "Zeus",
        4,
        4,
        "When Revealed: Lower the power of each card in your opponent's hand by 1."
    )
    setmetatable(o, Zeus)
    return o
end

function Zeus:onReveal(gameState)
    local opponentHand
    if self.owner == "player" then
        opponentHand = gameState.ai.hand
    else
        opponentHand = gameState.player.hand
    end

    for _, card in ipairs(opponentHand) do
        card.power = math.max(0, card.power - 1)
    end
end

return Zeus
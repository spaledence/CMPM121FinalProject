-- cards/aphrodite.lua

local BaseCard = require("cards.baseCard")

local Aphrodite = {}
Aphrodite.__index = Aphrodite
setmetatable(Aphrodite, { __index = BaseCard })

function Aphrodite:new()
    local card = BaseCard:new("Aphrodite", 2, 1, "Reduce power of enemies opposite by 2")
    setmetatable(card, Aphrodite)
    return card
end

function Aphrodite:onReveal(gameState)
    for _, loc in ipairs(gameState.locations) do
        if loc.id == self.location then
            local opponentSlots = self.owner == "player" and loc.aiSlots or loc.playerSlots
            for _, card in pairs(opponentSlots) do
                if card then
                    card.power = math.max(0, card.power - 2)
                end
            end
        end
    end
end

return Aphrodite
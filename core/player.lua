-- core/player.lua

Player = {}
Player.__index = Player

function Player:new(name, isAI)
    local obj = {
        name = name,
        isAI = isAI or false,
        deck = {},
        hand = {},
        staged = { {}, {}, {} },  
        discardPile = {},         
        mana = 1,
        points = 0
    }
    setmetatable(obj, Player)
    return obj
end

function Player:drawCard()
    if #self.deck > 0 and #self.hand < 7 then
        -- draw from the top (end) of the deck
        local card = table.remove(self.deck)
        card.owner = self.isAI and "ai" or "player"
        -- player sees drawn cards; AI draws face-down
        card.faceUp = not self.isAI
        table.insert(self.hand, card)
    end
end

function Player:playCard(card, locationIndex)
    -- (unused by drag/drop, but kept for completeness)
    if card.cost <= self.mana and #self.staged[locationIndex] < 4 then
        for i, c in ipairs(self.hand) do
            if c == card then
                table.remove(self.hand, i)
                break
            end
        end
        table.insert(self.staged[locationIndex], card)
        self.mana = self.mana - card.cost
        return true
    end
    return false
end

function Player:startTurn(turn)
    self.turn = turn
    local baseMana = math.min(10, turn)
    self.mana = baseMana + (self.bonusMana or 0)
    self.bonusMana = 0
end

function Player:resetTurn()
    self.staged = { {}, {}, {} }
end

return Player

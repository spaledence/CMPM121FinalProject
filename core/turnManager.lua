-- core/turnManager.lua

local TurnManager = {}
local Input = require("systems.input")

TurnManager.phase = "play"
TurnManager.turn = 1
TurnManager.player = nil
TurnManager.ai = nil
TurnManager.aiPlayDelay = 0.25
TurnManager.aiPlayElapsed = 0
TurnManager.currentFirst = "player"
TurnManager.aiHasPlayedThisTurn = false

function TurnManager:init(player, ai)
    self.phase = "play"
    self.turn = 1
    self.player = player
    self.ai = ai

    self.player:startTurn(self.turn)
    self.ai:startTurn(self.turn)

    -- Initial draw for both
    for i = 1, 3 do
        self.player:drawCard()
        self.ai:drawCard()
    end
    self.ai:drawCard() --turn 1 draw
end

function TurnManager:update(dt)
    if self.phase == "play"
       and self.currentFirst == "ai"
       and not self.aiHasPlayedThisTurn then

        self.aiPlayElapsed = self.aiPlayElapsed + dt
        if self.aiPlayElapsed >= self.aiPlayDelay then
            self:aiPlayCard()
            self.aiHasPlayedThisTurn = true
        end
    end
end

function TurnManager:getPhase()
    return self.phase
end

function TurnManager:nextPhase()
    if self.phase == "play" then
        -- If player goes first, trigger AI play now (after player)
        if self.currentFirst == "player" and not self.aiHasPlayedThisTurn then
            self:aiPlayCard()
            self.aiHasPlayedThisTurn = true
            --return -- Don't proceed until AI has played
        end

        

        -- Proceed to reveal phase
        self.phase = "reveal"
        for _, loc in ipairs(GameState.locations) do
            for _, card in pairs(loc.playerSlots) do
                if card and not card.faceUp then card.faceUp = true end
            end
            for _, card in pairs(loc.aiSlots) do
                if card and not card.faceUp then card.faceUp = true end
            end
        end

    elseif self.phase == "reveal" then
        self.phase = "score"
        for _, loc in ipairs(GameState.locations) do
            for _, card in pairs(loc.playerSlots) do
                if card.onReveal then card:onReveal(GameState) end
            end
            for _, card in pairs(loc.aiSlots) do
                if card.onReveal then card:onReveal(GameState) end
            end
        end

        -- Score resolution
        for _, loc in ipairs(GameState.locations) do
            local p = loc:getPower("player")
            local a = loc:getPower("ai")
            if p > a then
                GameState.playerScore = GameState.playerScore + (p - a)
            elseif a > p then
                GameState.aiScore = GameState.aiScore + (a - p)
            end
        end

        -- Win condition
        if GameState.playerScore >= 20 then
            GameState.current = "win"
            return
        elseif GameState.aiScore >= 20 then
            GameState.current = "lose"
            return
        end

    elseif self.phase == "score" then
        self.phase = "reset"

    elseif self.phase == "reset" then
        self.turn = self.turn + 1
        self.phase = "play"
    
        -- Move all board cards to discard piles
        for _, loc in ipairs(GameState.locations) do
            for _, card in pairs(loc.playerSlots) do
                if card then table.insert(self.player.discardPile, card) end
            end
            for _, card in pairs(loc.aiSlots) do
                if card then table.insert(self.ai.discardPile, card) end
            end
            loc:clearCards()
        end
    
        -- Determine next turn order
        if GameState.playerScore > GameState.aiScore then
            self.currentFirst = "player"
        elseif GameState.aiScore > GameState.playerScore then
            self.currentFirst = "ai"
        else
            self.currentFirst = (math.random() < 0.5) and "player" or "ai"
        end
    
        self.aiHasPlayedThisTurn = false
        self.aiPlayElapsed = 0
    
        self.player:startTurn(self.turn)
        self.ai:startTurn(self.turn)
        self.ai:drawCard()
        Input.resetTurn()
    end
end

function TurnManager:aiPlayCard()
    while true do
        local affordable = {}
        for idx, card in ipairs(self.ai.hand) do
            if card.cost <= self.ai.mana then
                table.insert(affordable, { card = card, index = idx })
            end
        end
        if #affordable == 0 then break end

        local choice = affordable[math.random(#affordable)]
        local aiCard = choice.card
        local aiIndex = choice.index
        local placed = false

        for _ = 1, 10 do
            local loc = GameState.locations[math.random(#GameState.locations)]
            local slot = math.random(1, loc.maxSlots)
            if not loc.aiSlots[slot] then
                aiCard.faceUp = false
                aiCard.owner = "ai"
                aiCard.location = loc.id
                loc:addCard(aiCard, "ai", slot)
                table.remove(self.ai.hand, aiIndex)
                self.ai.mana = self.ai.mana - aiCard.cost
                placed = true
                break
            end
        end

        if not placed then break end
    end
end

return TurnManager
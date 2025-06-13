-- core/gameState.lua

local BaseCard = require("cards.baseCard")
local CardLibrary = require("cards.cardLibrary")
local Player = require("core.player")
local Location = require("core/location")
local Input = require("systems.input")
local TurnManager = require("core.turnManager")

GameState = {}

GameState.current = "menu"

function GameState:load()
    self.deckDrawPosition = { x = 850, y = 600 }
    self.aiDeckDrawPosition = { x = 80, y = 60 }
    -- Discard pile positions
    self.playerDiscardPosition = { x = self.deckDrawPosition.x - 80, y = self.deckDrawPosition.y }
    self.aiDiscardPosition     = { x = self.aiDeckDrawPosition.x + 80,    y = self.aiDeckDrawPosition.y }
    self.playerScore = 0
    self.aiScore = 0
    GameState.deckBuilderDeckSlots = {}
    GameState.playerSelectedDeck = {}
    self.states = {
        menu = {
            draw = function()
                love.graphics.setBackgroundColor(0.2, 0, 0.3)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("3CG: Greek Card Clash", 0, 200, 960, "center")
                love.graphics.printf("Click to Start", 0, 250, 960, "center")
            end,
            mousepressed = function(x, y, button)
                GameState.playerDeck = {}
                GameState.current = "deckbuilder"
            end
        },

        playing = {
            draw = function()
                love.graphics.setBackgroundColor(0.2, 0, 0.3)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("[Gameplay in Progress]", 0, 10, 960, "center")
                love.graphics.printf("Phase: " .. GameState.turnManager:getPhase(), 0, 40, 960, "center")
                love.graphics.printf("Turn Priority: " .. GameState.turnManager.currentFirst, 0, 475, 960, "center")
                love.graphics.printf("Score: Player " .. GameState.playerScore .. " | AI " .. GameState.aiScore, 0, 450, 960, "center")
                -- Show Player Mana
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("Player Mana: " .. tostring(GameState.player.mana or 0), 20, 700, 300, "left")
                love.graphics.printf("Player Discard: " .. tostring(#GameState.player.discardPile), 20, 730, 300, "left")  -- new


                -- Show AI Mana
                love.graphics.printf("AI Mana: " .. tostring(GameState.ai.mana or 0), 20, 20, 300, "left")
                love.graphics.printf("AI Discard: " .. tostring(#GameState.ai.discardPile), 20, 50, 300, "left")          -- new
                Input.drawHandSlotOutlines(GameState.handSlotRects)
                

                for _, loc in ipairs(GameState.locations or {}) do
                    loc:draw()
                end

                -- Draw hand slots and cards
                for i, card in ipairs(GameState.player.hand or {}) do
                    local slot = GameState.handSlotRects[i]
                    if slot then
                        card:setPosition(slot.x, slot.y)
                    end
                    card:draw()
                end

                -- Draw deck top card
                if #GameState.player.deck > 0 then
                    local topCard = GameState.player.deck[#GameState.player.deck]
                    topCard:setPosition(GameState.deckDrawPosition.x, GameState.deckDrawPosition.y)
                    topCard:draw()
                end
                
                if #GameState.player.discardPile > 0 then
                    local card = GameState.player.discardPile[#GameState.player.discardPile]
                    card.faceUp = true
                    card:setPosition(GameState.playerDiscardPosition.x,
                                     GameState.playerDiscardPosition.y)
                    card:draw()
                end
                


                --ai locations
                for i, slot in ipairs(GameState.aiHandSlotRects) do
                    love.graphics.setColor(1, 1, 1, 0.1)
                    love.graphics.rectangle("line", slot.x, slot.y, 60, 90, 6, 6)
                
                    local card = GameState.ai.hand[i]
                    if card then
                        card:setPosition(slot.x, slot.y)
                        card:draw()
                    end
                end

                -- Draw top of AI deck
                if #GameState.ai.deck > 0 then
                    local topCard = GameState.ai.deck[#GameState.ai.deck]
                    topCard:setPosition(GameState.aiDeckDrawPosition.x, GameState.aiDeckDrawPosition.y)
                    topCard:draw()
                end

                -- Draw AI discard pile
                if #GameState.ai.discardPile > 0 then
                    local card = GameState.ai.discardPile[#GameState.ai.discardPile]
                    card.faceUp = true
                    card:setPosition(GameState.aiDiscardPosition.x, GameState.aiDiscardPosition.y)
                    card:draw()
                end

                if Input.getHeldCard then
                    local draggingCard = Input.getHeldCard()
                    if draggingCard then
                        draggingCard:draw()
                    end
                end

                if Input.drawTooltip then
                    Input.drawTooltip()
                end
            end,

            mousepressed = function(x, y, button)
                if GameState.turnManager:getPhase() == "play" then
                    Input.mousepressed(x, y, button, GameState.player, GameState.handSlotRects)
                end
            end,

            keypressed = function(key)
                if key == "space" then
                    GameState.turnManager:nextPhase()
                end
            end
        },

        win = {
            draw = function()
                love.graphics.setBackgroundColor(0.2, 0.3, 0.2)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("You Win!", 0, 200, 960, "center")
                love.graphics.printf("Click to return to menu", 0, 250, 960, "center")
            end,
            mousepressed = function()
                GameState:resetToMenu()
            end
        },
        
        lose = {
            draw = function()
                love.graphics.setBackgroundColor(0.3, 0.1, 0.1)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("You Lose!", 0, 200, 960, "center")
                love.graphics.printf("Click to return to menu", 0, 250, 960, "center")
            end,
            mousepressed = function()
                GameState:resetToMenu()
            end
        },

        deckbuilder = {
            draw = function()
                love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("Deck Builder", 0, 20, 960, "center")
                love.graphics.printf("Click a card to add it to your deck (Max 2 each)", 0, 50, 960, "center")

                --Deck builder deck slots
                local slotWidth, slotHeight = 60, 90
                local cols = 10
                local rows = 2
                local spacingX, spacingY = 10, 10
                local totalWidth = cols * slotWidth + (cols - 1) * spacingX
                local startX = (love.graphics.getWidth() - totalWidth) / 2
                local startY = 500  -- Adjust as needed

                for row = 0, rows - 1 do
                    for col = 0, cols - 1 do
                        local x = startX + col * (slotWidth + spacingX)
                        local y = startY + row * (slotHeight + spacingY)
                        table.insert(self.deckBuilderDeckSlots, { x = x, y = y })
                    end
                end


                --Draw reg deck slots
                for i, slot in ipairs(GameState.deckBuilderDeckSlots) do
                    love.graphics.setColor(1, 1, 1, 0.2)
                    love.graphics.rectangle("line", slot.x, slot.y, 60, 90, 6, 6)

                    local card = GameState.playerSelectedDeck[i]
                    if card then
                        card:setPosition(slot.x, slot.y)
                        card:draw()
                    end
                end
        
                GameState.previewCards = {}
                --draw available cards
                local spacing = 70
                for i, name in ipairs(CardLibrary.getAllCardNames()) do
                    local x = 50 + ((i - 1) % 8) * spacing
                    local y = 100 + math.floor((i - 1) / 8) * 120
                    local card = CardLibrary.getCardByName(name)
                    card:setPosition(x, y)
                    card.faceUp = true

                    --Check how many copies already in deck
                    local count = 0
                    for _, c in ipairs(GameState.playerDeck) do
                        if c.name == name then count = count + 1 end
                    end

                    --If maxed out, draw card grayed out
                    if count >= 2 then
                        love.graphics.setColor(0.5, 0.5, 0.5, 1)  -- gray tint
                    else
                        love.graphics.setColor(1, 1, 1, 1)        -- normal
                    end

                    table.insert(GameState.previewCards, card)
                    card:draw()
                end

                if Input.getHeldCard then
                    local draggingCard = Input.getHeldCard()
                    if draggingCard then
                        draggingCard:draw()
                    end
                end
                
                
                if Input.hoveredCard and Input.hoveredCard.faceUp then
                    Input.drawTooltip()
                end
        
                love.graphics.printf("Deck Size: " .. tostring(#GameState.playerDeck), 0, 475, 960, "center")

                if #GameState.playerDeck >= 20 then
                    love.graphics.setColor(1, 1, 0) -- yellow
                    love.graphics.printf("SPACE to Play", 0, 475, 960, "center")
                    love.graphics.setColor(1, 1, 1)
                else
                    love.graphics.printf("Build a deck of 20 cards to continue", 0, 450, 960, "center")
                end
            end,
        
            mousepressed = function(x, y, button)
                if button == 1 then
                    -- Remove a card from the deck if a deck slot is clicked
                    for i, slot in ipairs(GameState.deckBuilderDeckSlots) do
                        local card = GameState.playerSelectedDeck[i]
                        if card and x >= slot.x and x <= slot.x + 60 and y >= slot.y and y <= slot.y + 90 then
                            GameState.playerSelectedDeck[i] = nil
                            for j = #GameState.playerDeck, 1, -1 do
                                if GameState.playerDeck[j] == card then
                                    table.remove(GameState.playerDeck, j)
                                    break
                                end
                            end
                            return
                        end
                    end
            
                    -- Start dragging a card from preview
                    Input.mousepressed(x, y, button, GameState.player, GameState.handSlotRects)
                end
            end,
        
            keypressed = function(key)
                if key == "space" and #GameState.playerDeck >= 20 then
                    GameState.aiDeck = CardLibrary.buildRandomDeck()
                    GameState.current = "playing"
                    GameState:loadFromDecks(GameState.playerDeck, GameState.aiDeck)
                end
            end
        }
    }

    -- Create player w/ card library
    self.player = Player:new("TestPlayer", false)

    -- ai card 
    self.ai = Player:new("Bot", true)

    self.turnManager = TurnManager
    self.turnManager:init(self.player, self.ai)

    self.aiHandSlotRects = {}
    local startX = 300
    local spacing = 80
    for i = 1, 7 do
        table.insert(self.aiHandSlotRects, { x = startX + (i - 1) * spacing, y = 60 })
    end

    -- create hand slot rects
    self.handSlotRects = {}
    local startX = 100
    local spacing = 80
    for i = 1, 7 do
        table.insert(self.handSlotRects, {x = startX + (i - 1) * spacing, y = 600})
    end

    -- create locations
    self.locations = {}
    local locWidth, spacing = 300, 60
    local totalWidth = (3 * locWidth) + (2 * spacing)
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local y = 200

    for i = 1, 3 do
        local x = startX + (i - 1) * (locWidth + spacing)
        local loc = Location:new(i, x, y)
        table.insert(self.locations, loc)
    end

    
end

function GameState:update(dt)
    function GameState:update(dt)
        if GameState.current == "playing" or GameState.current == "deckbuilder" then
            if GameState.turnManager then
                self.turnManager:update(dt)
            end
            Input.update(dt)
        end
    end
end

function GameState:draw()
    self.states[GameState.current].draw()
end

function GameState:mousepressed(x, y, button)
    if self.states[GameState.current].mousepressed then
        self.states[GameState.current].mousepressed(x, y, button)
    end
end

function GameState:mousereleased(x, y, button)
    if Input.mousereleased then
        if GameState.current == "playing" then
            Input.mousereleased(x, y, button, self.player, self.locations, self.handSlotRects)
        elseif GameState.current == "deckbuilder" then
            -- deckbuilder only uses x/y/button
            Input.mousereleased(x, y, button)
        end
    end
end

function GameState:keypressed(key)
    local state = GameState.states[GameState.current]
    if state and state.keypressed then
        state.keypressed(key)
    end
end

function GameState:loadFromDecks(playerDeck, aiDeck)
    -- Set all player deck cards face-down
    GameState.deckBuilderDeckSlots = {}
    GameState.playerSelectedDeck = {}
    GameState.previewCards = {}


    for _, card in ipairs(playerDeck) do
        card.faceUp = false
    end

    self.player = Player:new("You", false)
    for i = #playerDeck, 2, -1 do
        local j = math.random(i)
        playerDeck[i], playerDeck[j] = playerDeck[j], playerDeck[i]
    end
    self.player.deck = playerDeck

    self.ai = Player:new("AI", true)
    for i = #aiDeck, 2, -1 do
        local j = math.random(i)
        aiDeck[i], aiDeck[j] = aiDeck[j], aiDeck[i]
    end
    self.ai.deck = aiDeck

    self.turnManager:init(self.player, self.ai)
end

function GameState:resetToMenu()
    GameState.current = "menu"

    self.player.hand = {}
    self.player.discardPile = {}
    self.ai.hand = {}
    self.ai.discardPile = {}

    -- Clear all deck-related state
    GameState.playerDeck = {}
    GameState.aiDeck = {}

    self.turnManager.turn = 1
    self.turnManager.phase = "play"
    self.turnManager.aiHasPlayedThisTurn = false
    self.turnManager.aiPlayElapsed = 0

    GameState.playerScore = 0
    GameState.aiScore = 0
end
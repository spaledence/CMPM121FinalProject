-- systems/input.lua

local CardLibrary = require("cards.cardLibrary")
Input = {}


local heldCard = nil
local offsetX, offsetY = 0, 0
local heldCardOriginalSlotIndex = nil
Input.hasDrawnThisTurn = false
Input.hoveredCard = nil

function Input.mousepressed(x, y, button, player, handSlotRects)
    if button == 1 then
        if GameState.current == "deckbuilder" then
            for _, card in ipairs(GameState.previewCards or {}) do
                if x > card.x and x < card.x + 60 and y > card.y and y < card.y + 90 then
                    -- Count existing cards
                    local count = 0
                    for _, c in ipairs(GameState.playerDeck) do
                        if c.name == card.name then count = count + 1 end
                    end
        
                    if count >= 2 then
                        return  -- prevent drag
                    end
        
                    heldCard = CardLibrary.getCardByName(card.name)
                    offsetX = 30
                    offsetY = 45
                    heldCard:setPosition(x - offsetX, y - offsetY)
                    heldCard.faceUp = true
                    return
                end
            end
        end

        -- Check if drawing from deck (only if allowed)
        if not Input.hasDrawnThisTurn and #player.deck > 0 then
            local topCard = player.deck[#player.deck]
            local dx, dy = GameState.deckDrawPosition.x, GameState.deckDrawPosition.y
            if x > dx and x < dx + 60 and y > dy and y < dy + 90 then
                heldCard = table.remove(player.deck)
                offsetX = x - dx
                offsetY = y - dy
                heldCardOriginalSlotIndex = nil
                heldCard:setPosition(dx, dy)
                return
            end
        end

        -- Check hand cards
        for i, card in ipairs(player.hand) do
            if x > card.x and x < card.x + 60 and y > card.y and y < card.y + 90 then
                heldCard = card
                offsetX = x - card.x
                offsetY = y - card.y
                heldCardOriginalSlotIndex = i
                table.remove(player.hand, i)
                break
            end
        end
    end
end

function Input.mousereleased(x, y, button, player, locations, handSlotRects)
    if button == 1 and heldCard then
        if GameState.current == "deckbuilder" and heldCard then
            -- Try dropping into deck slot
            for i, slot in ipairs(GameState.deckBuilderDeckSlots or {}) do
                if not GameState.playerSelectedDeck[i] and
                   x >= slot.x and x <= slot.x + 60 and y >= slot.y and y <= slot.y + 90 then
                    -- Check if we've already added 2 of this card
                    local count = 0
                    for _, c in ipairs(GameState.playerSelectedDeck) do
                        if c and c.name == heldCard.name then count = count + 1 end
                    end
                    if count < 2 then
                        heldCard.faceUp = true -- ✅ force face up
                        GameState.playerSelectedDeck[i] = heldCard
                        table.insert(GameState.playerDeck, heldCard)
                        heldCard = nil
                        return
                    end
                end
            end
        
            -- Didn't place: discard drag
            heldCard = nil
            return
        end

        if heldCardOriginalSlotIndex == nil then
            for i, rect in ipairs(handSlotRects) do
                if x >= rect.x and x <= rect.x + 60 and y >= rect.y and y <= rect.y + 90 and not player.hand[i] then
                    heldCard.owner = "player"
                    heldCard.faceUp = true
                    table.insert(player.hand, i, heldCard)
                    heldCard:setPosition(rect.x, rect.y)
                    heldCard = nil
                    Input.hasDrawnThisTurn = true
                    return
                end
            end
            table.insert(player.deck, heldCard)
            heldCard:setPosition(GameState.deckDrawPosition.x, GameState.deckDrawPosition.y)
            heldCard = nil
            return
        end

        for _, loc in ipairs(locations) do
            local slotIndex = loc:isMouseOverSlot(x, y)
            if slotIndex and heldCard.cost <= player.mana then
                player.mana = player.mana - heldCard.cost
                heldCard.faceUp = false
                heldCard.location = loc.id
                heldCard.owner = "player"
                local success = loc:addCard(heldCard, "player", slotIndex)
                if success then
                    heldCard = nil
                    heldCardOriginalSlotIndex = nil
                    return
                end
            end
        end

        if heldCardOriginalSlotIndex and handSlotRects[heldCardOriginalSlotIndex] then
            table.insert(player.hand, heldCardOriginalSlotIndex, heldCard)
            local slot = handSlotRects[heldCardOriginalSlotIndex]
            heldCard:setPosition(slot.x, slot.y)
        else
            table.insert(player.deck, heldCard)
            heldCard:setPosition(GameState.deckDrawPosition.x, GameState.deckDrawPosition.y)
        end
        heldCard = nil
        heldCardOriginalSlotIndex = nil
    end
end

function Input.update(dt)
    if heldCard then
        local mx, my = love.mouse.getPosition()
        heldCard:setPosition(mx - offsetX, my - offsetY)
    end

    Input.hoveredCard = nil
    local mx, my = love.mouse.getPosition()

    for _, card in ipairs(GameState.player.hand) do
        if mx > card.x and mx < card.x + 60 and my > card.y and my < card.y + 90 then
            Input.hoveredCard = card
            return
        end
    end

    for _, loc in ipairs(GameState.locations or {}) do
        for _, card in pairs(loc.playerSlots) do
            if card and card.faceUp and mx > card.x and mx < card.x + 60 and my > card.y and my < card.y + 90 then
                Input.hoveredCard = card
                return
            end
        end
        for _, card in pairs(loc.aiSlots) do
            if card and card.faceUp and mx > card.x and mx < card.x + 60 and my > card.y and my < card.y + 90 then
                Input.hoveredCard = card
                return
            end
        end
    end

    if GameState.current == "deckbuilder" and GameState.previewCards then
        for _, card in ipairs(GameState.previewCards) do
            if card.faceUp then
                if mx > card.x and mx < card.x + 60 and my > card.y and my < card.y + 90 then
                    Input.hoveredCard = card
                    return
                end
            end
        end
    end
end

function Input.resetTurn()
    Input.hasDrawnThisTurn = false
end

function Input.drawHandSlotOutlines(handSlotRects)
    love.graphics.setColor(1, 1, 1, 0.1)
    for _, slot in ipairs(handSlotRects) do
        love.graphics.rectangle("line", slot.x, slot.y, 60, 90, 6, 6)
    end
end

function Input.drawTooltip()
    local card = Input.hoveredCard
    if not card then return end

    local mx, my = love.mouse.getPosition()
    local padding = 12
    local lineHeight = 18
    local lines = {
        card.name or "???",
        "Cost: " .. tostring(card.cost or 0) .. "   Power: " .. tostring(card.power or 0),
        card.text or ""
    }

    local maxWidth = 0
    for _, line in ipairs(lines) do
        local w = love.graphics.getFont():getWidth(line)
        if w > maxWidth then maxWidth = w end
    end

    local boxWidth = maxWidth + padding * 2
    local boxHeight = #lines * lineHeight + padding * 2

    local xPos = mx + 10
    if xPos + boxWidth > love.graphics.getWidth() then
        xPos = mx - boxWidth - 10
    end

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", xPos, my + 10, boxWidth, boxHeight, 6, 6)

    love.graphics.setColor(1, 1, 1)
    for i, line in ipairs(lines) do
        love.graphics.print(line, xPos + padding, my + 10 + padding + (i - 1) * lineHeight)
    end
end

function Input.getHeldCard()
    return heldCard
end

return Input
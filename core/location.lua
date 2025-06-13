-- core/location.lua

Location = {}
Location.__index = Location

function Location:new(id, x, y)
    local loc = {
        id = id,
        x = x,
        y = y,
        width = 300,
        height = 225,
        maxSlots = 4,
        playerSlots = {},
        aiSlots = {},
        playerSlotRects = {},
        aiSlotRects = {},
        slotW = 60,
        slotH = 90,
        slotSpacing = 60
    }

    setmetatable(loc, self)

    -- Calculate horizontal offset to center the rows
    local rowWidth = (loc.maxSlots * loc.slotSpacing) - (loc.slotSpacing - loc.slotW)
    local offsetX = (loc.width - rowWidth) / 2

    -- Create player and AI slot rects
    for i = 1, loc.maxSlots do
        local cx = x + offsetX + (i - 1) * loc.slotSpacing
        -- AI row (top)
        local aiY = y + 20
        table.insert(loc.aiSlotRects, { x = cx, y = aiY, w = loc.slotW, h = loc.slotH })
        -- Player row (bottom)
        local playerY = y + loc.height - loc.slotH - 20
        table.insert(loc.playerSlotRects, { x = cx, y = playerY, w = loc.slotW, h = loc.slotH })
    end

    return loc
end

function Location:isMouseOverSlot(x, y)
    for i, rect in ipairs(self.playerSlotRects) do
        if x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h then
            return i
        end
    end
    return nil
end

function Location:addCard(card, owner, slotIndex)
    local targetSlots = (owner == "player") and self.playerSlots or self.aiSlots
    if not targetSlots[slotIndex] then
        targetSlots[slotIndex] = card
        return true
    end
    return false
end

function Location:getPower(owner)
    local total = 0
    local slots = (owner == "player") and self.playerSlots or self.aiSlots
    for _, card in pairs(slots) do
        total = total + (card.power or 0)
    end
    return total
end

function Location:clearCards()
    self.playerSlots = {}
    self.aiSlots = {}
end

function Location:draw()
    -- Board outline
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- Draw slot outlines first
    love.graphics.setColor(1, 1, 1, 0.1)
    for i = 1, self.maxSlots do
        local p = self.playerSlotRects[i]
        local a = self.aiSlotRects[i]
        love.graphics.rectangle("line", p.x, p.y, p.w, p.h, 6, 6)
        love.graphics.rectangle("line", a.x, a.y, a.w, a.h, 6, 6)
    end

    -- Draw AI cards (face-down or placeholder)
    for i = 1, self.maxSlots do
        local rect = self.aiSlotRects[i]
        local card = self.aiSlots[i]
        if card then
            card:setPosition(rect.x, rect.y)
            card:draw()
        end
    end

    -- Draw Player cards
    for i = 1, self.maxSlots do
        local rect = self.playerSlotRects[i]
        local card = self.playerSlots[i]
        if card then
            card:setPosition(rect.x, rect.y)
            card:draw()
        end
    end
end

return Location
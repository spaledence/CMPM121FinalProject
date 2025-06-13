-- cards/baseCard.lua

local BaseCard = {}
BaseCard.__index = BaseCard

function BaseCard:new(name, cost, power, text)
    local card = {
        name = name,
        cost = cost,
        power = power,
        text = text or "",
        owner = nil,
        location = nil,
        faceUp = false,
        resolved = false,
        x = 0,
        y = 0
    }
    setmetatable(card, BaseCard)
    return card
end

function BaseCard:setPosition(x, y)
    self.x = x
    self.y = y
end

function BaseCard:draw()
    local inPlayerHand = self.owner == "player" and not self.location
    local showFace = self.faceUp or inPlayerHand

    if showFace then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", self.x, self.y, 60, 90, 6, 6)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", self.x, self.y, 60, 90, 6, 6)

        love.graphics.setColor(0, 0, 0)

        local maxWidth = 56
        local nameWidth = love.graphics.getFont():getWidth(self.name or "")
        if nameWidth > maxWidth then
            love.graphics.push()
            love.graphics.translate(self.x, self.y)  -- shift origin
            love.graphics.scale(0.8, 0.8)  -- scale down
            love.graphics.printf(self.name, 2 / 0.8, 4 / 0.8, maxWidth / 0.8, "center")
            love.graphics.pop()
        else
            love.graphics.printf(self.name, self.x + 2, self.y + 4, maxWidth, "center")
        end
        love.graphics.printf("Cost: " .. self.cost, self.x + 5, self.y + 25, 70, "left")
        love.graphics.printf("Power: " .. self.power, self.x + 5, self.y + 40, 70, "left")
        local label = self.text:lower():find("vanilla") and "Vanilla" or "Effect"
        love.graphics.printf(label, self.x + 5, self.y + 60, 50, "left")
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, 60, 90, 6, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", self.x, self.y, 60, 90, 6, 6)
        love.graphics.printf("???", self.x, self.y + 35, 80, "center")
    end
end

return BaseCard
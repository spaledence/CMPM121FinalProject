-- cards/cardLibrary.lua

local CardLibrary = {}
local BaseCard    = require("cards.baseCard")
local Zeus = require("cards.zeus")
local Ares = require("cards.ares")
local Medusa = require("cards.medusa")
local Demeter = require("cards.demeter")
local Hades = require("cards.hades")
local Aphrodite = require("cards.aphrodite")
local Midas = require("cards.midas")
local Hera = require("cards.hera")
local Apollo = require("cards.apollo")
local Hermes = require("cards.hermes")

-- “vanilla” cards (no custom behavior)
CardLibrary.cards = {
    { name = "Wooden Cow", cost = 1, power = 1, text = "Vanilla" },
    { name = "Pegasus",     cost = 3, power = 5, text = "Vanilla" },
    { name = "Minotaur",    cost = 5, power = 9, text = "Vanilla" },
    { name = "Titan",       cost = 6, power = 12, text = "Vanilla" },
}

function CardLibrary.getCardByName(name)
    if name == "Zeus" then return Zeus:new() end
    if name == "Ares" then return Ares:new() end
    if name == "Medusa" then return Medusa:new() end
    if name == "Demeter" then return Demeter:new() end
    if name == "Hades" then return Hades:new() end
    if name == "Aphrodite" then return Aphrodite:new() end
    if name == "Midas" then return Midas:new() end
    if name == "Hera" then return Hera:new() end
    if name == "Apollo" then return Apollo:new() end
    if name == "Hermes" then return Hermes:new() end

    for _, data in ipairs(CardLibrary.cards) do
        if data.name == name then
            return BaseCard:new(data.name, data.cost, data.power, data.text)
        end
    end

    return nil
end



function CardLibrary.getAllCardNames()
    local names = {}
    for _, data in ipairs(CardLibrary.cards) do
        table.insert(names, data.name)
    end
    for _, name in ipairs({ "Zeus", "Ares", "Medusa", "Demeter", "Hades", "Aphrodite", "Midas", "Hera", "Apollo", "Hermes", "Wooden Cow", "Pegasus", "Minotaur", "Titan" }) do
        table.insert(names, name)
    end
    return names
end

function CardLibrary.buildRandomDeck()
    local deck = {}
    local names = CardLibrary.getAllCardNames()

    -- Shuffle names
    for i = #names, 2, -1 do
        local j = math.random(i)
        names[i], names[j] = names[j], names[i]
    end

    local i = 1
    while #deck < 20 do
        local name = names[(i - 1) % #names + 1]
        local count = 0
        for _, card in ipairs(deck) do
            if card.name == name then count = count + 1 end
        end
        if count < 2 then
            local card = CardLibrary.getCardByName(name)
            if card then
                table.insert(deck, card)
            end
        end
        i = i + 1
    end

    return deck
end

return CardLibrary
-- main.lua

require "core.gameState"

function love.load()
    GameState:load()
end

function love.update(dt)
    GameState:update(dt)
end

function love.draw()
    if GameState.states[GameState.current] and GameState.states[GameState.current].draw then
        GameState.states[GameState.current].draw()
    end
end

function love.mousepressed(x, y, button)
    if GameState.states[GameState.current] and GameState.states[GameState.current].mousepressed then
        GameState.states[GameState.current].mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    GameState:mousereleased(x, y, button)
end

function love.keypressed(key)
    GameState:keypressed(key)
end
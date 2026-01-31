local World = require("src.world")

-- Camera
local camera = {x = 0, y = 0, scale = 1.5}

function camera:follow(x, y)
    local w, h = love.graphics.getDimensions()
    self.x, self.y = x - w/(2*self.scale), y - h/(2*self.scale)
end

function camera:attach()
    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function camera:detach()
    love.graphics.pop()
end

function camera:toWorld(x, y)
    return x/self.scale + self.x, y/self.scale + self.y
end

-- Game loop
function love.load()
    love.graphics.setBackgroundColor(31/255, 46/255, 24/255)
    World:load()
end

function love.update(dt)
    World:update(dt, camera)
end

function love.draw()
    camera:follow(World.player.x, World.player.y)
    camera:attach()
    World:draw()
    camera:detach()

    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Enemies: " .. World.enemyCount .. "/10", 10, 10)
end
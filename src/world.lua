local Player = require("src.player")
local Enemy = require("src.enemy")

local World = {
    player = nil,
    enemies = {},
    boxes = {},
    enemyCount = 10,
    boxesCount = 10,
    gameOver = false,
    restartTimer = 0
}

-- Simple box with collision
local function createBox(x, y, w, h, isWall)
    return {
        x = x, y = y, width = w, height = h, isWall = isWall,
        sprite = not isWall and love.graphics.newImage("textures/box.png") or nil,

        resolveCollision = function(self, entity)
            local ex = entity.x - entity.width/2
            local ey = entity.y - entity.height/2
            if not (ex < self.x + self.width and ex + entity.width > self.x and
                    ey < self.y + self.height and ey + entity.height > self.y) then
                return false
            end

            local oLeft = (ex + entity.width) - self.x
            local oRight = (self.x + self.width) - ex
            local oTop = (ey + entity.height) - self.y
            local oBot = (self.y + self.height) - ey
            local minO = math.min(oLeft, oRight, oTop, oBot)

            if minO == oLeft then entity.x = entity.x - oLeft
            elseif minO == oRight then entity.x = entity.x + oRight
            elseif minO == oTop then entity.y = entity.y - oTop
            else entity.y = entity.y + oBot end
            return true
        end,

        draw = function(self)
            if self.isWall then
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.draw(self.sprite, self.x, self.y, 0, self.width/self.sprite:getWidth(), self.height/self.sprite:getHeight())
            end
        end
    }
end

function World:load()
    local w, h = love.graphics.getDimensions()

    self.player = Player:new(w/2, h/2)
    self.enemies = {}
    self.boxes = {}

    -- Spawn enemies
    for i = 1, self.enemyCount do
        table.insert(self.enemies, Enemy:new(math.random(w/10, w*9/10), math.random(h/10, h*9/10)))
    end

    -- Spawn boxes
    for i = 1, self.boxesCount do
        table.insert(self.boxes, createBox(math.random(100, w-100), math.random(100, h-100), 64, 64, false))
    end

    -- Border walls
    table.insert(self.boxes, createBox(-50, -50, w+100, 50, true))
    table.insert(self.boxes, createBox(-50, h, w+100, 50, true))
    table.insert(self.boxes, createBox(-50, 0, 50, h, true))
    table.insert(self.boxes, createBox(w, 0, 50, h, true))
end

function World:update(dt, camera)
    if self.gameOver then
        self.restartTimer = self.restartTimer + dt
        if self.restartTimer >= 3 then
            self:load() -- Restart the game
            self.gameOver = false
            self.restartTimer = 0
        end
        return
    end

    local playerHit = self.player:update(dt, self.enemies, self.boxes, camera)
    if playerHit then
        self.gameOver = true
        print("You lose, try again")
        return
    end

    for i = #self.enemies, 1, -1 do
        self.enemies[i]:update(dt, self.player, self.boxes, self.enemies)
        if self.enemies[i].dead then
            table.remove(self.enemies, i)
            self.enemyCount = self.enemyCount - 1
            if self.enemyCount <= 0 then love.event.quit() end
        end
    end
end

function World:draw()
    for _, box in ipairs(self.boxes) do box:draw() end
    self.player:draw()
    for _, enemy in ipairs(self.enemies) do enemy:draw() end
end

return World
local Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y)
    return setmetatable({
        x = x, y = y, speed = 50, hp = 3, angle = 0,
        width = 32, height = 32, dead = false,
        sprite = love.graphics.newImage("textures/zombie.png"),
        hitFlash = 0
    }, Enemy)
end

function Enemy:update(dt, player, boxes, enemies)
    -- Update hit flash timer
    if self.hitFlash > 0 then
        self.hitFlash = self.hitFlash - dt
    end

    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)

    self.angle = math.atan2(dy, dx)

    if dist > 10 then
        dx, dy = dx/dist, dy/dist
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt

        -- Collide with boxes
        for _, box in ipairs(boxes) do box:resolveCollision(self) end

        -- Collide with other enemies
        for _, other in ipairs(enemies) do
            if other ~= self and not other.dead then
                local odx, ody = other.x - self.x, other.y - self.y
                local odist = math.sqrt(odx*odx + ody*ody)
                if odist < 32 and odist > 0 then
                    local push = (32 - odist) * 0.5
                    self.x = self.x - (odx/odist) * push
                    self.y = self.y - (ody/odist) * push
                end
            end
        end
    end
end

function Enemy:checkHit(px, py, angle, laserLength)
    local dx, dy = self.x - px, self.y - py
    local dist = math.sqrt(dx*dx + dy*dy)
    local enemyAngle = math.atan2(dy, dx)

    -- Normalize angle difference to -pi to pi range
    local angleDiff = enemyAngle - angle
    while angleDiff > math.pi do angleDiff = angleDiff - 2*math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2*math.pi end

    -- Increase tolerance slightly and use distance-based tolerance for far enemies
    local tolerance = 0.15 + (dist / laserLength) * 0.05

    return math.abs(angleDiff) < tolerance and dist < laserLength
end

function Enemy:takeDamage()
    self.hp = self.hp - 1
    self.hitFlash = 0.1
    if self.hp <= 0 then self.dead = true end
end

function Enemy:draw()
    if self.hitFlash > 0 then
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.draw(self.sprite, self.x, self.y, self.angle, 1, 1, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
    love.graphics.setColor(1, 1, 1)
end

return Enemy
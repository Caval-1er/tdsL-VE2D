local Player = {}
Player.__index = Player

function Player:new(x, y)
    return setmetatable({
        x = x, y = y, speed = 200, angle = 0, width = 32, height = 32,
        mouseWasPressed = false, laserOffSet = 20, laserLength = 1020,
        bodySprite = love.graphics.newImage("textures/topdown_character.png"),
        gunSprite = love.graphics.newImage("textures/gun.png")
    }, Player)
end

function Player:update(dt, enemies, boxes, camera)
    -- Aim
    local mx, my = love.mouse.getPosition()
    if camera then mx, my = camera:toWorld(mx, my) end
    self.angle = math.atan2(my - self.y, mx - self.x)

    -- Move
    local dx, dy = 0, 0
    if love.keyboard.isDown("q") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    if love.keyboard.isDown("z") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end

    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx, dy = dx/len, dy/len
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    end

    -- Collide with boxes
    for _, box in ipairs(boxes) do box:resolveCollision(self) end

    -- Check collision with enemies
    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < (self.width + enemy.width) / 3 then
                return true -- Collision detected
            end
        end
    end

    -- Shoot (click detection)
    local mousePressed = love.mouse.isDown(1)
    if mousePressed and not self.mouseWasPressed then
        local closestEnemy = nil
        local closestDist = math.huge

        -- Find all enemies in the line of fire
        for _, enemy in ipairs(enemies) do
            if enemy:checkHit(self.x, self.y, self.angle, self.laserLength) then
                local dx = enemy.x - self.x
                local dy = enemy.y - self.y
                local dist = math.sqrt(dx*dx + dy*dy)

                -- Check if any box blocks the shot
                local blocked = false
                for _, box in ipairs(boxes) do
                    if self:lineIntersectsBox(self.x, self.y, enemy.x, enemy.y, box) then
                        blocked = true
                        break
                    end
                end

                -- If not blocked and closer than current closest, update
                if not blocked and dist < closestDist then
                    closestEnemy = enemy
                    closestDist = dist
                end
            end
        end

        -- Damage the closest unobstructed enemy
        if closestEnemy then
            closestEnemy:takeDamage()
        end
    end
    self.mouseWasPressed = mousePressed
end

function Player:lineIntersectsBox(x1, y1, x2, y2, box)
    -- Check if line segment from (x1,y1) to (x2,y2) intersects with box
    -- Using line-rectangle intersection test

    -- Get box edges
    local left = box.x
    local right = box.x + box.width
    local top = box.y
    local bottom = box.y + box.height

    -- Check if either endpoint is inside the box
    if x1 >= left and x1 <= right and y1 >= top and y1 <= bottom then
        return true
    end
    if x2 >= left and x2 <= right and y2 >= top and y2 <= bottom then
        return true
    end

    -- Check intersection with each edge of the box
    local function lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
        local denom = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
        if math.abs(denom) < 0.0001 then return false end

        local t = ((x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)) / denom
        local u = -((x1-x2)*(y1-y3) - (y1-y2)*(x1-x3)) / denom

        return t >= 0 and t <= 1 and u >= 0 and u <= 1
    end

    -- Check all four edges of the box
    if lineIntersect(x1, y1, x2, y2, left, top, right, top) then return true end      -- top edge
    if lineIntersect(x1, y1, x2, y2, right, top, right, bottom) then return true end  -- right edge
    if lineIntersect(x1, y1, x2, y2, left, bottom, right, bottom) then return true end -- bottom edge
    if lineIntersect(x1, y1, x2, y2, left, top, left, bottom) then return true end    -- left edge

    return false
end

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    love.graphics.draw(self.bodySprite, 0, 0, 0, 1, 1, self.bodySprite:getWidth()/2, self.bodySprite:getHeight()/2)
    love.graphics.draw(self.gunSprite, 15, 0, 0, 1, 1, self.gunSprite:getWidth()/2, self.gunSprite:getHeight()/2)
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.line(self.laserOffSet, 0, self.laserLength, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

return Player
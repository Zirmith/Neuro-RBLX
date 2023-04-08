

local AI_Manager = {}


function AI_Manager.new()
    local self = setmetatable({}, {__index = AI_Manager})
    return self
end

function AI_Manager:initialize()
    self.Players = game:GetService("Players")
    self.AI = self.Players.LocalPlayer
    self.AI_Char = self.AI.Character or self.AI:WaitForChild("Character")
    self.Health, self.MaxHealth = self.AI_Char.Humanoid.Health, self.AI_Char.Humanoid.MaxHealth
    self.VirtualInput = game:GetService("VirtualUser")
    self.CoreGui = game:GetService("CoreGui")
    self.Marketplace = game:GetService("MarketplaceService")
    self.gameName = self.Marketplace:GetProductInfo(self.getCurrentGameName()).name
    
    -- add the following line to call the automatic movement function
    task.spawn(function()
        while true do
            local target = self:getNearestPlayer()
            if target then
                self:pathfindTo(target.Character.HumanoidRootPart.Position)
            else
                -- If no players nearby, move randomly
                local randomPos = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
                self:pathfindTo(randomPos)
            end
            task.wait(2)
        end
    end)
end


function AI_Manager:doActionBasedOnCondition(condition, actionFunction, ...)
    if condition then
        actionFunction(self, ...)
    end
end

function AI_Manager:getAICharacter()
    return self.AI_Char
end

function AI_Manager:pathfindTo(targetPosition)
    if not self.AI_Char then
        return -- AI character not found, can't pathfind
    end
    local path = game:GetService("PathfindingService"):CreatePath()
    local success, message = pcall(function()
        path:ComputeAsync(self.AI_Char.HumanoidRootPart.Position, targetPosition)
    end)
    if not success then
        warn("Failed to compute path:", message)
        return
    end
    local waypoints = path:GetWaypoints()
    local currentIndex = 1
    while currentIndex <= #waypoints do
        local waypoint = waypoints[currentIndex]
        self.AI_Char.Humanoid:MoveTo(waypoint.Position)
        self.VirtualInput:Button2Down(Vector2.new(0, 0), nil, nil)
        self.VirtualInput:Button2Up(Vector2.new(0, 0), nil, nil)
        self.AI_Char.Humanoid.MoveToFinished:Wait()
        self:addFakeLag(0.5)
        local nextWaypoint = waypoints[currentIndex + 1]
        if nextWaypoint then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {self.AI_Char}
            raycastParams.IgnoreWater = true
            local raycastResult = workspace:Raycast(waypoint.Position, nextWaypoint.Position - waypoint.Position, raycastParams)
            if raycastResult then
                -- Obstacle detected, recompute path
                path = game:GetService("PathfindingService"):CreatePath()
                path:ComputeAsync(self.AI_Char.HumanoidRootPart.Position, targetPosition)
                waypoints = path:GetWaypoints()
                currentIndex = 1
            else
                currentIndex = currentIndex + 1
            end
        else
            break
        end
    end
end


function AI_Manager:getNearestPlayer()
    local nearestDistance = math.huge
    local nearestPlayer = nil
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player ~= self.AI then
            local distance = (player.Character.HumanoidRootPart.Position - self.AI_Char.HumanoidRootPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end
    return nearestPlayer, nearestDistance
end

function AI_Manager:getCurrentGame()
    return game.GameId
end

function AI_Manager:isPlayerOnSameTeam(player)
    if not self.AI_Char or not player.Character then
        return false -- AI character or player character not found
    end
    local teamService = game:GetService("Teams")
    local aiTeam = teamService:GetPlayerTeam(self.AI)
    local playerTeam = teamService:GetPlayerTeam(player)
    if aiTeam and playerTeam and aiTeam == playerTeam then
        return true -- player is on the same team
    else
        return false -- player is not on the same team
    end
end

function AI_Manager:chat(message)
    if not self.AI_Char then
        return -- AI character not found, can't chat
    end
    local chatService = game:GetService("Chat")
    chatService:Chat(self.AI_Char.Head, message, Enum.ChatColor.White)
end

function AI_Manager:log(message)
    local chat = self.CoreGui:FindFirstChild("Chat")
    if chat then
        local chatFrame = chat:FindFirstChild("Frame")
        if chatFrame then
            local chatBar = chatFrame:FindFirstChild("ChatBarParent")
            if chatBar then
                local messageLabel = Instance.new("TextLabel")
                messageLabel.Text = message
                messageLabel.TextColor3 = Color3.new(1, 1, 1)
                messageLabel.TextSize = 18
                messageLabel.BackgroundTransparency = 1
                messageLabel.Size = UDim2.new(1, 0, 0, messageLabel.TextBounds.Y)
                messageLabel.Position = UDim2.new(0, 0, 1, 0)
                messageLabel.AnchorPoint = Vector2.new(0, 1)
                messageLabel.Parent = chatBar
                task.wait(5) -- display message for 5 seconds
                messageLabel:Destroy()
            end
        end
    end
end

function AI_Manager:getPlayerInfo(player)
    local playerChar = player.Character or player.CharacterAdded:Wait()
    local playerHealth = playerChar:WaitForChild("Humanoid").Health
    local playerMaxHealth = playerChar:WaitForChild("Humanoid").MaxHealth
    local playerDistance = (playerChar.HumanoidRootPart.Position - self.AI_Char.HumanoidRootPart.Position).Magnitude
    local playerName = player.Name
    return {
        health = playerHealth,
        maxHealth = playerMaxHealth,
        distance = playerDistance,
        name = playerName
    }
end

function AI_Manager:addFakeLag(time)
    local originalMoveTo = self.AI_Char.Humanoid.MoveTo
    local isMoving = false
    self.AI_Char.Humanoid.MoveTo = function(humanoid, position, ...)
        isMoving = true
        task.spawn(function()
            task.wait(time)
            isMoving = false
        end)
        return originalMoveTo(humanoid, position, ...)
    end
    while true do
        self.VirtualInput:Button2Down(Vector2.new(0, 0), nil, nil)
        self.VirtualInput:Button2Up(Vector2.new(0, 0), nil, nil)
        if not isMoving then
            task.wait(1)
        end
        task.wait()
    end
end


return AI_Manager

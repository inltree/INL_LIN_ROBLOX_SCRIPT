-- 服务声明
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 创建UI界面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- 获取游戏名称
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

-- 初始化UI通知
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = "inltree｜"..gameName.." Script Loading...｜加载中...",
    Duration = 3
})

task.wait(5)

-- 按钮样式配置
local buttonStyle = {
    Size = UDim2.new(0, 120, 0, 30),
    BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
    BackgroundTransparency = 0.5,
    Font = Enum.Font.SourceSansBold,
    TextSize = 16
}

-- 创建按钮函数
local function createButton(name, position, color, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = buttonStyle.Size
    button.Position = position
    button.Text = name
    button.TextColor3 = color
    button.BackgroundColor3 = buttonStyle.BackgroundColor3
    button.BackgroundTransparency = buttonStyle.BackgroundTransparency
    button.Font = buttonStyle.Font
    button.TextSize = buttonStyle.TextSize
    button.Parent = screenGui
    
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- ===================== 自动朗克斯功能 =====================
local lankersTeleportRunning = false
local lankersTeleportThread = nil

local function stopLankersTeleport()
    if lankersTeleportRunning then
        lankersTeleportRunning = false
        if lankersTeleportThread then
            coroutine.close(lankersTeleportThread)
            lankersTeleportThread = nil
        end
        print("⏹️ 自动朗克斯已停止")
    end
end

local function findNearestLankers(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestLankers = nil
    local minDistance = math.huge
    
    -- 检查_Effects文件夹下的所有Model
    local effectsFolder = workspace:FindFirstChild("_Effects")
    if effectsFolder then
        for _, child in ipairs(effectsFolder:GetChildren()) do
            if child:IsA("Model") then
                local targetPart = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
                if targetPart then
                    local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearestLankers = targetPart
                    end
                end
            end
        end
    end
    
    return nearestLankers
end

local function startLankersTeleport()
    if lankersTeleportRunning then
        stopLankersTeleport()
        return
    end
    
    lankersTeleportRunning = true
    local player = game.Players.LocalPlayer
    
    lankersTeleportThread = coroutine.create(function()
        while lankersTeleportRunning and player do
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local nearestLankers = findNearestLankers(character)
                    if nearestLankers then
                        humanoidRootPart.CFrame = nearestLankers.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
            task.wait(0.3)
        end
        lankersTeleportRunning = false
        lankersTeleportThread = nil
    end)
    coroutine.resume(lankersTeleportThread)
end

-- ===================== 复活节活动功能 =====================
local function activateEasterBoard()
    pcall(function()
        local easterBoard = workspace.Map.Islands["Easter Island"]["Easter Board"]
        
        local function findFirstPrompt(parent)
            for _, child in ipairs(parent:GetDescendants()) do
                if child:IsA("ProximityPrompt") then
                    return child
                end
            end
            return nil
        end

        local prompt = findFirstPrompt(easterBoard)
        if prompt then
            fireproximityprompt(prompt)
            print("✅ 已打开复活节任务板")
        end
    end)
end

local function activateEasterAngel()
    pcall(function()
        local easterAngel = workspace.Map.Islands["Easter Island"]["Easter Angel"]
        local prompt = easterAngel.HumanoidRootPart.ProximityPrompt
        if prompt then
            fireproximityprompt(prompt)
            print("✅ 已打开复活节商店")
        end
    end)
end

-- ===================== Egg收集功能 =====================
local eggCollectionRunning = false
local eggCollectionThread = nil

local function stopEggCollection()
    if eggCollectionRunning then
        eggCollectionRunning = false
        if eggCollectionThread then
            coroutine.close(eggCollectionThread)
            eggCollectionThread = nil
        end
        print("⏹️ 蛋狩猎已停止")
    end
end

local function startEggCollection()
    if eggCollectionRunning then
        stopEggCollection()
        return
    end
    
    eggCollectionRunning = true
    
    local player = game.Players.LocalPlayer
    
    eggCollectionThread = coroutine.create(function()
        while eggCollectionRunning and player do
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local eggs = {}
                    for _, child in ipairs(workspace:GetChildren()) do
                        if child.Name == "Egg" and child:IsA("BasePart") then
                            table.insert(eggs, child)
                        end
                    end

                    if #eggs > 0 then
                        table.sort(eggs, function(a, b)
                            return a.Position.X < b.Position.X
                        end)

                        for i, egg in ipairs(eggs) do
                            if not eggCollectionRunning or not character or not character:FindFirstChild("HumanoidRootPart") then break end
                            humanoidRootPart.CFrame = egg.CFrame + Vector3.new(0, 3, 0)
                            print("🚀 传送到蛋 ["..i.."/"..#eggs.."]: "..egg.Name)
                            task.wait(1)
                        end
                    else
                        task.wait(2)
                    end
                end
            end
            task.wait(0.1)
        end
        eggCollectionRunning = false
        eggCollectionThread = nil
    end)
    coroutine.resume(eggCollectionThread)
end

-- ===================== 外星人传送功能 =====================
local alienTeleportRunning = false
local alienTeleportThread = nil
local DepositGooEvent = ReplicatedStorage:WaitForChild("Source")
    :WaitForChild("Network")
    :WaitForChild("RemoteEvents")
    :WaitForChild("DepositGoo")

local function stopAlienTeleport()
    if alienTeleportRunning then
        alienTeleportRunning = false
        if alienTeleportThread then
            coroutine.close(alienTeleportThread)
            alienTeleportThread = nil
        end
        print("⏹️ 外星人传送已停止")
    end
end

local function setupBackpackMonitor()
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    
    while alienTeleportRunning and player do
        local alienGoo = backpack:FindFirstChild("Alien Goo")
        if alienGoo then
            task.wait(5)
            DepositGooEvent:FireServer()
        end
        task.wait(0.5)
    end
end

local function findNearestAlien(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestAlien = nil
    local minDistance = math.huge
    
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Alien" and child:IsA("Model") then
            local targetPart = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
            if targetPart then
                local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearestAlien = targetPart
                end
            end
        end
    end
    return nearestAlien
end

local function startAlienTeleport()
    if alienTeleportRunning then
        stopAlienTeleport()
        return
    end
    
    alienTeleportRunning = true
    local player = game.Players.LocalPlayer
    
    coroutine.wrap(setupBackpackMonitor)()
    
    alienTeleportThread = coroutine.create(function()
        while alienTeleportRunning and player do
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local nearestAlien = findNearestAlien(character)
                    if nearestAlien then
                        humanoidRootPart.CFrame = nearestAlien.CFrame + Vector3.new(0, 9, 0)
                    end
                end
            end
            task.wait(0.3)
        end
        alienTeleportRunning = false
        alienTeleportThread = nil
    end)
    coroutine.resume(alienTeleportThread)
end

-- ===================== 半自动里德利功能=====================
local ridleyTeleportRunning = false
local ridleyTeleportThread = nil
local objectsToRemove = {"AcidPool"}

local function stopRidleyTeleport()
    if ridleyTeleportRunning then
        ridleyTeleportRunning = false
        if ridleyTeleportThread then
            coroutine.close(ridleyTeleportThread)
            ridleyTeleportThread = nil
        end
        print("⏹️ 里德利传送已停止")
    end
end

local function removeDangerParts()
    -- 移除Ridley's Cave中的危险部件
    local ridleysCave = workspace.Map.Islands["Ridley's Cave"]
    if ridleysCave then
        for _, child in ipairs(ridleysCave:GetChildren()) do
            -- 检查子对象是否同时包含TouchInterest和Texture
            local hasTouchInterest = false
            local hasTexture = false
            
            for _, descendant in ipairs(child:GetDescendants()) do
                if descendant.Name == "TouchInterest" then
                    hasTouchInterest = true
                elseif descendant.Name == "Texture" then
                    hasTexture = true
                end
                
                -- 如果两个条件都满足，则跳出循环
                if hasTouchInterest and hasTexture then
                    break
                end
            end
            
            -- 只有当同时包含TouchInterest和Texture时才移除
            if hasTouchInterest and hasTexture then
                child:Destroy()
                print("✅ 已移除危险Part: "..child.Name)
            end
        end
    end
    
    -- 移除Camera下的AcidPool对象
    local acidPool = workspace.Camera:FindFirstChild("AcidPool")
    if acidPool then
        acidPool:Destroy()
    end
end

local function findNearestBomb(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestBomb = nil
    local minDistance = math.huge
    
    local bombSpawnPoints = workspace.Map.DinoArena.BombSpawnPoints:GetChildren()
    for _, spawnPoint in ipairs(bombSpawnPoints) do
        for _, child in ipairs(spawnPoint:GetChildren()) do
            if child:IsA("Model") and child.Name == "Bomb" then
                local targetPart = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
                if targetPart then
                    local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearestBomb = targetPart
                    end
                end
            end
        end
    end
    return nearestBomb
end

local function startRidleyTeleport()
    if ridleyTeleportRunning then
        stopRidleyTeleport()
        return
    end
    
    ridleyTeleportRunning = true
    local player = game.Players.LocalPlayer
    
    -- 先移除一次危险对象
    removeDangerParts()
    
    ridleyTeleportThread = coroutine.create(function()
        while ridleyTeleportRunning and player do
            -- 持续移除危险对象
            removeDangerParts()
            
            -- 传送到最近的Bomb
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local nearestBomb = findNearestBomb(character)
                    if nearestBomb then
                        humanoidRootPart.CFrame = nearestBomb.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
            task.wait(0.3)
        end
        ridleyTeleportRunning = false
        ridleyTeleportThread = nil
    end)
    coroutine.resume(ridleyTeleportThread)
end

-- ===================== 创建功能按钮 =====================
local hideButton = createButton("隐藏UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("关闭UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
    print("✅ UI已关闭")
end)

createButton("控制台", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, "F9", false, game)
    print("✅ 已打开控制台")
end)

-- 复活节活动按钮
createButton("复活节任务板", UDim2.new(0, 140, 0, 10), Color3.new(0.8, 0.2, 0.8), activateEasterBoard)
createButton("复活节商店", UDim2.new(0, 140, 0, 50), Color3.new(0.8, 0.2, 0.8), activateEasterAngel)

-- 蛋狩猎按钮
local eggHuntButton = createButton("半自动蛋狩猎: 关", UDim2.new(0, 140, 0, 90), Color3.new(0.5, 1, 0.5))
eggHuntButton.MouseButton1Click:Connect(function()
    eggHuntEnabled = not eggHuntEnabled
    eggHuntButton.Text = "半自动蛋狩猎: "..(eggHuntEnabled and "开" or "关")
    eggHuntButton.TextColor3 = eggHuntEnabled and Color3.new(0,1,0) or Color3.new(0.5,1,0.5)
    if eggHuntEnabled then startEggCollection() else stopEggCollection() end
end)

-- 半自动外星人按钮
local alienHuntButton = createButton("半自动外星人: 关", UDim2.new(0, 270, 0, 10), Color3.new(1, 0.5, 0))
alienHuntButton.MouseButton1Click:Connect(function()
    alienHuntEnabled = not alienHuntEnabled
    alienHuntButton.Text = "半自动外星人: "..(alienHuntEnabled and "开" or "关")
    alienHuntButton.TextColor3 = alienHuntEnabled and Color3.new(0,1,0) or Color3.new(1,0.5,0)
    if alienHuntEnabled then startAlienTeleport() else stopAlienTeleport() end
end)

-- 半自动里德利按钮
local ridleyHuntButton = createButton("半自动里德利: 关", UDim2.new(0, 270, 0, 50), Color3.new(0.5, 0.8, 1))
ridleyHuntButton.MouseButton1Click:Connect(function()
    ridleyHuntEnabled = not ridleyHuntEnabled
    ridleyHuntButton.Text = "半自动里德利: "..(ridleyHuntEnabled and "开" or "关")
    ridleyHuntButton.TextColor3 = ridleyHuntEnabled and Color3.new(0,1,0) or Color3.new(0.5,0.8,1)
    if ridleyHuntEnabled then startRidleyTeleport() else stopRidleyTeleport() end
end)

-- 自动朗克斯按钮
local lankersHuntButton = createButton("半自动朗克斯: 关", UDim2.new(0, 270, 0, 90), Color3.new(0.8, 0.5, 1))
lankersHuntButton.MouseButton1Click:Connect(function()
    lankersHuntEnabled = not lankersHuntEnabled
    lankersHuntButton.Text = "半自动朗克斯: "..(lankersHuntEnabled and "开" or "关")
    lankersHuntButton.TextColor3 = lankersHuntEnabled and Color3.new(0,1,0) or Color3.new(0.8,0.5,1)
    if lankersHuntEnabled then startLankersTeleport() else stopLankersTeleport() end
end)

-- ===================== UI拖动功能 =====================
local dragging = false 
local dragInput 
local dragStart = nil 
local startPositions = {} -- 存储所有按钮的初始位置

-- 初始化记录所有按钮位置
for _, child in ipairs(screenGui:GetChildren()) do
    if child:IsA("TextButton") then
        startPositions[child] = child.Position
    end
end

local function updatePos(input) 
    if not dragStart then return end
    
    local delta = input.Position - dragStart 
    
    -- 更新所有按钮位置
    for button, startPos in pairs(startPositions) do
        button.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end 

hideButton.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = true 
        dragStart = input.Position
        
        -- 拖动开始时重新记录所有按钮当前位置
        for _, child in ipairs(screenGui:GetChildren()) do
            if child:IsA("TextButton") then
                startPositions[child] = child.Position
            end
        end
        
        input.Changed:Connect(function() 
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
            end 
        end) 
    end 
end) 

hideButton.InputChanged:Connect(function(input) 
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        dragInput = input 
    end 
end) 

game:GetService("UserInputService").InputChanged:Connect(function(input) 
    if dragging and input == dragInput then 
        updatePos(input) 
    end 
end)

-- 隐藏/显示UI逻辑
hideButton.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    for _, child in ipairs(screenGui:GetChildren()) do
        if child:IsA("TextButton") and child ~= hideButton then
            child.Visible = not isHidden
        end
    end
    hideButton.Text = isHidden and "显示UI" or "隐藏UI"
    print("UI状态:", isHidden and "已隐藏" or "已显示")
end)

-- 加载完成通知
task.wait(0.5)
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = gameName.."｜挖掘它｜加载完成",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 包含复活节活动、蛋狩猎、半自动外星人、半自动里德利和自动朗克斯功能\n- 版本: 1.4.0\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

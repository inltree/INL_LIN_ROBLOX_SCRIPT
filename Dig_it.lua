-- 服务声明
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- 全局状态变量
local autoSliderEnabled = false
local autoDigEnabled = false
local autoCreatePileEnabled = false
local lankersHuntEnabled = false
local fallingStarEnabled = false
local alienHuntEnabled = false
local ridleyHuntEnabled = false

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

task.wait(0.1)

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

-- ===================== 自动滑块功能 =====================
local autoSliderRunning = false
local autoSliderConnection = nil

local function stopAutoSlider()
    if autoSliderRunning then
        autoSliderRunning = false
        if autoSliderConnection then
            autoSliderConnection:Disconnect()
            autoSliderConnection = nil
        end
    end
end

local function startAutoSlider()
    if autoSliderRunning then
        stopAutoSlider()
        return
    end
    
    autoSliderRunning = true
    
    local function alignCursorToArea(cursor, area)
        if not cursor or not area then return false end
        
        local success, areaCenterX = pcall(function()
            local areaSize = area.AbsoluteSize
            local areaPos = area.AbsolutePosition
            return areaPos.X + (areaSize.X / 2)
        end)
        if not success then return false end
        
        local success2, cursorCenterX = pcall(function()
            local cursorSize = cursor.AbsoluteSize
            local cursorPos = cursor.AbsolutePosition
            return cursorPos.X + (cursorSize.X / 2)
        end)
        if not success2 then return false end
        
        local deltaX = areaCenterX - cursorCenterX
        
        -- 如果误差小于1像素，不再调整
        if math.abs(deltaX) < 1 then
            return true
        end
        
        -- 更新Cursor位置（保持Y不变）
        pcall(function()
            cursor.Position = UDim2.new(
                cursor.Position.X.Scale,
                cursor.Position.X.Offset + deltaX,
                cursor.Position.Y.Scale,
                cursor.Position.Y.Offset
            )
        end)
        return true
    end
    
    -- 使用RunService逐帧检查并执行
    autoSliderConnection = RunService.Heartbeat:Connect(function()
        if not autoSliderEnabled then return end
        
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        local main = playerGui:FindFirstChild("Main")
        if not main then return end
        
        local digMinigame = main:FindFirstChild("DigMinigame")
        if not digMinigame then return end
        
        local cursor = digMinigame:FindFirstChild("Cursor")
        local area = digMinigame:FindFirstChild("Area")
        if not cursor or not area then return end
        
        -- 尝试对齐滑块
        alignCursorToArea(cursor, area)
    end)
end

-- ===================== 自动挖掘功能 =====================
local autoDigRunning = false
local autoDigThread = nil

local function getNearestPile(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local treasurePiles = Workspace:FindFirstChild("TreasurePiles")
    if not treasurePiles then return nil end
    
    local nearestPile = nil
    local minDistance = 15
    
    for _, pile in ipairs(treasurePiles:GetChildren()) do
        local primaryPart = pile:FindFirstChild("DigTarget") or pile:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            local distance = (humanoidRootPart.Position - primaryPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                nearestPile = pile
            end
        end
    end
    
    return nearestPile
end

local function stopAutoDig()
    if autoDigRunning then
        autoDigRunning = false
        if autoDigThread then
            coroutine.close(autoDigThread)
            autoDigThread = nil
        end
    end
end

local function startAutoDig()
    if autoDigRunning then
        stopAutoDig()
        return
    end
    
    autoDigRunning = true
    
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local diggingRemote = ReplicatedStorage:WaitForChild("Source"):WaitForChild("Network"):WaitForChild("RemoteFunctions"):WaitForChild("Digging")
    
    autoDigThread = coroutine.create(function()
        while autoDigRunning and autoDigEnabled do
            if character and character:FindFirstChild("HumanoidRootPart") then
                local nearestPile = getNearestPile(character)
                if nearestPile then
                    pcall(function()
                        local args = {
                            {
                                Command = "DigPile",
                                TargetPileIndex = tonumber(nearestPile.Name) or nearestPile.Name
                            }
                        }
                        diggingRemote:InvokeServer(unpack(args))
                    end)
                    task.wait(0.1)
                else
                    task.wait(0.5)
                end
            else
                character = player.Character or player.CharacterAdded:Wait()
                task.wait(1)
            end
        end
        autoDigRunning = false
    end)
    coroutine.resume(autoDigThread)
end

-- ===================== 自动创建堆功能 =====================
local autoCreatePileRunning = false
local autoCreatePileThread = nil

local function stopAutoCreatePile()
    if autoCreatePileRunning then
        autoCreatePileRunning = false
        if autoCreatePileThread then
            coroutine.close(autoCreatePileThread)
            autoCreatePileThread = nil
        end
    end
end

local function startAutoCreatePile()
    if autoCreatePileRunning then
        stopAutoCreatePile()
        return
    end
    
    autoCreatePileRunning = true
    
    local DiggingRemote = ReplicatedStorage:WaitForChild("Source"):WaitForChild("Network"):WaitForChild("RemoteFunctions"):WaitForChild("Digging")
    
    autoCreatePileThread = coroutine.create(function()
        while autoCreatePileRunning and autoCreatePileEnabled do
            pcall(function()
                local args = {
                    {
                        Command = "CreatePile"
                    }
                }
                DiggingRemote:InvokeServer(unpack(args))
            end)
            task.wait(0.2)
        end
        autoCreatePileRunning = false
    end)
    coroutine.resume(autoCreatePileThread)
end

-- ===================== 半自动朗克斯功能 =====================
local lankersTeleportRunning = false
local lankersTeleportThread = nil

local function stopLankersTeleport()
    if lankersTeleportRunning then
        lankersTeleportRunning = false
        if lankersTeleportThread then
            coroutine.close(lankersTeleportThread)
            lankersTeleportThread = nil
        end
    end
end

local function findNearestLankers(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestLankers = nil
    local minDistance = math.huge
    
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
        while lankersTeleportRunning and lankersHuntEnabled do
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
    end)
    coroutine.resume(lankersTeleportThread)
end

-- ===================== 半自动坠落星功能 =====================
local fallingStarTeleportRunning = false
local fallingStarTeleportThread = nil

local function stopFallingStarTeleport()
    if fallingStarTeleportRunning then
        fallingStarTeleportRunning = false
        if fallingStarTeleportThread then
            coroutine.close(fallingStarTeleportThread)
            fallingStarTeleportThread = nil
        end
    end
end

local function findNearestFallingStar(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestStar = nil
    local minDistance = math.huge
    
    local treasurePiles = workspace:FindFirstChild("TreasurePiles")
    if treasurePiles then
        for _, child in ipairs(treasurePiles:GetChildren()) do
            if child:IsA("Model") then
                local starLight = child:FindFirstChild("StarLightEffect")
                if starLight then
                    local targetPart = starLight:FindFirstChild("HumanoidRootPart") or starLight.PrimaryPart or starLight:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
                        if distance < minDistance then
                            minDistance = distance
                            nearestStar = targetPart
                        end
                    end
                end
            end
        end
    end
    
    return nearestStar
end

local function startFallingStarTeleport()
    if fallingStarTeleportRunning then
        stopFallingStarTeleport()
        return
    end
    
    fallingStarTeleportRunning = true
    local player = game.Players.LocalPlayer
    
    fallingStarTeleportThread = coroutine.create(function()
        while fallingStarTeleportRunning and fallingStarEnabled do
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local nearestStar = findNearestFallingStar(character)
                    if nearestStar then
                        humanoidRootPart.CFrame = nearestStar.CFrame + Vector3.new(0, 0, 0)
                    end
                end
            end
            task.wait(0.3)
        end
        fallingStarTeleportRunning = false
    end)
    coroutine.resume(fallingStarTeleportThread)
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
    end
end

local function setupBackpackMonitor()
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    
    while alienTeleportRunning and alienHuntEnabled do
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
        while alienTeleportRunning and alienHuntEnabled do
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
    end)
    coroutine.resume(alienTeleportThread)
end

-- ===================== 半自动里德利功能=====================
local ridleyTeleportRunning = false
local ridleyTeleportThread = nil

local function stopRidleyTeleport()
    if ridleyTeleportRunning then
        ridleyTeleportRunning = false
        if ridleyTeleportThread then
            coroutine.close(ridleyTeleportThread)
            ridleyTeleportThread = nil
        end
    end
end

local function removeDangerParts()
    local ridleysCave = workspace.Map.Islands["Ridley's Cave"]
    if ridleysCave then
        for _, child in ipairs(ridleysCave:GetChildren()) do
            local hasTouchInterest = false
            local hasTexture = false
            
            for _, descendant in ipairs(child:GetDescendants()) do
                if descendant.Name == "TouchInterest" then
                    hasTouchInterest = true
                elseif descendant.Name == "Texture" then
                    hasTexture = true
                end
                
                if hasTouchInterest and hasTexture then
                    break
                end
            end
            
            if hasTouchInterest and hasTexture then
                child:Destroy()
            end
        end
    end
    
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
    
    removeDangerParts()
    
    ridleyTeleportThread = coroutine.create(function()
        while ridleyTeleportRunning and ridleyHuntEnabled do
            removeDangerParts()
            
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
    end)
    coroutine.resume(ridleyTeleportThread)
end

-- ===================== 创建功能按钮 =====================
local hideButton = createButton("隐藏UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("关闭UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
    -- 停止所有正在运行的功能
    stopAutoSlider()
    stopAutoDig()
    stopAutoCreatePile()
    stopLankersTeleport()
    stopFallingStarTeleport()
    stopAlienTeleport()
    stopRidleyTeleport()
    
    screenGui:Destroy()
    print("✅ "..gameName.." - 面板: 关闭")
end)

createButton("控制台", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
    print("✅ 控制台: 已开启")
end)

-- 自动滑块按钮
local autoSliderButton = createButton("自动滑块: 关", UDim2.new(0, 270, 0, 10), Color3.new(0.5, 1, 0.5))
autoSliderButton.MouseButton1Click:Connect(function()
    autoSliderEnabled = not autoSliderEnabled
    autoSliderButton.Text = "自动滑块: "..(autoSliderEnabled and "开" or "关")
    autoSliderButton.TextColor3 = autoSliderEnabled and Color3.new(0,1,0) or Color3.new(0.5,1,0.5)
    print("✅ 自动滑块: "..(autoSliderEnabled and "已开启" or "已关闭"))
    if autoSliderEnabled then 
        startAutoSlider() 
    else 
        stopAutoSlider() 
    end
end)

-- 自动挖掘按钮
local autoDigButton = createButton("自动挖掘: 关", UDim2.new(0, 270, 0, 50), Color3.new(0.2, 0.8, 0.8))
autoDigButton.MouseButton1Click:Connect(function()
    autoDigEnabled = not autoDigEnabled
    autoDigButton.Text = "自动挖掘: "..(autoDigEnabled and "开" or "关")
    autoDigButton.TextColor3 = autoDigEnabled and Color3.new(0,1,0) or Color3.new(0.2,0.8,0.8)
    print("✅ 自动挖掘: "..(autoDigEnabled and "已开启" or "已关闭"))
    if autoDigEnabled then 
        startAutoDig() 
    else 
        stopAutoDig() 
    end
end)

-- 自动创建堆按钮
local autoCreatePileButton = createButton("自动创建堆: 关", UDim2.new(0, 270, 0, 90), Color3.new(0.8, 0.2, 0.8))
autoCreatePileButton.MouseButton1Click:Connect(function()
    autoCreatePileEnabled = not autoCreatePileEnabled
    autoCreatePileButton.Text = "自动创建堆: "..(autoCreatePileEnabled and "开" or "关")
    autoCreatePileButton.TextColor3 = autoCreatePileEnabled and Color3.new(0,1,0) or Color3.new(0.8,0.2,0.8)
    print("✅ 自动创建堆: "..(autoCreatePileEnabled and "已开启" or "已关闭"))
    if autoCreatePileEnabled then 
        startAutoCreatePile() 
    else 
        stopAutoCreatePile() 
    end
end)

-- 自动朗克斯按钮
local lankersHuntButton = createButton("半自动朗克斯: 关", UDim2.new(0, 140, 0, 10), Color3.new(0.8, 0.5, 1))
lankersHuntButton.MouseButton1Click:Connect(function()
    lankersHuntEnabled = not lankersHuntEnabled
    lankersHuntButton.Text = "半自动朗克斯: "..(lankersHuntEnabled and "开" or "关")
    lankersHuntButton.TextColor3 = lankersHuntEnabled and Color3.new(0,1,0) or Color3.new(0.8,0.5,1)
    print("✅ 半自动朗克斯: "..(lankersHuntEnabled and "已开启" or "已关闭"))
    if lankersHuntEnabled then 
        startLankersTeleport() 
    else 
        stopLankersTeleport() 
    end
end)

-- 半自动坠落星按钮
local fallingStarButton = createButton("半自动坠落星: 关", UDim2.new(0, 140, 0, 50), Color3.new(1, 0.84, 0))
fallingStarButton.MouseButton1Click:Connect(function()
    fallingStarEnabled = not fallingStarEnabled
    fallingStarButton.Text = "半自动坠落星: "..(fallingStarEnabled and "开" or "关")
    fallingStarButton.TextColor3 = fallingStarEnabled and Color3.new(0,1,0) or Color3.new(1,0.84,0)
    print("✅ 半自动坠落星: "..(fallingStarEnabled and "已开启" or "已关闭"))
    if fallingStarEnabled then 
        startFallingStarTeleport() 
    else 
        stopFallingStarTeleport() 
    end
end)

-- 半自动外星人按钮
local alienHuntButton = createButton("半自动外星人: 关", UDim2.new(0, 140, 0, 90), Color3.new(1, 0.5, 0))
alienHuntButton.MouseButton1Click:Connect(function()
    alienHuntEnabled = not alienHuntEnabled
    alienHuntButton.Text = "半自动外星人: "..(alienHuntEnabled and "开" or "关")
    alienHuntButton.TextColor3 = alienHuntEnabled and Color3.new(0,1,0) or Color3.new(1,0.5,0)
    print("✅ 半自动外星人: "..(alienHuntEnabled and "已开启" or "已关闭"))
    if alienHuntEnabled then 
        startAlienTeleport() 
    else 
        stopAlienTeleport() 
    end
end)

-- 半自动里德利按钮
local ridleyHuntButton = createButton("半自动里德利: 关", UDim2.new(0, 140, 0, 130), Color3.new(0.5, 0.8, 1))
ridleyHuntButton.MouseButton1Click:Connect(function()
    ridleyHuntEnabled = not ridleyHuntEnabled
    ridleyHuntButton.Text = "半自动里德利: "..(ridleyHuntEnabled and "开" or "关")
    ridleyHuntButton.TextColor3 = ridleyHuntEnabled and Color3.new(0,1,0) or Color3.new(0.5,0.8,1)
    print("✅ 半自动里德利: "..(ridleyHuntEnabled and "已开启" or "已关闭"))
    if ridleyHuntEnabled then 
        startRidleyTeleport() 
    else 
        stopRidleyTeleport() 
    end
end)

-- ===================== UI拖动功能 =====================
local dragging = false 
local dragInput 
local dragStart = nil 
local startPositions = {}

-- 初始化记录所有按钮位置
for _, child in ipairs(screenGui:GetChildren()) do
    if child:IsA("TextButton") then
        startPositions[child] = child.Position
    end
end

local function updatePos(input) 
    if not dragStart then return end
    
    local delta = input.Position - dragStart 
    
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
    print("✅ 隐藏状态:", isHidden and "已关闭" or "已开启")
end)

-- 加载完成通知
task.wait(0.5)
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = gameName.."｜挖掘它｜加载完成",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 包含自动挖掘、自动创建堆、自动滑块及多种半自动狩猎功能\n- 版本: 1.6.1\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

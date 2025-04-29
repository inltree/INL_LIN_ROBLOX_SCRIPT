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

-- 复活节活动功能
local function activateEasterBoard()
    pcall(function()
        local easterBoard = workspace.Map.Islands["Easter Island"]["Easter Board"]
        
        -- 递归查找
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

-- Egg收集功能
local eggCollectionRunning = false
local eggCollectionThread = nil
local collectedEggs = {} -- 用于记录已收集的Egg

local function stopEggCollection()
    if eggCollectionRunning then
        eggCollectionRunning = false
        if eggCollectionThread then
            coroutine.close(eggCollectionThread)
            eggCollectionThread = nil
        end
        table.clear(collectedEggs) -- 清空已收集记录
        print("⏹️ 蛋狩猎已停止")
    end
end

local function startEggCollection()
    if eggCollectionRunning then
        stopEggCollection()
        return
    end
    
    eggCollectionRunning = true
    table.clear(collectedEggs) -- 开始新的收集时清空记录
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    eggCollectionThread = coroutine.create(function()
        while eggCollectionRunning do
            local eggs = {}
            -- 只收集未被收集过的Egg
            for _, child in ipairs(workspace:GetChildren()) do
                if child.Name == "Egg" and child:IsA("BasePart") and not collectedEggs[child] then
                    table.insert(eggs, child)
                end
            end

            if #eggs > 0 then
                -- 按位置排序
                table.sort(eggs, function(a, b)
                    return a.Position.X < b.Position.X
                end)

                -- 传送并标记已收集
                for i, egg in ipairs(eggs) do
                    if not eggCollectionRunning then break end
                    
                    humanoidRootPart.CFrame = egg.CFrame + Vector3.new(0, 3, 0)
                    collectedEggs[egg] = true -- 标记为已收集
                    print("🚀 传送到蛋 ["..i.."/"..#eggs.."]: "..egg.Name)
                    
                    task.wait(1)
                end
            else
                task.wait(2) -- 没有新蛋时等待2秒再检查
            end
        end
        
        eggCollectionRunning = false
        eggCollectionThread = nil
    end)
    
    coroutine.resume(eggCollectionThread)
end

-- 外星人传送功能
local alienTeleportRunning = false
local alienTeleportThread = nil

-- 粘液自动提交功能
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
    
    -- 持续检查背包中的Alien Goo
    while alienTeleportRunning do
        local alienGoo = backpack:FindFirstChild("Alien Goo")
        if alienGoo then
            task.wait(5) -- 等待5秒后提交
            DepositGooEvent:FireServer()
        end
        task.wait(0.5) -- 每0.5秒检查一次背包
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
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- 启动背包监控
    coroutine.wrap(setupBackpackMonitor)()
    
    alienTeleportThread = coroutine.create(function()
        while alienTeleportRunning do
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local nearestAlien = findNearestAlien(character)
                if nearestAlien then
                    humanoidRootPart.CFrame = nearestAlien.CFrame + Vector3.new(0, 9, 0)
                end
            end
            task.wait(0.3) -- 每0.3秒检测一次最近的外星人
        end
    end)
    
    coroutine.resume(alienTeleportThread)
end

-- 创建功能按钮
local hideButton = createButton("隐藏UI", UDim2.new(1, -130, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("关闭UI", UDim2.new(1, -130, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
    print("✅ UI已关闭")
end)

createButton("控制台", UDim2.new(1, -130, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, "F9", false, game)
    print("✅ 已打开控制台")
end)

-- 复活节活动按钮
createButton("复活节任务板", UDim2.new(1, -130, 0, 130), Color3.new(0.8, 0.2, 0.8), function()
    activateEasterBoard()
end)

createButton("复活节商店", UDim2.new(1, -130, 0, 170), Color3.new(0.8, 0.2, 0.8), function()
    activateEasterAngel()
end)

-- 蛋狩猎按钮
local eggHuntEnabled = false
local eggHuntButton = createButton("蛋狩猎: 关", UDim2.new(1, -130, 0, 210), Color3.new(0.5, 1, 0.5))
eggHuntButton.MouseButton1Click:Connect(function()
    eggHuntEnabled = not eggHuntEnabled
    eggHuntButton.Text = "蛋狩猎: "..(eggHuntEnabled and "开" or "关")
    eggHuntButton.TextColor3 = eggHuntEnabled and Color3.new(0,1,0) or Color3.new(0.5,1,0.5)
    
    if eggHuntEnabled then
        startEggCollection()
    else
        stopEggCollection()
    end
end)

-- 半自动外星人按钮
local alienHuntEnabled = false
local alienHuntButton = createButton("半自动外星人: 关", UDim2.new(1, -130, 0, 250), Color3.new(1, 0.5, 0))
alienHuntButton.MouseButton1Click:Connect(function()
    alienHuntEnabled = not alienHuntEnabled
    alienHuntButton.Text = "半自动外星人: "..(alienHuntEnabled and "开" or "关")
    alienHuntButton.TextColor3 = alienHuntEnabled and Color3.new(0,1,0) or Color3.new(1,0.5,0)
    
    if alienHuntEnabled then
        startAlienTeleport()
    else
        stopAlienTeleport()
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

-- 拖动功能 
local dragging = false 
local dragInput 
local dragStart = nil 
local startPos = nil 

local function updatePos(input) 
    local delta = input.Position - dragStart 
    hideButton.Position = UDim2.new( 
        startPos.X.Scale, startPos.X.Offset + delta.X, 
        startPos.Y.Scale, startPos.Y.Offset + delta.Y 
    ) 
    local yOffset = 40 
    for i, child in ipairs(screenGui:GetChildren()) do 
        if child:IsA("TextButton") and child ~= hideButton then 
            child.Position = UDim2.new( 
                hideButton.Position.X.Scale, hideButton.Position.X.Offset, 
                hideButton.Position.Y.Scale, hideButton.Position.Y.Offset + yOffset * (i-1) 
            ) 
        end 
    end 
end 

hideButton.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = true 
        dragStart = input.Position 
        startPos = hideButton.Position 
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

-- 加载完成通知
task.wait(0.5)
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = gameName.."｜挖掘它｜加载完成",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 包含复活节活动、蛋狩猎和半自动外星人功能\n- 版本: 0.1.6\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

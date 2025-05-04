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

-- ===================== 移除植物部件功能 =====================
local totalRemoved = 0

local function RemovePartsWithoutPrompts(parent)
    local removed = 0
    local children = parent:GetChildren()
    
    for i = #children, 1, -1 do
        local child = children[i]
        
        if child:IsA("Model") then
            removed = removed + RemovePartsWithoutPrompts(child)
        elseif child:IsA("BasePart") then
            local hasPrompt = false
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    hasPrompt = true
                    break
                end
            end
            
            if not hasPrompt then
                child:Destroy()
                removed = removed + 1
            end
        end
    end
    
    return removed
end

local function ProcessFarmWithFeedback()
    print("✅ 移除植物部件：已点击")
    print(("-"):rep(40))
    
    totalRemoved = 0  -- 重置计数器
    
    for idx, farmChild in ipairs(workspace.Farm:GetChildren()) do
        local childRemoved = 0
        local childName = farmChild.Name
        
        -- 查找Important.Plants_Physical路径
        local important = farmChild:FindFirstChild("Important")
        if important then
            local plantsPhysical = important:FindFirstChild("Plants_Physical")
            if plantsPhysical then
                for _, plantModel in ipairs(plantsPhysical:GetChildren()) do
                    if plantModel:IsA("Model") then
                        childRemoved = childRemoved + RemovePartsWithoutPrompts(plantModel)
                    end
                end
            end
        end
        
        print(string.format("农场 [%d] %-20s : 已移除 %d 植物部件", 
              idx, childName, childRemoved))
        
        totalRemoved = totalRemoved + childRemoved
    end
    
    print(("-"):rep(40))
    print(string.format("✅ 已移除 %d 植物部件", totalRemoved))
end

-- ===================== 创建按钮 =====================
local hideButton = createButton("隐藏UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("关闭UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
    print("✅ "..gameName.." - 面板: 已关闭")
end)

createButton("控制台", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
    print("✅ 控制台: 已开启")
end)

-- 工具商店按钮
createButton("工具商店", UDim2.new(0, 270, 0, 10), Color3.new(0, 1, 1), function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        -- 传送到教程点3
        character.HumanoidRootPart.CFrame = workspace.Tutorial_Points.Tutorial_Point_3.CFrame
        print("✅ 工具商店: 已点击")
    end
end)

-- 自动购买种子功能
local autoSeedsEnabled = false
local autoSeedsButton = createButton("自动种子: 关", UDim2.new(0, 140, 0, 10), Color3.new(0.5, 1, 0.5))

autoSeedsButton.MouseButton1Click:Connect(function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsButton.Text = "自动种子: " .. (autoSeedsEnabled and "开" or "关")
    autoSeedsButton.TextColor3 = autoSeedsEnabled and Color3.new(0, 1, 0) or Color3.new(0.5, 1, 0.5)
    print("✅ 自动种子: " .. (autoSeedsEnabled and "已开启" or "已关闭"))
    
    if autoSeedsEnabled then
        spawn(function()
            while autoSeedsEnabled do
                local seedTypes = {
                    "Pepper", "Mushroom", "Grape", "Mango", "Dragon Fruit", "Cactus",
                    "Coconut", "Bamboo", "Apple", "Pumpkin", "Watermelon",
                    "Daffodil", "Corn", "Tomato", "Orange Tulip", "Blueberry",
                    "Strawberry", "Carrot"
                }

                local buyEvent = game:GetService("ReplicatedStorage")
                    :WaitForChild("GameEvents")
                    :WaitForChild("BuySeedStock")

                for _, seed in ipairs(seedTypes) do
                    if not autoSeedsEnabled then break end
                    buyEvent:FireServer(seed)
                    task.wait(0.1)
                end
                
                task.wait(0.1)
            end
        end)
    end
end)

-- 自动购买工具功能
local autoToolsEnabled = false
local autoToolsButton = createButton("自动工具: 关", UDim2.new(0, 140, 0, 50), Color3.new(0.5, 0.5, 1))

autoToolsButton.MouseButton1Click:Connect(function()
    autoToolsEnabled = not autoToolsEnabled
    autoToolsButton.Text = "自动工具: " .. (autoToolsEnabled and "开" or "关")
    autoToolsButton.TextColor3 = autoToolsEnabled and Color3.new(0, 0, 1) or Color3.new(0.5, 0.5, 1)
    print("✅ 自动工具: " .. (autoToolsEnabled and "已开启" or "已关闭"))
    
    if autoToolsEnabled then
        spawn(function()
            while autoToolsEnabled do
                local gearList = {
                    "Master Sprinkler", "Lightning Rod", "Godly Sprinkler",
                    "Advanced Sprinkler", "Basic Sprinkler", "Trowel", "Watering Can"
                }

                local buyEvent = game:GetService("ReplicatedStorage")
                    :WaitForChild("GameEvents")
                    :WaitForChild("BuyGearStock")

                for _, gear in ipairs(gearList) do
                    if not autoToolsEnabled then break end
                    buyEvent:FireServer(gear)
                    task.wait(0.1)
                end
                
                task.wait(0.1)
            end
        end)
    end
end)

-- 自动购买宠物功能
local autoPetsEnabled = false
local autoPetsButton = createButton("自动宠物: 关", UDim2.new(0, 140, 0, 90), Color3.new(1, 0.5, 1))

autoPetsButton.MouseButton1Click:Connect(function()
    autoPetsEnabled = not autoPetsEnabled
    autoPetsButton.Text = "自动宠物: " .. (autoPetsEnabled and "开" or "关")
    autoPetsButton.TextColor3 = autoPetsEnabled and Color3.new(1, 0, 1) or Color3.new(1, 0.5, 1)
    print("✅ 自动宠物: " .. (autoPetsEnabled and "已开启" or "已关闭"))
    
    if autoPetsEnabled then
        spawn(function()
            while autoPetsEnabled do
                local buyEvent = game:GetService("ReplicatedStorage")
                    :WaitForChild("GameEvents")
                    :WaitForChild("BuyPetEgg")

                for i = 1, 3 do
                    if not autoPetsEnabled then break end
                    buyEvent:FireServer(i)
                    task.wait(0.1)
                end
                
                task.wait(0.1)
            end
        end)
    end
end)

-- 移除植物部件按钮
createButton("移除植物部件", UDim2.new(0, 270, 0, 50), Color3.new(1, 0.3, 0.3), ProcessFarmWithFeedback)

-- ===================== UI拖动功能 =====================
local dragging = false 
local dragInput 
local dragStart = nil 
local startPositions = {}

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
    Text = gameName.."｜种植花园｜加载完成",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 种植花园｜提前是钱够了添加自动购买宠物，移除植物部件更好的采摘果实\n- 版本: 1.0.2\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

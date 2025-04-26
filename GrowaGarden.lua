-- 服务声明
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

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

-- 创建功能按钮
local hideButton = createButton("隐藏UI", UDim2.new(1, -130, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("关闭UI", UDim2.new(1, -130, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
    print("UI已关闭")
end)

createButton("控制台", UDim2.new(1, -130, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, "F9", false, game)
    print("已打开控制台")
end)

-- 自动购买种子功能
local autoSeedsEnabled = false
local autoSeedsButton = createButton("自动种子: 关", UDim2.new(1, -130, 0, 130), Color3.new(0.5, 1, 0.5))

autoSeedsButton.MouseButton1Click:Connect(function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsButton.Text = "自动种子: " .. (autoSeedsEnabled and "开" or "关")
    autoSeedsButton.TextColor3 = autoSeedsEnabled and Color3.new(0, 1, 0) or Color3.new(0.5, 1, 0.5)
    
    if autoSeedsEnabled then
        spawn(function()
            while autoSeedsEnabled do
                local seedTypes = {
                    "Mushroom", "Grape", "Mango", "Dragon Fruit", "Cactus",
                    "Coconut", "Bamboo", "Apple", "Pumpkin", "Watermelon",
                    "Daffodil", "Corn", "Tomato", "Orange Tulip", "Blueberry",
                    "Strawberry", "Carrot"
                }

                local buyEvent = game:GetService("ReplicatedStorage")
                    :WaitForChild("GameEvents")
                    :WaitForChild("BuySeedStock")

                for _, seed in ipairs(seedTypes) do
                    if not autoSeedsEnabled then break end  -- 如果中途关闭则停止
                    buyEvent:FireServer(seed)
                    task.wait(0.1)  -- 添加延迟防止服务器限制
                end
                
                task.wait(0.2)  -- 每0.2秒尝试购买一次
            end
        end)
    end
end)

-- 自动购买工具功能
local autoToolsEnabled = false
local autoToolsButton = createButton("自动工具: 关", UDim2.new(1, -130, 0, 170), Color3.new(0.5, 0.5, 1))

autoToolsButton.MouseButton1Click:Connect(function()
    autoToolsEnabled = not autoToolsEnabled
    autoToolsButton.Text = "自动工具: " .. (autoToolsEnabled and "开" or "关")
    autoToolsButton.TextColor3 = autoToolsEnabled and Color3.new(0, 0, 1) or Color3.new(0.5, 0.5, 1)
    
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
                    if not autoToolsEnabled then break end  -- 如果中途关闭则停止
                    buyEvent:FireServer(gear)
                    task.wait(0.1)  -- 添加延迟防止服务器限制
                end
                
                task.wait(0.2)  -- 每0.2秒尝试购买一次
            end
        end)
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
    Text = gameName.."｜种植花园｜加载完成",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n脚本名称: "..gameName.."｜种植花园\n描述: 种植花园｜脚本\n版本: 0.1.1\n作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

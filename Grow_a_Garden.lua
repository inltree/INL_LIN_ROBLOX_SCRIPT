-- 服务声明
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- 声明自动购买控制变量
local autoSeedsEnabled = false
local autoToolsEnabled = false
local autoPetsEnabled = false
local autoEventItemsEnabled = false

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

-- ===================== 获取玩家谢克尔数量 =====================
local function getPlayerSheckles()
    local shecklesUI = player.PlayerGui:FindFirstChild("Sheckles_UI")
    if shecklesUI and shecklesUI:FindFirstChild("TextLabel") then
        local shecklesText = shecklesUI.TextLabel.Text
        -- 提取数字部分 (例如: "1,234" -> 1234)
        local numericValue = string.gsub(shecklesText, "[^%d]", "")
        return tonumber(numericValue) or 0
    end
    return 0
end

-- ===================== 获取物品价格 =====================
local function getItemCost(frame)
    if frame and frame:FindFirstChild("Main_Frame") then
        local costText = frame.Main_Frame:FindFirstChild("Cost_Text")
        if costText and costText.Text ~= "NO STOCK" then
            -- 提取数字部分 (例如: "1,234" -> 1234)
            local numericValue = string.gsub(costText.Text, "[^%d]", "")
            return tonumber(numericValue) or 0
        end
    end
    return 0
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

-- ===================== 种子自动购买功能 =====================
local SEED_RARITY_ORDER = {
    ["Prismatic"] = 7,
    ["Divine"] = 6,
    ["Mythical"] = 5,
    ["Legendary"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
}

local function getSeedShopFrame()
    return Players.LocalPlayer.PlayerGui:WaitForChild("Seed_Shop"):WaitForChild("Frame"):WaitForChild("ScrollingFrame")
end

local function isSeedInStock(seedName)
    local seedFrame = getSeedShopFrame():FindFirstChild(seedName)
    if seedFrame then
        local costText = seedFrame:FindFirstChild("Main_Frame") and seedFrame.Main_Frame:FindFirstChild("Cost_Text")
        if costText and costText.Text ~= "NO STOCK" then
            local playerSheckles = getPlayerSheckles()
            local itemCost = getItemCost(seedFrame)
            return playerSheckles >= itemCost
        end
    end
    return false
end

local function getSortedSeeds()
    local seeds = {}
    local scrollingFrame = getSeedShopFrame()
    
    for _, seedFrame in ipairs(scrollingFrame:GetChildren()) do
        local rarityText = seedFrame:FindFirstChild("Main_Frame") and seedFrame.Main_Frame:FindFirstChild("Rarity_Text")
        if rarityText and isSeedInStock(seedFrame.Name) then
            table.insert(seeds, {
                name = seedFrame.Name,
                rarity = rarityText.Text,
                level = SEED_RARITY_ORDER[rarityText.Text] or 0,
                cost = getItemCost(seedFrame)
            })
        end
    end
    
    table.sort(seeds, function(a, b)
        if a.level == b.level then
            return a.cost < b.cost  -- 相同稀有度时选择更便宜的
        end
        return a.level > b.level  -- 按稀有度降序排列
    end)
    
    return seeds
end

local function purchaseSeedsSequentially(seeds, index)
    if not autoSeedsEnabled or not seeds[index] then return end
    
    -- 检查库存状态和玩家资金
    if isSeedInStock(seeds[index].name) then
        -- 发送种子购买请求
        ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(seeds[index].name)
    end
    
    -- 0.1秒后购买下一个种子
    task.delay(0.1, function()
        purchaseSeedsSequentially(seeds, index + 1)
    end)
end

local function autoPurchaseSeedsByRarity()
    while autoSeedsEnabled do
        local sortedSeeds = getSortedSeeds()
        if #sortedSeeds > 0 then
            purchaseSeedsSequentially(sortedSeeds, 1)
        end
        task.wait(0.1) -- 每次完整购买循环后等待0.1秒
    end
end

-- ===================== 工具自动购买功能 =====================
local GEARS_RARITY_ORDER = {
    ["Prismatic"] = 7,
    ["Divine"] = 6,
    ["Mythical"] = 5,
    ["Legendary"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
}

local function getGearShopFrame()
    return Players.LocalPlayer.PlayerGui:WaitForChild("Gear_Shop"):WaitForChild("Frame"):WaitForChild("ScrollingFrame")
end

local function isGearInStock(gearName)
    local gearFrame = getGearShopFrame():FindFirstChild(gearName)
    if gearFrame then
        local costText = gearFrame:FindFirstChild("Main_Frame") and gearFrame.Main_Frame:FindFirstChild("Cost_Text")
        if costText and costText.Text ~= "NO STOCK" then
            local playerSheckles = getPlayerSheckles()
            local itemCost = getItemCost(gearFrame)
            return playerSheckles >= itemCost
        end
    end
    return false
end

local function getSortedGears()
    local gears = {}
    local scrollingFrame = getGearShopFrame()
    
    for _, gearFrame in ipairs(scrollingFrame:GetChildren()) do
        local rarityText = gearFrame:FindFirstChild("Main_Frame") and gearFrame.Main_Frame:FindFirstChild("Rarity_Text")
        if rarityText and isGearInStock(gearFrame.Name) then
            table.insert(gears, {
                name = gearFrame.Name,
                rarity = rarityText.Text,
                level = GEARS_RARITY_ORDER[rarityText.Text] or 0,
                cost = getItemCost(gearFrame)
            })
        end
    end
    
    table.sort(gears, function(a, b)
        if a.level == b.level then
            return a.cost < b.cost  -- 相同稀有度时选择更便宜的
        end
        return a.level > b.level  -- 降序排列
    end)
    
    return gears
end

local function purchaseGearsSequentially(gears, index)
    if not autoToolsEnabled or not gears[index] then return end
    
    -- 检查库存状态和玩家资金
    if isGearInStock(gears[index].name) then
        -- 发送工具购买请求
        ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(gears[index].name)
    end
    
    -- 延迟后购买下一个（0.1秒间隔）
    task.delay(0.1, function()
        purchaseGearsSequentially(gears, index + 1)
    end)
end

local function autoPurchaseGearsByRarity()
    while autoToolsEnabled do
        local sortedGears = getSortedGears()
        if #sortedGears > 0 then
            purchaseGearsSequentially(sortedGears, 1)
        end
        task.wait(0.11)
    end
end

-- ===================== 活动物品自动购买功能 =====================
local EVENT_ITEMS_RARITY_ORDER = {
    ["Prismatic"] = 7,
    ["Divine"] = 6,
    ["Mythical"] = 5,
    ["Legendary"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
}

local function getEventShopFrame()
    local eventShopUI = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShopUI then
        return eventShopUI:WaitForChild("Frame"):WaitForChild("ScrollingFrame")
    end
    return nil
end

local function isEventItemInStock(itemName)
    local itemFrame = getEventShopFrame():FindFirstChild(itemName)
    if itemFrame then
        local costText = itemFrame:FindFirstChild("Main_Frame") and itemFrame.Main_Frame:FindFirstChild("Cost_Text")
        if costText and costText.Text ~= "NO STOCK" then
            local playerSheckles = getPlayerSheckles()
            local itemCost = getItemCost(itemFrame)
            return playerSheckles >= itemCost
        end
    end
    return false
end

local function getSortedEventItems()
    local eventItems = {}
    local scrollingFrame = getEventShopFrame()
    
    if scrollingFrame then
        for _, itemFrame in ipairs(scrollingFrame:GetChildren()) do
            local rarityText = itemFrame:FindFirstChild("Main_Frame") and itemFrame.Main_Frame:FindFirstChild("Rarity_Text")
            if rarityText and isEventItemInStock(itemFrame.Name) then
                table.insert(eventItems, {
                    name = itemFrame.Name,
                    rarity = rarityText.Text,
                    level = EVENT_ITEMS_RARITY_ORDER[rarityText.Text] or 0,
                    cost = getItemCost(itemFrame)
                })
            end
        end
        
        table.sort(eventItems, function(a, b)
            if a.level == b.level then
                return a.cost < b.cost  -- 相同稀有度时选择更便宜的
            end
            return a.level > b.level  -- 降序排列
        end)
    end
    
    return eventItems
end

local function purchaseEventItemsSequentially(items, index)
    if not autoEventItemsEnabled or not items[index] then return end
    
    -- 检查库存状态和玩家资金
    if isEventItemInStock(items[index].name) then
        -- 发送活动物品购买请求
        local args = {
            items[index].name
        }
        ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(unpack(args))
    end
    
    -- 延迟后购买下一个（0.1秒间隔）
    task.delay(0.1, function()
        purchaseEventItemsSequentially(items, index + 1)
    end)
end

local function autoPurchaseEventItemsByRarity()
    while autoEventItemsEnabled do
        local sortedItems = getSortedEventItems()
        if #sortedItems > 0 then
            purchaseEventItemsSequentially(sortedItems, 1)
        end
        task.wait(0.11)
    end
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
createButton("工具商店传送", UDim2.new(0, 270, 0, 10), Color3.new(0, 1, 1), function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = workspace.Tutorial_Points.Tutorial_Point_3.CFrame
        print("✅ 工具商店传送: 已点击")
    end
end)

-- 自动种子功能
local autoSeedsButton = createButton("自动种子: 关", UDim2.new(0, 140, 0, 10), Color3.new(0.5, 1, 0.5))

autoSeedsButton.MouseButton1Click:Connect(function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsButton.Text = "自动种子: " .. (autoSeedsEnabled and "开" or "关")
    autoSeedsButton.TextColor3 = autoSeedsEnabled and Color3.new(0, 1, 0) or Color3.new(0.5, 1, 0.5)
    print("✅ 自动种子: " .. (autoSeedsEnabled and "已开启" or "已关闭"))
    
    if autoSeedsEnabled then
        spawn(autoPurchaseSeedsByRarity)
    end
end)

-- 自动工具功能
local autoToolsButton = createButton("自动工具: 关", UDim2.new(0, 140, 0, 50), Color3.new(0.5, 0.5, 1))

autoToolsButton.MouseButton1Click:Connect(function()
    autoToolsEnabled = not autoToolsEnabled
    autoToolsButton.Text = "自动工具: " .. (autoToolsEnabled and "开" or "关")
    autoToolsButton.TextColor3 = autoToolsEnabled and Color3.new(0, 0, 1) or Color3.new(0.5, 0.5, 1)
    print("✅ 自动工具: " .. (autoToolsEnabled and "已开启" or "已关闭"))
    
    if autoToolsEnabled then
        spawn(autoPurchaseGearsByRarity)
    end
end)

-- 自动宠物功能
local autoPetsButton = createButton("自动宠物: 关", UDim2.new(0, 140, 0, 90), Color3.new(1, 0.5, 1))

autoPetsButton.MouseButton1Click:Connect(function()
    autoPetsEnabled = not autoPetsEnabled
    autoPetsButton.Text = "自动宠物: " .. (autoPetsEnabled and "开" or "关")
    autoPetsButton.TextColor3 = autoPetsEnabled and Color3.new(1, 0, 1) or Color3.new(1, 0.5, 1)
    print("✅ 自动宠物: " .. (autoPetsEnabled and "已开启" or "已关闭"))
    
    if autoPetsEnabled then
        spawn(function()
            while autoPetsEnabled do
                local buyEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyPetEgg")

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

-- 自动活动物品功能
local autoEventItemsButton = createButton("自动活动物品: 关", UDim2.new(0, 140, 0, 130), Color3.new(1, 0.8, 0.4))

autoEventItemsButton.MouseButton1Click:Connect(function()
    autoEventItemsEnabled = not autoEventItemsEnabled
    autoEventItemsButton.Text = "自动活动物品: " .. (autoEventItemsEnabled and "开" or "关")
    autoEventItemsButton.TextColor3 = autoEventItemsEnabled and Color3.new(1, 0.6, 0) or Color3.new(1, 0.8, 0.4)
    print("✅ 自动活动物品: " .. (autoEventItemsEnabled and "已开启" or "已关闭"))
    
    if autoEventItemsEnabled then
        spawn(autoPurchaseEventItemsByRarity)
    end
end)

-- 移除植物部件按钮
createButton("移除植物部件", UDim2.new(0, 270, 0, 50), Color3.new(1, 0.3, 0.3), ProcessFarmWithFeedback)

-- 界面获取按钮
createButton("种子界面", UDim2.new(0, 270, 0, 90), Color3.new(0.5, 1, 0.5), function()
    local seedShop = player.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShop then
        seedShop.Enabled = not seedShop.Enabled
        print("✅ 种子界面: " .. (seedShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("工具界面", UDim2.new(0, 270, 0, 130), Color3.new(0.5, 0.5, 1), function()
    local gearShop = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gearShop then
        gearShop.Enabled = not gearShop.Enabled
        print("✅ 工具界面: " .. (gearShop.Enabled and "已开启" or "已关闭"))
    end
end)

-- 装饰品界面按钮
createButton("装饰品界面", UDim2.new(0, 270, 0, 170), Color3.new(0.4, 1, 0.8), function()
    local cosmeticShopUI = player.PlayerGui:FindFirstChild("CosmeticShop_UI")
    if cosmeticShopUI then
        cosmeticShopUI.Enabled = not cosmeticShopUI.Enabled
        print("✅ 装饰品界面: " .. (cosmeticShopUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("任务界面", UDim2.new(0, 270, 0, 210), Color3.new(1, 0.5, 0.5), function()
    local dailyQuestsUI = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if dailyQuestsUI then
        dailyQuestsUI.Enabled = not dailyQuestsUI.Enabled
        print("✅ 任务界面: " .. (dailyQuestsUI.Enabled and "已开启" or "已关闭"))
    end
end)

-- 启动包界面按钮
createButton("启动包界面", UDim2.new(0, 400, 0, 10), Color3.new(0.8, 0.4, 1), function()
    local starterPackUI = player.PlayerGui:FindFirstChild("StarterPack_UI")
    if starterPackUI then
        starterPackUI.Enabled = not starterPackUI.Enabled
        print("✅ 启动包界面: " .. (starterPackUI.Enabled and "已开启" or "已关闭"))
    end
end)

-- 活动商店界面按钮
createButton("活动商店界面", UDim2.new(0, 400, 0, 50), Color3.new(1, 1, 0), function()
    local eventShop = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShop then
        eventShop.Enabled = not eventShop.Enabled
        print("✅ 活动商店界面: " .. (eventShop.Enabled and "已开启" or "已关闭"))
    end
end)

-- 蜂蜜商店界面按钮
createButton("蜂蜜商店界面", UDim2.new(0, 400, 0, 90), Color3.new(1, 0.8, 0.4), function()
    local honeyEventShopUI = player.PlayerGui:FindFirstChild("HoneyEventShop_UI")
    if honeyEventShopUI then
        honeyEventShopUI.Enabled = not honeyEventShopUI.Enabled
        print("✅ 蜂蜜商店界面: " .. (honeyEventShopUI.Enabled and "已开启" or "已关闭"))
    end
end)

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

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 种植花园｜添加自动购买宠物，移除植物部件、打开商店界面和优化自动购买种子和工具\n- 版本: 1.0.7\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

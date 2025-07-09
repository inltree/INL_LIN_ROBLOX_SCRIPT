-- 服务声明
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- 声明自动购买控制变量
local autoSeedsEnabled = false
local autoGearEnabled = false
local autoPetsEnabled = false
local autoEventItemsEnabled = false
local autoTravelMerchantEnabled = false
local autoCosmeticsEnabled = false
-- 隐藏植物部件控制变量
local isFarmPartsHidden = false
local FarmHiddenObjects = {}

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

-- ===================== 隐藏/恢复植物部件功能 =====================
local function HideFarmParentObjectsWithoutPrompt(FarmModel)
    for _, FarmParentObj in ipairs(FarmModel:GetChildren()) do
        if FarmParentObj:IsA("Part") or FarmParentObj:IsA("MeshPart") then
            local HasFarmPrompt = FarmParentObj:FindFirstChildOfClass("ProximityPrompt")
            
            if not HasFarmPrompt and not FarmHiddenObjects[FarmParentObj] then
                FarmHiddenObjects[FarmParentObj] = {
                    Transparency = FarmParentObj.Transparency,
                    CanCollide = FarmParentObj.CanCollide
                }
                FarmParentObj.Transparency = 1
                FarmParentObj.CanCollide = false
            end
        end
    end
end

local function RestoreFarmHiddenObjects()
    for FarmObj, OriginalFarmState in pairs(FarmHiddenObjects) do
        if FarmObj and FarmObj.Parent then
            FarmObj.Transparency = OriginalFarmState.Transparency
            FarmObj.CanCollide = OriginalFarmState.CanCollide
        end
    end
    FarmHiddenObjects = {}
end

local function ProcessAllFarmLayers(FarmParent)
    for _, FarmChild in ipairs(FarmParent:GetChildren()) do
        if FarmChild.Name == "Farm" then
            local FarmImportant = FarmChild:FindFirstChild("Important")
            local FarmPlants = FarmImportant and FarmImportant:FindFirstChild("Plants_Physical")
            
            if FarmPlants then
                for _, FarmModel in ipairs(FarmPlants:GetChildren()) do
                    if FarmModel:IsA("Model") then
                        HideFarmParentObjectsWithoutPrompt(FarmModel)
                    end
                end
            end
            
            ProcessAllFarmLayers(FarmChild)
        end
    end
end

-- ===================== 自动种子商店 =====================
local function autoPurchaseSeeds()
    while autoSeedsEnabled do
        local AutoSeedShop = player.PlayerGui:WaitForChild("Seed_Shop").Frame:WaitForChild("ScrollingFrame")
        local BuySeedEvent = ReplicatedStorage.GameEvents:WaitForChild("BuySeedStock")
        
        for _, SeedItem in ipairs(AutoSeedShop:GetChildren()) do
            if autoSeedsEnabled then
                BuySeedEvent:FireServer(SeedItem.Name)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 自动装备商店 =====================
local function autoPurchaseGears()
    while autoGearEnabled do
        local AutoGearShop = player.PlayerGui:WaitForChild("Gear_Shop").Frame:WaitForChild("ScrollingFrame")
        local BuyGearEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyGearStock")
        
        for _, GearItem in ipairs(AutoGearShop:GetChildren()) do
            if autoGearEnabled then
                BuyGearEvent:FireServer(GearItem.Name)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 自动蛋商店 =====================
local function autoPurchasePets()
    while autoPetsEnabled do
        local AutoPetEggShopEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
        
        for PetEggItem = 1, 3 do
            if autoPetsEnabled then
                AutoPetEggShopEvent:FireServer(PetEggItem)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 自动旅行商店 =====================
local function autoPurchaseTravelMerchant()
    while autoTravelMerchantEnabled do
        local AutoTravelingMerchantShop = player.PlayerGui:WaitForChild("TravelingMerchantShop_UI").Frame:WaitForChild("ScrollingFrame")
        local BuyTravelingMerchantItem = ReplicatedStorage.GameEvents:WaitForChild("BuyTravelingMerchantShopStock")
        
        for _, TravelingMerchantItem in ipairs(AutoTravelingMerchantShop:GetChildren()) do
            if autoTravelMerchantEnabled then
                BuyTravelingMerchantItem:FireServer(TravelingMerchantItem.Name)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 自动装饰品商店 =====================
local function autoPurchaseCosmetics()
    while autoCosmeticsEnabled do
        local AutoCosmeticShop = player.PlayerGui:WaitForChild("CosmeticShop_UI"):WaitForChild("CosmeticShop"):WaitForChild("Main"):WaitForChild("Holder"):WaitForChild("Shop"):WaitForChild("ContentFrame")
        local topSegment = AutoCosmeticShop:WaitForChild("TopSegment")
        local bottomSegment = AutoCosmeticShop:WaitForChild("BottomSegment")
        local buyCosmeticCrateEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyCosmeticCrate")
        
        for _, CosmeticItem in ipairs(topSegment:GetChildren()) do
            if autoCosmeticsEnabled then
                buyCosmeticCrateEvent:FireServer(CosmeticItem.Name)
            end
        end
        
        for _, CosmeticItem in ipairs(bottomSegment:GetChildren()) do
            if autoCosmeticsEnabled then
                buyCosmeticCrateEvent:FireServer(CosmeticItem.Name)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 自动活动商店 =====================
local function autoPurchaseEventItems()
    while autoEventItemsEnabled do
        local AutoEventShop = player.PlayerGui:WaitForChild("EventShop_UI").Frame:WaitForChild("ScrollingFrame")
        local BuyEventEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyEventShopStock")
        
        for _, EventItem in ipairs(AutoEventShop:GetChildren()) do
            if autoEventItemsEnabled then
                BuyEventEvent:FireServer(EventItem.Name)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 创建按钮 =====================
local hideButton = createButton("隐藏UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0))
local isHidden = false

createButton("关闭UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
    print("🔴 "..gameName.." - 面板: 已关闭")
end)

createButton("控制台", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
    print("🟢 控制台: 已开启")
end)

-- 自动种子功能（绿色系：种子/植物关联）
local autoSeedsButton = createButton("自动种子: 关", UDim2.new(0, 140, 0, 10), Color3.new(0.3, 0.8, 0.3))

autoSeedsButton.MouseButton1Click:Connect(function()
    autoSeedsEnabled = not autoSeedsEnabled
    autoSeedsButton.Text = "自动种子: " .. (autoSeedsEnabled and "开" or "关")
    autoSeedsButton.TextColor3 = autoSeedsEnabled and Color3.new(0, 1, 0) or Color3.new(0.3, 0.8, 0.3)
    print("🟢 自动种子: " .. (autoSeedsEnabled and "已开启" or "已关闭"))
    
    if autoSeedsEnabled then
        spawn(autoPurchaseSeeds)
    end
end)

-- 自动工具功能（蓝色系：工具/装备关联）
local autoToolsButton = createButton("自动工具: 关", UDim2.new(0, 140, 0, 50), Color3.new(0.3, 0.6, 0.9))

autoToolsButton.MouseButton1Click:Connect(function()
    autoGearEnabled = not autoGearEnabled
    autoToolsButton.Text = "自动工具: " .. (autoGearEnabled and "开" or "关")
    autoToolsButton.TextColor3 = autoGearEnabled and Color3.new(0, 0.4, 1) or Color3.new(0.3, 0.6, 0.9)
    print("🟢 自动工具: " .. (autoGearEnabled and "已开启" or "已关闭"))
    
    if autoGearEnabled then
        spawn(autoPurchaseGears)
    end
end)

-- 自动宠物功能（粉色系：宠物/伙伴关联）
local autoPetsButton = createButton("自动宠物: 关", UDim2.new(0, 140, 0, 90), Color3.new(0.9, 0.5, 0.8))

autoPetsButton.MouseButton1Click:Connect(function()
    autoPetsEnabled = not autoPetsEnabled
    autoPetsButton.Text = "自动宠物: " .. (autoPetsEnabled and "开" or "关")
    autoPetsButton.TextColor3 = autoPetsEnabled and Color3.new(0.8, 0.2, 0.7) or Color3.new(0.9, 0.5, 0.8)
    print("🟢 自动宠物: " .. (autoPetsEnabled and "已开启" or "已关闭"))
    
    if autoPetsEnabled then
        spawn(autoPurchasePets)
    end
end)

-- 自动旅行商人功能（紫色系：特殊商人关联）
local autoTravelMerchantButton = createButton("自动旅行商人: 关", UDim2.new(0, 140, 0, 130), Color3.new(0.7, 0.4, 0.9))

autoTravelMerchantButton.MouseButton1Click:Connect(function()
    autoTravelMerchantEnabled = not autoTravelMerchantEnabled
    autoTravelMerchantButton.Text = "自动旅行商人: " .. (autoTravelMerchantEnabled and "开" or "关")
    autoTravelMerchantButton.TextColor3 = autoTravelMerchantEnabled and Color3.new(0.6, 0.2, 0.8) or Color3.new(0.7, 0.4, 0.9)
    print("🟢 自动旅行商人: " .. (autoTravelMerchantEnabled and "已开启" or "已关闭"))
    
    if autoTravelMerchantEnabled then
        spawn(autoPurchaseTravelMerchant)
    end
end)

-- 自动装饰品功能（青色系：装饰/外观关联）
local autoCosmeticsButton = createButton("自动装饰品: 关", UDim2.new(0, 140, 0, 170), Color3.new(0.4, 0.9, 0.8))

autoCosmeticsButton.MouseButton1Click:Connect(function()
    autoCosmeticsEnabled = not autoCosmeticsEnabled
    autoCosmeticsButton.Text = "自动装饰品: " .. (autoCosmeticsEnabled and "开" or "关")
    autoCosmeticsButton.TextColor3 = autoCosmeticsEnabled and Color3.new(0.2, 0.8, 0.7) or Color3.new(0.4, 0.9, 0.8)
    print("🟢 自动装饰品: " .. (autoCosmeticsEnabled and "已开启" or "已关闭"))
    
    if autoCosmeticsEnabled then
        spawn(autoPurchaseCosmetics)
    end
end)

-- 自动活动物品功能按钮（橙色系：活动/限时关联）
local autoEventItemsButton = createButton("自动活动物品: 关", UDim2.new(0, 140, 0, 210), Color3.new(0.9, 0.6, 0.3))

autoEventItemsButton.MouseButton1Click:Connect(function()
    autoEventItemsEnabled = not autoEventItemsEnabled
    autoEventItemsButton.Text = "自动活动物品: " .. (autoEventItemsEnabled and "开" or "关")
    autoEventItemsButton.TextColor3 = autoEventItemsEnabled and Color3.new(0.8, 0.5, 0) or Color3.new(0.9, 0.6, 0.3)
    print("🟢 自动活动物品: " .. (autoEventItemsEnabled and "已开启" or "已关闭"))
    
    if autoEventItemsEnabled then
        spawn(autoPurchaseEventItems)
    end
end)

-- 隐藏/显示植物部件按钮（深绿系：与种子功能同属植物相关）
local farmPartsButton = createButton("隐藏植物部件: 关", UDim2.new(0, 270, 0, 10), Color3.new(0.2, 0.7, 0.2))

farmPartsButton.MouseButton1Click:Connect(function()
    isFarmPartsHidden = not isFarmPartsHidden
    farmPartsButton.Text = "隐藏植物部件: " .. (isFarmPartsHidden and "开" or "关")
    farmPartsButton.TextColor3 = isFarmPartsHidden and Color3.new(0, 1, 0) or Color3.new(0.2, 0.7, 0.2)
    print("🟢 植物部件: " .. (isFarmPartsHidden and "已开启" or "已关闭"))
    
    if isFarmPartsHidden then
        ProcessAllFarmLayers(workspace)
    else
        RestoreFarmHiddenObjects()
    end
end)

-- 界面按钮（与对应自动功能同色系）
createButton("种子界面", UDim2.new(0, 270, 0, 50), Color3.new(0.3, 0.8, 0.3), function()
    local seedShop = player.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShop then
        seedShop.Enabled = not seedShop.Enabled
        print("🟢 种子界面: " .. (seedShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("工具界面", UDim2.new(0, 270, 0, 90), Color3.new(0.3, 0.6, 0.9), function()
    local gearShop = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gearShop then
        gearShop.Enabled = not gearShop.Enabled
        print("🟢 工具界面: " .. (gearShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("装饰品界面", UDim2.new(0, 270, 0, 130), Color3.new(0.4, 0.9, 0.8), function()
    local cosmeticShopUI = player.PlayerGui:FindFirstChild("CosmeticShop_UI")
    if cosmeticShopUI then
        cosmeticShopUI.Enabled = not cosmeticShopUI.Enabled
        print("🟢 装饰品界面: " .. (cosmeticShopUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("任务界面", UDim2.new(0, 270, 0, 170), Color3.new(0.8, 0.5, 0.5), function()  -- 红色系：任务/成就关联
    local dailyQuestsUI = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if dailyQuestsUI then
        dailyQuestsUI.Enabled = not dailyQuestsUI.Enabled
        print("🟢 任务界面: " .. (dailyQuestsUI.Enabled and "已开启" or "已关闭"))
    end
end)

-- 动态界面（与对应功能同色系）
createButton("启动包界面", UDim2.new(0, 400, 0, 10), Color3.new(0.9, 0.7, 0.9), function()  -- 浅紫：特殊礼包关联
    local starterPackUI = player.PlayerGui:FindFirstChild("StarterPack_UI")
    if starterPackUI then
        starterPackUI.Enabled = not starterPackUI.Enabled
        print("🟢 启动包界面: " .. (starterPackUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("活动商店界面", UDim2.new(0, 400, 0, 50), Color3.new(0.9, 0.6, 0.3), function()  -- 橙色：与活动物品同系
    local eventShop = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShop then
        eventShop.Enabled = not eventShop.Enabled
        print("🟢 活动商店界面: " .. (eventShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("旅行商人界面", UDim2.new(0, 400, 0, 90), Color3.new(0.7, 0.4, 0.9), function()  -- 紫色：与旅行商人同系
    local travelingMerchantUI = player.PlayerGui:FindFirstChild("TravelingMerchantShop_UI")
    if travelingMerchantUI then
        travelingMerchantUI.Enabled = not travelingMerchantUI.Enabled
        print("🟢 旅行商人界面: " .. (travelingMerchantUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("恐龙任务界面", UDim2.new(0, 400, 0, 130), Color3.new(0.8, 0.5, 0.5), function()  -- 红色系：与任务系统同系
    local dinoQuestsUI = player.PlayerGui:FindFirstChild("DinoQuests_UI")
    if dinoQuestsUI then
        dinoQuestsUI.Enabled = not dinoQuestsUI.Enabled
        print("🟢 恐龙任务界面: " .. (dinoQuestsUI.Enabled and "已开启" or "已关闭"))
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
    print("🟢 隐藏状态:", isHidden and "已关闭" or "已开启")
end)

-- 隐藏传送按钮显示
for _, btn in ipairs(game.Players.LocalPlayer.PlayerGui.Teleport_UI.Frame:GetChildren()) do
    if btn:IsA("ImageButton") then btn.Visible = true end
end

-- 加载完成通知
task.wait(0.5)
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = gameName.."｜种植花园｜加载完成",
    Duration = 3
})

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 种植花园｜重构部分内容新增部分内容\n- 版本: 1.1.0\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

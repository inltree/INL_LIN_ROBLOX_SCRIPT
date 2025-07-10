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
-- 隐藏作物部件控制变量
-- local isFruitsHidden = false
-- local FruitHiddenObjects = {}
local isCropPartsHidden = false
local CropHiddenObjects = {}

-- 创建UI界面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "inltree_Lin_UniversalUI"
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
    TextSize = 16,
    BorderSizePixel = 1,
    BorderColor3 = Color3.new(0.8, 0.8, 0.8)
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
    button.BorderSizePixel = buttonStyle.BorderSizePixel
    button.BorderColor3 = buttonStyle.BorderColor3
    button.Parent = screenGui
    
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- ===================== 隐藏/恢复果实部件 =====================
-- 太难了哪位大神帮帮我qwq


-- ===================== 隐藏/恢复作物部件功能 =====================
local function HideCropParentObjectsWithoutPrompt(CropModel)
    for _, CropParentObj in ipairs(CropModel:GetChildren()) do
        if CropParentObj:IsA("Part") or CropParentObj:IsA("MeshPart") then
            local HasCropPrompt = CropParentObj:FindFirstChildOfClass("ProximityPrompt")
            
            if not HasCropPrompt and not CropHiddenObjects[CropParentObj] then
                CropHiddenObjects[CropParentObj] = {
                    Transparency = CropParentObj.Transparency,
                    CanCollide = CropParentObj.CanCollide
                }
                CropParentObj.Transparency = 1
                CropParentObj.CanCollide = false
            end
        end
    end
end

local function RestoreCropHiddenObjects()
    for CropObj, OriginalCropState in pairs(CropHiddenObjects) do
        if CropObj and CropObj.Parent then
            CropObj.Transparency = OriginalCropState.Transparency
            CropObj.CanCollide = OriginalCropState.CanCollide
        end
    end
    CropHiddenObjects = {}
end

local function ProcessAllCropLayers(CropParent)
    for _, CropChild in ipairs(CropParent:GetChildren()) do
        if CropChild.Name == "Farm" then
            local CropImportant = CropChild:FindFirstChild("Important")
            local CropPlants = CropImportant and CropImportant:FindFirstChild("Plants_Physical")
            
            if CropPlants then
                for _, CropModel in ipairs(CropPlants:GetChildren()) do
                    if CropModel:IsA("Model") then
                        HideCropParentObjectsWithoutPrompt(CropModel)
                    end
                end
            end
            
            ProcessAllCropLayers(CropChild)
        end
    end
end

-- ===================== 自动种子商店 =====================
local function autoPurchaseSeeds()
    while autoSeedsEnabled do
        local seedShop = player.PlayerGui:WaitForChild("Seed_Shop")
        local frame = seedShop:WaitForChild("Frame")
        local scroller = frame:WaitForChild("ScrollingFrame")
        local seedItems = scroller:GetChildren()
        
        local buySeedEvent = ReplicatedStorage.GameEvents:WaitForChild("BuySeedStock")
        for _, item in ipairs(seedItems) do
            if not autoSeedsEnabled then break end
            buySeedEvent:FireServer(item.Name)
            task.wait(0.01)
        end
        task.wait(0.1)
    end
end

-- ===================== 自动装备商店 =====================
local function autoPurchaseGears()
    while autoGearEnabled do
        local gearShop = player.PlayerGui:WaitForChild("Gear_Shop")
        local frame = gearShop:WaitForChild("Frame")
        local scroller = frame:WaitForChild("ScrollingFrame")
        local gearItems = scroller:GetChildren()
        
        local buyGearEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyGearStock")
        for _, item in ipairs(gearItems) do
            if not autoGearEnabled then break end
            buyGearEvent:FireServer(item.Name)
            task.wait(0.01)
        end
        task.wait(0.1)
    end
end

-- ===================== 自动蛋商店 =====================
local function autoPurchasePets()
    while autoPetsEnabled do
        local buyPetEggEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
        for i = 1, 3 do
            if not autoPetsEnabled then break end
            buyPetEggEvent:FireServer(i)
            task.wait(0.01)
        end
        task.wait(0.1)
    end
end

-- ===================== 自动旅行商店 =====================
local function autoPurchaseTravelMerchant()
    while autoTravelMerchantEnabled do
        local merchantShop = player.PlayerGui:WaitForChild("TravelingMerchantShop_UI")
        local frame = merchantShop:WaitForChild("Frame")
        local scroller = frame:WaitForChild("ScrollingFrame")
        local merchantItems = scroller:GetChildren()
        
        local buyTravelingMerchantEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyTravelingMerchantShopStock")
        for _, item in ipairs(merchantItems) do
            if not autoTravelMerchantEnabled then break end
            buyTravelingMerchantEvent:FireServer(item.Name)
            task.wait(0.01)
        end
        task.wait(0.1)
    end
end

-- ===================== 自动装饰品商店 =====================
local function autoPurchaseCosmetics()
    while autoCosmeticsEnabled do
        local cosmeticShop = player.PlayerGui:WaitForChild("CosmeticShop_UI")
        local main = cosmeticShop:WaitForChild("CosmeticShop"):WaitForChild("Main")
        local holder = main:WaitForChild("Holder")
        local shop = holder:WaitForChild("Shop")
        local content = shop:WaitForChild("ContentFrame")
        local segments = {
            content:WaitForChild("TopSegment"):GetChildren(),
            content:WaitForChild("BottomSegment"):GetChildren()
        }
        
        local buyCosmeticCrateEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyCosmeticCrate")
        local buyCosmeticItemEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyCosmeticItem")
        
        for _, segment in ipairs(segments) do
            for _, item in ipairs(segment) do
                if not autoCosmeticsEnabled then break end
                
                buyCosmeticCrateEvent:FireServer(item.Name)
                -- buyCosmeticItemEvent:FireServer(item.Name)
                task.wait(0.01)
            end
        end
        task.wait(0.1)
    end
end

-- ===================== 自动活动商店 =====================
local function autoPurchaseEventItems()
    while autoEventItemsEnabled do
        local eventShop = player.PlayerGui:WaitForChild("EventShop_UI")
        local frame = eventShop:WaitForChild("Frame")
        local scroller = frame:WaitForChild("ScrollingFrame")
        local eventItems = scroller:GetChildren()
        
        local buyEventEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyEventShopStock")
        for _, item in ipairs(eventItems) do
            if not autoEventItemsEnabled then break end
            buyEventEvent:FireServer(item.Name)
            task.wait(0.01)
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

-- 自动种子功能
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

-- 自动装备功能
local autoToolsButton = createButton("自动装备: 关", UDim2.new(0, 140, 0, 50), Color3.new(0.3, 0.6, 0.9))

autoToolsButton.MouseButton1Click:Connect(function()
    autoGearEnabled = not autoGearEnabled
    autoToolsButton.Text = "自动装备: " .. (autoGearEnabled and "开" or "关")
    autoToolsButton.TextColor3 = autoGearEnabled and Color3.new(0, 0.4, 1) or Color3.new(0.3, 0.6, 0.9)
    print("🟢 自动装备: " .. (autoGearEnabled and "已开启" or "已关闭"))
    
    if autoGearEnabled then
        spawn(autoPurchaseGears)
    end
end)

-- 自动宠物功能
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

-- 自动旅行商人功能
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

-- 自动装饰品功能
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

-- 自动活动物品功能按钮
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

-- 隐藏果实部件按钮（深绿系：与植物功能关联）
-- local hideFruitsButton = createButton("隐藏果实部件: 关", UDim2.new(0, 270, 0, 210), Color3.new(0.2, 0.6, 0.2))

-- hideFruitsButton.MouseButton1Click:Connect(function()
    -- isFruitsHidden = not isFruitsHidden
    -- hideFruitsButton.Text = "隐藏果实部件: " .. (isFruitsHidden and "开" or "关")
    -- hideFruitsButton.TextColor3 = isFruitsHidden and Color3.new(0, 1, 0) or Color3.new(0.2, 0.6, 0.2)
    -- print("🟢 果实部件: " .. (isFruitsHidden and "已开启" or "已关闭"))
    
    -- if isFruitsHidden then
        -- ProcessAllFruitLayers(workspace)
    -- else
        -- RestoreFruitHiddenObjects()
    -- end
-- end)

-- 隐藏/显示植物部件按钮
local farmPartsButton = createButton("隐藏植物部件: 关", UDim2.new(0, 270, 0, 10), Color3.new(0.2, 0.7, 0.2))

farmPartsButton.MouseButton1Click:Connect(function()
    isCropPartsHidden = not isCropPartsHidden
    farmPartsButton.Text = "隐藏植物部件: " .. (isCropPartsHidden and "开" or "关")
    farmPartsButton.TextColor3 = isCropPartsHidden and Color3.new(0, 1, 0) or Color3.new(0.2, 0.7, 0.2)
    print("🟢 植物部件: " .. (isCropPartsHidden and "已开启" or "已关闭"))
    
    if isCropPartsHidden then
        ProcessAllCropLayers(workspace)
    else
        RestoreCropHiddenObjects()
    end
end)

-- 界面按钮
createButton("种子界面", UDim2.new(0, 270, 0, 50), Color3.new(0.3, 0.8, 0.3), function()
    local seedShop = player.PlayerGui:FindFirstChild("Seed_Shop")
    if seedShop then
        seedShop.Enabled = not seedShop.Enabled
        print("🟢 种子界面: " .. (seedShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("装备界面", UDim2.new(0, 270, 0, 90), Color3.new(0.3, 0.6, 0.9), function()
    local gearShop = player.PlayerGui:FindFirstChild("Gear_Shop")
    if gearShop then
        gearShop.Enabled = not gearShop.Enabled
        print("🟢 装备界面: " .. (gearShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("装饰品界面", UDim2.new(0, 270, 0, 130), Color3.new(0.4, 0.9, 0.8), function()
    local cosmeticShopUI = player.PlayerGui:FindFirstChild("CosmeticShop_UI")
    if cosmeticShopUI then
        cosmeticShopUI.Enabled = not cosmeticShopUI.Enabled
        print("🟢 装饰品界面: " .. (cosmeticShopUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("任务界面", UDim2.new(0, 270, 0, 170), Color3.new(0.8, 0.5, 0.5), function()
    local dailyQuestsUI = player.PlayerGui:FindFirstChild("DailyQuests_UI")
    if dailyQuestsUI then
        dailyQuestsUI.Enabled = not dailyQuestsUI.Enabled
        print("🟢 任务界面: " .. (dailyQuestsUI.Enabled and "已开启" or "已关闭"))
    end
end)

-- 动态界面
createButton("启动包界面", UDim2.new(0, 400, 0, 10), Color3.new(0.9, 0.7, 0.9), function()
    local starterPackUI = player.PlayerGui:FindFirstChild("StarterPack_UI")
    if starterPackUI then
        starterPackUI.Enabled = not starterPackUI.Enabled
        print("🟢 启动包界面: " .. (starterPackUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("活动商店界面", UDim2.new(0, 400, 0, 50), Color3.new(0.9, 0.6, 0.3), function()
    local eventShop = player.PlayerGui:FindFirstChild("EventShop_UI")
    if eventShop then
        eventShop.Enabled = not eventShop.Enabled
        print("🟢 活动商店界面: " .. (eventShop.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("旅行商人界面", UDim2.new(0, 400, 0, 90), Color3.new(0.7, 0.4, 0.9), function()
    local travelingMerchantUI = player.PlayerGui:FindFirstChild("TravelingMerchantShop_UI")
    if travelingMerchantUI then
        travelingMerchantUI.Enabled = not travelingMerchantUI.Enabled
        print("🟢 旅行商人界面: " .. (travelingMerchantUI.Enabled and "已开启" or "已关闭"))
    end
end)

createButton("恐龙任务界面", UDim2.new(0, 400, 0, 130), Color3.new(0.8, 0.5, 0.5), function()
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

warn("\n"..(("="):rep(40).."\n- 脚本名称: "..gameName.."\n- 描述: 种植花园｜重构部分内容新增部分内容\n- 版本: 1.1.1\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))

--[[
   Natural Disaster Survival v1.0
   作者: inltree｜Lin × GPT-5
]]

-- 服务声明
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

-- UI根界面
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "inltree_Lin_UniversalUI"
screenGui.Parent = PlayerGui

-- 载入提示
StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = "inltree｜"..gameName.." Script Loading...",
    Duration = 3
})

-- 按钮样式
local buttonStyle = {
    Size = UDim2.new(0, 120, 0, 32),
    BackgroundColor3 = Color3.fromRGB(45,45,45),
    BackgroundTransparency = 0.35,
    Font = Enum.Font.SourceSansBold,
    TextSize = 16,
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(200,200,200)
}

local function notify(msg)
    StarterGui:SetCore("SendNotification", {
        Title = gameName,
        Text = tostring(msg),
        Duration = 1
    })
end

-- 创建普通按钮
local function createButton(name, position, color, callback)
    local button = Instance.new("TextButton")
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

-- 创建可开关按钮
local function createToggleButton(name, position, baseColor)
    local state = false
    local btn = createButton(name, position, baseColor)
    local offColor = Color3.fromRGB(45, 45, 45)
    local onColor = Color3.fromRGB(150, 255, 150) -- 开启时背景变绿，可自行更换颜色

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and onColor or offColor
        print("🟢", name, "状态:", state)
        notify(name.." : "..tostring(state))
    end)
    return btn, function() return state end
end

-- 无坠落伤害
local noFall = false
local noFallConnection = nil
local function startNoFall(character)
    if noFallConnection then
        noFallConnection:Disconnect()
        noFallConnection = nil
    end
    local hrp = character:WaitForChild("HumanoidRootPart")
    if not hrp then return end
    noFallConnection = RunService.Heartbeat:Connect(function()
        if noFall and hrp and hrp.Parent then
            local v = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.zero
            RunService.RenderStepped:Wait()
            hrp.AssemblyLinearVelocity = v
        end
    end)
end

-- 自动胜利
local autoWin = false
local autoWinConnection = nil
local winPos = Vector3.new(-280.551, 166.5, 341.019)
local function setupAutoWin()
    if autoWinConnection then
        autoWinConnection:Disconnect()
        autoWinConnection = nil
    end
    autoWinConnection = RunService.Heartbeat:Connect(function()
        if autoWin and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then 
                hrp.CFrame = CFrame.new(winPos) 
            end
        end
    end)
end

-- 火箭发射
local function launchRocket()
    local successCount = 0
    local totalCount = 0
    local function tryFireClickDetector(objectPath)
        totalCount = totalCount + 1
        pcall(function()
            local object = objectPath
            if object and object:FindFirstChild("ClickDetector") then
                fireclickdetector(object.ClickDetector)
                successCount = successCount + 1
            end
        end)
    end
    tryFireClickDetector(Workspace.Structure["Launch Land"]["SPACESHIP!!"].Shuttle.IgnitionButton)
    tryFireClickDetector(Workspace.Structure["Launch Land"].RocketStand.ConsoleLower.ReleaseButtonLower)
    tryFireClickDetector(Workspace.Structure["Launch Land"].RocketStand.ConsoleUpper.ReleaseButtonUpper)
    tryFireClickDetector(Workspace.Structure["Launch Land"].LoadingTower.Console.ReleaseEntryBridge)
end

-- 灾害检测系统
local disasterAlert = false
local disasterDisplayGUI = false
local disasterDetectionConnection = nil
local lastDisaster = ""

-- 创建灾害显示GUI
local disasterGui = Instance.new("ScreenGui")
disasterGui.Name = "DisasterDisplay"
disasterGui.ResetOnSpawn = false
disasterGui.Parent = PlayerGui

local disasterFrame = Instance.new("Frame")
disasterFrame.Size = UDim2.new(0, 200, 0, 60)
disasterFrame.Position = UDim2.new(0.5, -100, 0, 10)
disasterFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
disasterFrame.BackgroundTransparency = 0.3
disasterFrame.BorderSizePixel = 2
disasterFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
disasterFrame.Visible = false
disasterFrame.Parent = disasterGui

local disasterTitle = Instance.new("TextLabel")
disasterTitle.Size = UDim2.new(1, 0, 0, 20)
disasterTitle.Position = UDim2.new(0, 0, 0, 0)
disasterTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
disasterTitle.BackgroundTransparency = 0.5
disasterTitle.Text = "当前灾害"
disasterTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
disasterTitle.TextSize = 14
disasterTitle.Font = Enum.Font.SourceSansBold
disasterTitle.Parent = disasterFrame

local disasterText = Instance.new("TextLabel")
disasterText.Size = UDim2.new(1, 0, 0, 40)
disasterText.Position = UDim2.new(0, 0, 0, 20)
disasterText.BackgroundTransparency = 1
disasterText.Text = "None"
disasterText.TextColor3 = Color3.fromRGB(255, 255, 255)
disasterText.TextSize = 16
disasterText.Font = Enum.Font.SourceSansBold
disasterText.Parent = disasterFrame

local function sendDisasterAlert(disasterName)
    print("🌪️ 当前灾害:", disasterName)
    local success = pcall(function()
        game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(disasterName)
    end)
    
    if success then
        notify("📊 已打印灾害: " .. disasterName)
    end
end

local function updateDisasterDisplay()
    local character = LocalPlayer.Character
    if not character then
        if disasterDisplayGUI then
            disasterText.Text = "None"
        end
        return
    end
    local tag = character:FindFirstChild("SurvivalTag")
    if tag and tag.Value ~= "" then
        local currentDisaster = tag.Value
        if disasterDisplayGUI then
            disasterText.Text = currentDisaster
        end
        if disasterAlert and currentDisaster ~= lastDisaster then
            sendDisasterAlert(currentDisaster)
            lastDisaster = currentDisaster
        end
    else
        if disasterDisplayGUI then
            disasterText.Text = "None"
        end
        if disasterAlert and lastDisaster ~= "" then
            lastDisaster = ""
        end
    end
end

local function startDisasterDetection()
    if disasterDetectionConnection then
        disasterDetectionConnection:Disconnect()
        disasterDetectionConnection = nil
    end
    
    disasterDetectionConnection = RunService.Heartbeat:Connect(function()
        updateDisasterDisplay()
    end)
    lastDisaster = ""
end

local function stopDisasterDetection()
    if disasterDetectionConnection then
        disasterDetectionConnection:Disconnect()
        disasterDetectionConnection = nil
    end
    lastDisaster = ""
end

-- 灾害打印开关
local function toggleDisasterAlert()
    disasterAlert = not disasterAlert
    if disasterAlert and not disasterDetectionConnection then
        startDisasterDetection()
    end
    if not disasterAlert and not disasterDisplayGUI then
        stopDisasterDetection()
    end
    if disasterAlert then
        updateDisasterDisplay()
    end
end

-- 灾害GUI显示开关
local function toggleDisplayGUI()
    disasterDisplayGUI = not disasterDisplayGUI
    disasterFrame.Visible = disasterDisplayGUI
    if disasterDisplayGUI and not disasterDetectionConnection then
        startDisasterDetection()
    end
    if not disasterAlert and not disasterDisplayGUI then
        stopDisasterDetection()
    end
    if disasterDisplayGUI then
        updateDisasterDisplay()
    end
end

-- 天气效果控制
local weatherCleanup = false
local weatherCleanupConnection = nil

local function startWeatherCleanup()
    if weatherCleanupConnection then
        weatherCleanupConnection:Disconnect()
        weatherCleanupConnection = nil
    end
    
    weatherCleanupConnection = RunService.Heartbeat:Connect(function()
        local removedCount = 0
        for _, uiName in ipairs({"SandStormGui", "BlizzardGui"}) do
            local gui = LocalPlayer.PlayerGui:FindFirstChild(uiName)
            if gui then
                gui:Destroy()
                removedCount = removedCount + 1
            end
        end
        local ads = {"BillboardAd", "ForwardPortal"}
        for _, adName in ipairs(ads) do
            local ad = Workspace:FindFirstChild(adName)
            if ad then
                ad:Destroy()
                removedCount = removedCount + 1
            end
        end
        if removedCount > 0 then
            print("🧹 已清理" .. removedCount .. " 天气效果")
        end
    end)
end

local function stopWeatherCleanup()
    if weatherCleanupConnection then
        weatherCleanupConnection:Disconnect()
        weatherCleanupConnection = nil
    end
end

-- 创建UI按钮
local hideButton = createButton("隐藏UI", UDim2.new(0, 10, 0, 10), Color3.fromRGB(255, 200, 100))
createButton("控制台", UDim2.new(0, 10, 0, 50), Color3.fromRGB(191, 239, 255), function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
end)
createButton("关闭UI", UDim2.new(0, 10, 0, 90), Color3.fromRGB(255, 0, 0), function()
    if noFallConnection then
        noFallConnection:Disconnect()
    end
    if autoWinConnection then
        autoWinConnection:Disconnect()
    end
    if disasterDetectionConnection then
        disasterDetectionConnection:Disconnect()
    end
    if weatherCleanupConnection then
        weatherCleanupConnection:Disconnect()
    end
    
    screenGui:Destroy()
    disasterGui:Destroy()
end)

local buttonY = 10
local buttonSpacing = 35

local autoWinButton = createButton("自动胜利: 关", UDim2.new(0, 140, 0, buttonY), Color3.fromRGB(255, 210, 0))
autoWinButton.MouseButton1Click:Connect(function()
    autoWin = not autoWin
    autoWinButton.Text = "自动胜利: " .. (autoWin and "开" or "关")
    autoWinButton.BackgroundColor3 = autoWin and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(45, 45, 45)
    if autoWin then
        setupAutoWin()
    end
end)
buttonY = buttonY + buttonSpacing

local noFallButton = createButton("无坠落伤害: 关", UDim2.new(0, 140, 0, buttonY), Color3.fromRGB(200, 150, 255))
noFallButton.MouseButton1Click:Connect(function()
    noFall = not noFall
    noFallButton.Text = "无坠落伤害: " .. (noFall and "开" or "关")
    noFallButton.BackgroundColor3 = noFall and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(45, 45, 45)
    if noFall and LocalPlayer.Character then
        startNoFall(LocalPlayer.Character)
    end
end)
buttonY = buttonY + buttonSpacing

-- 灾害打印
local disasterAlertButton = createButton("灾害打印: 关", UDim2.new(0, 140, 0, buttonY), Color3.fromRGB(255, 100, 100))
disasterAlertButton.MouseButton1Click:Connect(function()
    toggleDisasterAlert()
    disasterAlertButton.Text = "灾害打印: " .. (disasterAlert and "开" or "关")
    disasterAlertButton.BackgroundColor3 = disasterAlert and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(45, 45, 45)
    notify("灾害打印: " .. (disasterAlert and "开启" or "关闭"))
end)
buttonY = buttonY + buttonSpacing

-- 灾害GUI显示按钮
local displayGUIButton = createButton("灾害显示: 关", UDim2.new(0, 140, 0, buttonY), Color3.fromRGB(100, 200, 255))
displayGUIButton.MouseButton1Click:Connect(function()
    toggleDisplayGUI()
    displayGUIButton.Text = "灾害显示: " .. (disasterDisplayGUI and "开" or "关")
    displayGUIButton.BackgroundColor3 = disasterDisplayGUI and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(45, 45, 45)
    notify("灾害显示: " .. (disasterDisplayGUI and "开启" or "关闭"))
end)
buttonY = buttonY - buttonY + 10

local weatherCleanupButton = createButton("移除天气效果: 关", UDim2.new(0, 270, 0, buttonY), Color3.fromRGB(255, 100, 255))
weatherCleanupButton.MouseButton1Click:Connect(function()
    weatherCleanup = not weatherCleanup
    weatherCleanupButton.Text = "移除天气效果: " .. (weatherCleanup and "开" or "关")
    weatherCleanupButton.BackgroundColor3 = weatherCleanup and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(45, 45, 45)
    
    if weatherCleanup then
        startWeatherCleanup()
    else
        stopWeatherCleanup()
    end
end)
buttonY = buttonY + buttonSpacing

createButton("一键发射火箭", UDim2.new(0, 270, 0, buttonY), Color3.fromRGB(255, 50, 50), launchRocket)
buttonY = buttonY + buttonSpacing

LocalPlayer.CharacterAdded:Connect(function(character)
    if noFall then
        task.wait(3)
        startNoFall(character)
    end
end)

-- UI拖动功能
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

UserInputService.InputChanged:Connect(function(input) 
    if dragging and input == dragInput then 
        updatePos(input) 
    end 
end)

-- UI显示隐藏
local isHidden = false
hideButton.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    for _, obj in ipairs(screenGui:GetChildren()) do
        if obj:IsA("TextButton") and obj ~= hideButton then
            obj.Visible = not isHidden
        end
    end
    hideButton.Text = isHidden and "显示UI" or "隐藏UI"
end)

notify("✅ Loading succeeded.")

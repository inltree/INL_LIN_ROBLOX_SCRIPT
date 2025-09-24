local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerInfoDisplay"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local COLORS = {
    TEXT = Color3.new(1, 1, 1),
    BACKGROUND = Color3.new(0.2, 0.2, 0.2),
    BUTTON_BG = Color3.new(0.1, 0.1, 0.1),
    SCROLLBAR = Color3.new(0.3, 0.3, 0.3),
    SCROLLBAR_THUMB = Color3.new(0.5, 0.5, 0.5),
    TRANSPARENCY = 0.5
}

local FONT_CONFIG = {
    Font = Enum.Font.SourceSansBold,
    TextSize = 16
}

local SERVICES = {
    Players = game:GetService("Players"),
    MarketplaceService = game:GetService("MarketplaceService"),
    RbxAnalyticsService = game:GetService("RbxAnalyticsService"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    TweenService = game:GetService("TweenService")
}

local localPlayer = SERVICES.Players.LocalPlayer

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 280)
mainFrame.Position = UDim2.new(0, 10, 0, -5)
mainFrame.BackgroundColor3 = COLORS.BACKGROUND
mainFrame.BackgroundTransparency = COLORS.TRANSPARENCY
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -25, 1, -10)
scrollFrame.Position = UDim2.new(0, 5, 0, 5)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = COLORS.SCROLLBAR
scrollFrame.ScrollBarImageTransparency = 0.7
scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local infoContainer = Instance.new("TextLabel")
infoContainer.Name = "InfoContainer"
infoContainer.Size = UDim2.new(1, -5, 0, 0)
infoContainer.Position = UDim2.new(0, 0, 0, 0)
infoContainer.Text = "加载中..."
infoContainer.TextColor3 = COLORS.TEXT
infoContainer.BackgroundTransparency = 1
infoContainer.Font = FONT_CONFIG.Font
infoContainer.TextSize = FONT_CONFIG.TextSize
infoContainer.TextXAlignment = Enum.TextXAlignment.Left
infoContainer.TextYAlignment = Enum.TextYAlignment.Top
infoContainer.RichText = true
infoContainer.TextWrapped = true
infoContainer.AutomaticSize = Enum.AutomaticSize.Y
infoContainer.Parent = scrollFrame

local PLATFORM_MAP = {
    [Enum.Platform.Windows] = {name = "Windows 系统", cate = "桌面设备"},
    [Enum.Platform.OSX] = {name = "macOS 系统", cate = "桌面设备"},
    [Enum.Platform.Linux] = {name = "Linux 系统", cate = "桌面设备"},
    [Enum.Platform.IOS] = {name = "iOS 系统", cate = "移动设备"},
    [Enum.Platform.Android] = {name = "Android 系统", cate = "移动设备"},
    [Enum.Platform.XBoxOne] = {name = "Xbox One", cate = "游戏主机"},
    [Enum.Platform.PS4] = {name = "PlayStation 4", cate = "游戏主机"},
    [Enum.Platform.UWP] = {name = "Windows UWP 应用", cate = "特殊平台"},
    [Enum.Platform.None] = {name = "未知平台", cate = "特殊平台"}
}

local function getPlatformInfo()
    local uis = SERVICES.UserInputService
    local platform = uis:GetPlatform()
    local currPlat = PLATFORM_MAP[platform] or PLATFORM_MAP[Enum.Platform.None]
    
    local localTime = DateTime.now():ToLocalTime()
    local currTime = string.format("%d年%d月%d日 %02d:%02d:%02d", 
        localTime.Year, localTime.Month, localTime.Day, 
        localTime.Hour, localTime.Minute, localTime.Second)
    
    local executor = identifyexecutor and identifyexecutor() or "未知执行器"
    
    local platDesc = currPlat.name .. " | 类别：" .. currPlat.cate
    local platEnum = tostring(platform)
    
    local inputList = {}
    if uis.TouchEnabled then table.insert(inputList, "触屏支持") end
    if uis.KeyboardEnabled then table.insert(inputList, "键盘支持") end
    if uis.MouseEnabled then table.insert(inputList, "鼠标支持") end
    if uis.GamepadEnabled then
        local gamepads = uis:GetConnectedGamepads()
        local padType = #gamepads > 0 and tostring(gamepads[1]):gsub("Enum.Gamepad.", "") or "未知手柄"
        table.insert(inputList, "手柄支持(" .. padType .. ")")
    end
    local inputDesc = #inputList > 0 and table.concat(inputList, "|") or "无特殊输入"
    
    return currTime, executor, platDesc, platEnum, inputDesc
end

local function formatInfoText(data)
    return string.format(
        '<font color="rgb(102,255,102)">用户名: %s</font>\n'..
        '<font color="rgb(255,102,102)">显示名称: %s</font>\n'..
        '<font color="rgb(255,255,102)">用户ID: %d</font>\n'..
        '<font color="rgb(173,216,230)">账号注册时间: %d 天</font>\n'..
        '<font color="rgb(255,255,255)">客户端ID: %s</font>\n'..
        '<font color="rgb(102,102,255)">服务器ID: %d</font>\n'..
        '<font color="rgb(255,165,0)">游戏名称: %s</font>\n'..
        '<font color="rgb(0,255,0)">服务器玩家总数: %d</font>\n'..
        '<font color="rgb(128,128,128)">用户代理(UA): %s</font>\n'..
        '<font color="rgb(255,102,204)">当前时间: %s</font>\n'..
        '<font color="rgb(102,204,255)">执行器: %s</font>\n'..
        '<font color="rgb(204,255,102)">平台信息: %s</font>\n'..
        '<font color="rgb(255,204,102)">输入设备: %s</font>\n'..
        '<font color="rgb(153,153,255)">平台枚举: %s</font>',
        
        data.userName, data.displayName, data.userId, data.accountAge, data.clientId,
        data.placeId, data.placeName, data.playerCount, data.userAgent,
        data.currTime, data.executor, data.platDesc, data.inputDesc, data.platEnum
    )
end

local function collectPlayerData()
    local userName = localPlayer.Name
    local displayName = localPlayer.DisplayName
    local userId = localPlayer.UserId
    local accountAge = localPlayer.AccountAge
    local clientId = SERVICES.RbxAnalyticsService:GetClientId()
    
    local placeId = game.PlaceId
    local success, placeInfo = pcall(function()
        return SERVICES.MarketplaceService:GetProductInfo(placeId)
    end)
    local placeName = success and placeInfo.Name or "获取失败"
    
    local playerCount = #SERVICES.Players:GetPlayers()
    local userAgent = SERVICES.HttpService:GetUserAgent()
    
    local currTime, executor, platDesc, platEnum, inputDesc = getPlatformInfo()
    
    return {
        userName = userName,
        displayName = displayName,
        userId = userId,
        accountAge = accountAge,
        clientId = clientId,
        placeId = placeId,
        placeName = placeName,
        playerCount = playerCount,
        userAgent = userAgent,
        currTime = currTime,
        executor = executor,
        platDesc = platDesc,
        platEnum = platEnum,
        inputDesc = inputDesc
    }
end

local function updateInfo()
    local data = collectPlayerData()
    infoContainer.Text = formatInfoText(data)
    
    task.wait(0.1)
    scrollFrame.CanvasPosition = Vector2.new(0, 0)
end

local function createButton(name, position, textColor, onClick)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 30)
    button.Position = position
    button.Text = name
    button.TextColor3 = textColor
    button.BackgroundColor3 = COLORS.BUTTON_BG
    button.BackgroundTransparency = COLORS.TRANSPARENCY
    button.Font = FONT_CONFIG.Font
    button.TextSize = FONT_CONFIG.TextSize
    button.Parent = screenGui
    
    local originalTransparency = button.BackgroundTransparency
    button.MouseEnter:Connect(function()
        SERVICES.TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = originalTransparency - 0.2
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        SERVICES.TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = originalTransparency
        }):Play()
    end)
    
    button.MouseButton1Click:Connect(onClick)
    return button
end

local buttons = {}
buttons.copy = createButton("复制数据", UDim2.new(1, -110, 0, 10), Color3.new(0, 1, 0), function()
    local data = collectPlayerData()
    local copyText = string.format(
        "用户名: %s\n显示名称: %s\n用户ID: %d\n账号注册时间: %d 天\n客户端ID: %s\n\n"..
        "服务器ID: %d\n游戏名称: %s\n服务器玩家总数: %d\n用户代理(UA): %s\n"..
        "当前时间: %s\n执行器: %s\n平台信息: %s\n输入设备: %s\n平台枚举: %s",
        
        data.userName, data.displayName, data.userId, data.accountAge, data.clientId,
        data.placeId, data.placeName, data.playerCount, data.userAgent,
        data.currTime, data.executor, data.platDesc, data.inputDesc, data.platEnum
    )
    setclipboard(copyText)
end)

buttons.console = createButton("控制台", UDim2.new(1, -110, 0, 50), Color3.new(1, 1, 0.5), function()
    SERVICES.VirtualInputManager:SendKeyEvent(true, "F9", false, game)
end)

buttons.close = createButton("关闭UI", UDim2.new(1, -110, 0, 90), Color3.new(1, 0, 0), function()
    screenGui:Destroy()
end)

buttons.hide = createButton("隐藏UI", UDim2.new(1, -110, 0, 130), Color3.new(1, 0.5, 0), function()
    isHidden = not isHidden
    mainFrame.Visible = not isHidden
    buttons.copy.Visible = not isHidden
    buttons.console.Visible = not isHidden
    buttons.close.Visible = not isHidden
    buttons.hide.Text = isHidden and "显示UI" or "隐藏UI"
end)

local isDragging = false
local dragStartPos, btnStartPos

local function updateButtonPosition(input)
    if not isDragging then return end
    local delta = input.Position - dragStartPos
    buttons.hide.Position = UDim2.new(
        btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X,
        btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
    )
end

buttons.hide.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        btnStartPos = buttons.hide.Position
    end
end)

buttons.hide.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

SERVICES.UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateButtonPosition(input)
    end
end)

scrollFrame.MouseEnter:Connect(function()
    scrollFrame.Active = true
end)
scrollFrame.MouseLeave:Connect(function()
    scrollFrame.Active = false
end)

local function onCharacterAdded()
    task.wait(0.5)
    updateInfo()
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

SERVICES.Players.PlayerAdded:Connect(updateInfo)
SERVICES.Players.PlayerRemoving:Connect(updateInfo)

task.spawn(updateInfo)
task.spawn(function()
    while task.wait(0.5) do
        if screenGui.Parent then
            updateInfo()
        else
            break
        end
    end
end)

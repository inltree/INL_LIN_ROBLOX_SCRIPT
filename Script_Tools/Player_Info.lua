--[[
   📊 玩家信息统计
   作者：inltree｜Lin×AI
   更新：优化FPS显示
   版本：v2.0
]]

-- 🧩 服务定义
local Services = {
    Players = game:GetService("Players"),
    MarketplaceService = game:GetService("MarketplaceService"),
    AnalyticsService = game:GetService("RbxAnalyticsService"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    TweenService = game:GetService("TweenService"),
    Stats = game:GetService("Stats"),
    TeleportService = game:GetService("TeleportService"),
    StarterGui = game:GetService("StarterGui"),
    RunService = game:GetService("RunService"),
}
local LocalPlayer = Services.Players.LocalPlayer
local JoinTime = tick()
local PlaceId = game.PlaceId
local JobId = game.JobId

-- 📊 玩家统计变量
local totalPlayersJoined = 0
local totalPlayersLeft = 0

-- 📈 FPS统计变量
local heartbeatFrameCount = 0
local heartbeatLastUpdateTime = tick()
local realTimeFPS = 0
local physicsFPSValue = 0

-- 初始化FPS计算
task.spawn(function()
    while task.wait() do
        local currentTime = tick()
        heartbeatFrameCount = heartbeatFrameCount + 1
        
        if currentTime - heartbeatLastUpdateTime >= 1 then
            realTimeFPS = heartbeatFrameCount
            heartbeatFrameCount = 0
            heartbeatLastUpdateTime = currentTime
        end
    end
end)

totalPlayersJoined = #Services.Players:GetPlayers()
Services.Players.PlayerAdded:Connect(function(newPlayer)
    totalPlayersJoined = totalPlayersJoined + 1
end)
Services.Players.PlayerRemoving:Connect(function(leavingPlayer)
    totalPlayersLeft = totalPlayersLeft + 1
end)

-- 🎨 样式配置
local UI_Colors = {
    Text = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(51, 51, 51),
    Button = Color3.fromRGB(26, 26, 26),
    Transparency = 0.5
}
local UI_FontStyle = {
    Font = Enum.Font.SourceSansBold,
    Size = 16
}

-- 🪟 主容器（在CoreGui中创建）
local playerInfoScreenGui = Instance.new("ScreenGui")
playerInfoScreenGui.Name = "PlayerInfoUI"
playerInfoScreenGui.ResetOnSpawn = false
playerInfoScreenGui.IgnoreGuiInset = true
playerInfoScreenGui.Parent = game:GetService("CoreGui")

-- 📋 信息面板
local mainInfoFrame = Instance.new("Frame", playerInfoScreenGui)
mainInfoFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
mainInfoFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
mainInfoFrame.BackgroundColor3 = UI_Colors.Background
mainInfoFrame.BackgroundTransparency = UI_Colors.Transparency
mainInfoFrame.BorderSizePixel = 2
mainInfoFrame.BorderColor3 = Color3.fromRGB(255, 128, 0)
mainInfoFrame.ClipsDescendants = true

local scrollContainer = Instance.new("ScrollingFrame", mainInfoFrame)
scrollContainer.Size = UDim2.new(1, -10, 1, -10)
scrollContainer.Position = UDim2.new(0, 5, 0, 5)
scrollContainer.BackgroundTransparency = 1
scrollContainer.ScrollBarThickness = 8
scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

local infoDisplayLabel = Instance.new("TextLabel", scrollContainer)
infoDisplayLabel.Size = UDim2.new(1, -10, 0, 0)
infoDisplayLabel.BackgroundTransparency = 1
infoDisplayLabel.TextColor3 = UI_Colors.Text
infoDisplayLabel.Font = UI_FontStyle.Font
infoDisplayLabel.TextSize = UI_FontStyle.Size
infoDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
infoDisplayLabel.TextYAlignment = Enum.TextYAlignment.Top
infoDisplayLabel.RichText = true
infoDisplayLabel.TextWrapped = true
infoDisplayLabel.AutomaticSize = Enum.AutomaticSize.Y
infoDisplayLabel.Text = "正在加载..."

-- 💻 平台枚举表
local PLATFORM_DATA = {
    [Enum.Platform.Windows] = { name = "Windows 系统", category = "桌面设备" },
    [Enum.Platform.IOS] = { name = "iOS 系统", category = "移动设备" },
    [Enum.Platform.Android] = { name = "Android 系统", category = "移动设备" },
    [Enum.Platform.OSX] = { name = "macOS 系统", category = "桌面设备" },
    [Enum.Platform.Linux] = { name = "Linux 系统", category = "桌面设备" },
    [Enum.Platform.XBoxOne] = { name = "Xbox One", category = "游戏主机" },
    [Enum.Platform.PS4] = { name = "PlayStation 4", category = "游戏主机" },
    [Enum.Platform.None] = { name = "未知平台", category = "特殊平台" }
}

-- 🧭 获取平台信息
local function getPlatformDetails()
    local userInput = Services.UserInputService
    local platformType = userInput:GetPlatform()
    local currentPlatform = PLATFORM_DATA[platformType] or PLATFORM_DATA[Enum.Platform.None]

    local localDateTime = DateTime.now():ToLocalTime()
    local formattedDateTime = string.format("%d年%d月%d日 %02d:%02d:%02d",
        localDateTime.Year, localDateTime.Month, localDateTime.Day,
        localDateTime.Hour, localDateTime.Minute, localDateTime.Second)

    local executorName = identifyexecutor and identifyexecutor() or "未知执行器"
    local inputDeviceList = {}
    if userInput.TouchEnabled then table.insert(inputDeviceList, "触屏") end
    if userInput.KeyboardEnabled then table.insert(inputDeviceList, "键盘") end
    if userInput.MouseEnabled then table.insert(inputDeviceList, "鼠标") end
    if userInput.GamepadEnabled then table.insert(inputDeviceList, "手柄") end

    local inputDescription = #inputDeviceList > 0 and table.concat(inputDeviceList, " | ") or "无特殊输入"

    return formattedDateTime, executorName, currentPlatform.name .. " | 类别: " .. currentPlatform.category, tostring(platformType), inputDescription
end

-- 🕒 格式化在线时间
local function formatPlayTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secondsRemaining = math.floor(seconds % 60)
    return string.format("%02d时%02d分%02d秒", hours, minutes, secondsRemaining)
end

-- 👥 好友统计
local function countServerFriends()
    local currentPlayers = Services.Players:GetPlayers()
    local friendCount = 0
    
    for _, otherPlayer in ipairs(currentPlayers) do
        if otherPlayer ~= LocalPlayer then
            local success, isFriend = pcall(function()
                return LocalPlayer:IsFriendsWith(otherPlayer.UserId)
            end)
            
            if success and isFriend then
                friendCount = friendCount + 1
            end
        end
    end
    
    return friendCount
end

-- 🧩 收集玩家数据
local function gatherPlayerInfo()
    local currentPlayer = LocalPlayer
    local playerCharacter = currentPlayer.Character or currentPlayer.CharacterAdded:Wait()
    local playerHumanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
    local playerRoot = playerCharacter:FindFirstChild("HumanoidRootPart")

    local playerUsername, playerDisplayName, playerID = currentPlayer.Name, currentPlayer.DisplayName, currentPlayer.UserId
    local accountAgeDays, analyticsClientId = currentPlayer.AccountAge, Services.AnalyticsService:GetClientId()
    local membershipLevel = currentPlayer.MembershipType
    local isPremiumMember = (membershipLevel == Enum.MembershipType.Premium) and "是" or "否"
    local playerPosition = playerRoot and playerRoot.Position or Vector3.new(0, 0, 0)

    local gamePlaceId = game.PlaceId
    local success, placeData = pcall(function()
        return Services.MarketplaceService:GetProductInfo(gamePlaceId)
    end)
    local placeDisplayName = success and placeData.Name or "未知游戏"

    local currentPlayerCount = #Services.Players:GetPlayers()
    local maxServerCapacity = Services.Players.MaxPlayers
    
    local friendCountInServer = countServerFriends()
    
    local userAgentString = Services.HttpService:GetUserAgent()
    local currentDateTime, executorName, platformInfo, platformCode, inputDevices = getPlatformDetails()

    local sessionDuration = tick() - JoinTime
    local networkLatency = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())

    physicsFPSValue = math.floor(workspace:GetRealPhysicsFPS())
    
    local memoryUsageMB = math.floor(Services.Stats:GetTotalMemoryUsageMb())
    local currentHealth = playerHumanoid and math.floor(playerHumanoid.Health) or 0
    local maximumHealth = playerHumanoid and math.floor(playerHumanoid.MaxHealth) or 0

    return {
        username = playerUsername,
        displayName = playerDisplayName,
        userId = playerID,
        accountAge = accountAgeDays,
        premiumStatus = isPremiumMember,
        
        clientIdentifier = analyticsClientId,
        gamePlaceId = gamePlaceId,
        placeName = placeDisplayName,
        serverJobId = JobId,
        playerCount = currentPlayerCount,
        maxPlayers = maxServerCapacity,
        totalJoined = totalPlayersJoined,
        totalLeft = totalPlayersLeft,
        
        serverFriendCount = friendCountInServer,
        
        userAgent = userAgentString,
        currentDateTime = currentDateTime,
        executor = executorName,
        platformDetails = platformInfo,
        inputDescription = inputDevices,
        platformEnum = platformCode,
        position = string.format("(%.2f, %.2f, %.2f)", playerPosition.X, playerPosition.Y, playerPosition.Z),
        sessionTime = formatPlayTime(sessionDuration),
        pingLatency = networkLatency,
        realTimeFPS = realTimeFPS,
        physicsFPS = physicsFPSValue,
        memoryUsage = memoryUsageMB,
        currentHealth = currentHealth,
        maxHealth = maximumHealth
    }
end

-- 📋 分类显示格式
local function formatDisplayData(data)
    return string.format([[

<font color="rgb(255,255,255)" size="20"><b>📁 基本信息</b></font>
<font color="rgb(102,255,102)">用户名:</font> %s
<font color="rgb(255,102,102)">显示名称:</font> %s
<font color="rgb(255,255,102)">用户ID:</font> %d
<font color="rgb(173,216,230)">账号注册时间:</font> %d 天
<font color="rgb(255,215,0)">是否会员:</font> %s

<font color="rgb(255,255,255)" size="20"><b>🕹️ 游戏信息</b></font>
<font color="rgb(0,255,0)">生命值:</font> %d / %d
<font color="rgb(0,255,255)">玩家坐标:</font> %s
<font color="rgb(255,182,193)">在线时长:</font> %s
<font color="rgb(255,215,0)">地图名称:</font> %s
<font color="rgb(255,165,0)">地图ID:</font> %d
<font color="rgb(255,165,0)">服务器工作ID:</font> %s
<font color="rgb(0,255,0)">服务器玩家:</font> %d / %d
<font color="rgb(128,255,128)">总加入离开玩家:</font> %d / %d
<font color="rgb(255,128,255)">服务器联系人:</font> %d

<font color="rgb(255,255,255)" size="20"><b>⚙️ 系统信息</b></font>
<font color="rgb(255,140,0)">延迟 (Ping):</font> %d MS
<font color="rgb(255,255,50)">帧率 (FPS):</font> %d / %d
<font color="rgb(173,255,47)">内存占用:</font> %d MB
<font color="rgb(255,102,204)">当前时间:</font> %s
<font color="rgb(128,128,128)">客户端ID:</font> %s
<font color="rgb(128,128,128)">用户代理(UA):</font> %s

<font color="rgb(255,255,255)" size="20"><b>💻 平台信息</b></font>
<font color="rgb(102,204,255)">执行器:</font> %s
<font color="rgb(204,255,102)">平台信息:</font> %s
<font color="rgb(255,204,102)">输入设备:</font> %s
<font color="rgb(153,153,255)">平台枚举:</font> %s
]],
        data.username, data.displayName, data.userId, data.accountAge, data.premiumStatus,
        data.currentHealth, data.maxHealth, data.position, data.sessionTime,
        data.placeName, data.gamePlaceId, data.serverJobId, data.playerCount, data.maxPlayers,
        data.totalJoined, data.totalLeft, data.serverFriendCount,
        data.pingLatency, data.realTimeFPS, data.physicsFPS, data.memoryUsage, data.currentDateTime, data.clientIdentifier, data.userAgent,
        data.executor, data.platformDetails, data.inputDescription, data.platformEnum)
end

-- 更新信息显示
local function refreshInfoDisplay()
    pcall(function()
        infoDisplayLabel.Text = formatDisplayData(gatherPlayerInfo())
    end)
end
task.defer(refreshInfoDisplay)

-- 🔁 实时更新循环
task.spawn(function()
    while task.wait(0.2) do
        if playerInfoScreenGui.Parent then
            pcall(refreshInfoDisplay)
        else
            break
        end
    end
end)

-- 🎛️ 按钮面板
local controlPanel = Instance.new("Frame", playerInfoScreenGui)
controlPanel.Size = UDim2.new(0, 80, 0, 80)
controlPanel.AnchorPoint = Vector2.new(0.5, 0.5)
controlPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
controlPanel.BackgroundTransparency = 1
controlPanel.BorderSizePixel = 2
controlPanel.BorderColor3 = Color3.fromRGB(0, 128, 128)

-- 按钮生成函数
local function createControlButton(buttonText, yPosition, textColor, clickAction)
    local button = Instance.new("TextButton", controlPanel)
    button.Size = UDim2.new(1, -10, 0, 35)
    button.Position = UDim2.new(0, 5, 0, yPosition)
    button.Text = buttonText
    button.Font = UI_FontStyle.Font
    button.TextSize = UI_FontStyle.Size
    button.TextColor3 = textColor
    button.BackgroundColor3 = UI_Colors.Button
    button.BackgroundTransparency = UI_Colors.Transparency
    button.BorderSizePixel = 2
    button.BorderColor3 = Color3.fromRGB(0, 128, 128)
    button.TextScaled = true
    if clickAction then button.MouseButton1Click:Connect(clickAction) end
    return button
end

-- 伺服器跳转
local function serverHop()
    task.wait()
    print("[inltree] 🔍 正在搜索人数最少的服务器...")
    
    local lowestPlayerCount = math.huge
    local targetServers = {}
    local foundPlayers = 0
    
    local success, result = pcall(function()
        for _, serverData in ipairs(Services.HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data) do
            if type(serverData) == "table" and serverData.maxPlayers > serverData.playing and serverData.id ~= JobId then
                if serverData.playing < lowestPlayerCount then
                    lowestPlayerCount = serverData.playing
                    targetServers[1] = serverData.id
                    foundPlayers = serverData.playing
                end
            end
        end
        
        if #targetServers > 0 then
            print("[inltree] ✅ 正在跳转服务器 | 玩家数量: " .. foundPlayers)
            Services.TeleportService:TeleportToPlaceInstance(PlaceId, targetServers[1], Services.Players.LocalPlayer)
        else
            warn("[inltree] ⚠️ 未找到合适的服务器")
        end
    end)
    
    if not success then
        warn("[inltree] ❌ 搜索服务器时出错:", result)
    end
end

-- 重新加入伺服器
local function rejoinServer()
    if #Services.Players:GetPlayers() <= 1 then
        Services.Players.LocalPlayer:Kick("重新加入中...\n(Rejoining...)")
        task.wait()
        Services.TeleportService:Teleport(PlaceId, Services.Players.LocalPlayer)
    else
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Services.Players.LocalPlayer)
    end
end

-- 控制台功能
local function openDeveloperConsole()
    local success = pcall(function()
        Services.StarterGui:SetCore("DevConsoleVisible", true)
    end)
    
    if not success then
        pcall(function() 
            Services.VirtualInputManager:SendKeyEvent(true, "F9", false, game) 
        end)
    end
end

-- 创建按钮
local isHidden = false
local buttonPositions = {
    copy = 0,
    console = 35,
    serverhop = 70,
    rejoin = 105,
    close = 140,
    hide = 175
}

local copyDataButton = createControlButton("复制数据", buttonPositions.copy, Color3.fromRGB(0, 255, 0), function()
    setclipboard(infoDisplayLabel.Text:gsub("<.->", ""))
end)

local consoleButton = createControlButton("控制台", buttonPositions.console, Color3.fromRGB(255, 255, 128), openDeveloperConsole)

local serverHopButton = createControlButton("传送伺服", buttonPositions.serverhop, Color3.fromRGB(128, 255, 128), serverHop)

local rejoinButton = createControlButton("重新加入", buttonPositions.rejoin, Color3.fromRGB(255, 178, 77), rejoinServer)

local closeButton = createControlButton("关闭UI", buttonPositions.close, Color3.fromRGB(255, 0, 0), function()
    playerInfoScreenGui:Destroy()
end)

local hideButton = createControlButton("隐藏UI", buttonPositions.hide, Color3.fromRGB(255, 128, 0))

-- 🔧 拖动逻辑
local function setupDraggingInterface(uiElement, dragElement)
    dragElement = dragElement or uiElement
    local parentScreenGui = uiElement:FindFirstAncestorWhichIsA("ScreenGui") or uiElement.Parent
    local isDragging, dragInput, dragOrigin, startPosition
    local anchor = uiElement.AnchorPoint

    local function safeClamp(value, minVal, maxVal)
        if maxVal < minVal then maxVal = minVal end
        return math.clamp(value, minVal, maxVal)
    end

    local function updatePosition(input)
        pcall(function()
            local parentSize = parentScreenGui.AbsoluteSize
            local elementSize = uiElement.AbsoluteSize
            if parentSize.X <= 0 or parentSize.Y <= 0 then return end
            local startX = startPosition.X.Scale * parentSize.X + startPosition.X.Offset
            local startY = startPosition.Y.Scale * parentSize.Y + startPosition.Y.Offset
            local deltaX = input.Position.X - dragOrigin.X
            local deltaY = input.Position.Y - dragOrigin.Y
            local minX = anchor.X * elementSize.X
            local maxX = parentSize.X - (1 - anchor.X) * elementSize.X
            local minY = anchor.Y * elementSize.Y
            local maxY = parentSize.Y - (1 - anchor.Y) * elementSize.Y
            local newX = safeClamp(startX + deltaX, minX, maxX)
            local newY = safeClamp(startY + deltaY, minY, maxY)
            uiElement.Position = UDim2.new(newX / parentSize.X, 0, newY / parentSize.Y, 0)
        end)
    end

    dragElement.InputBegan:Connect(function(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                dragOrigin = input.Position
                startPosition = uiElement.Position
                local connection = input.Changed:Connect(function()
                    pcall(function()
                        if input.UserInputState == Enum.UserInputState.End then isDragging = false end
                    end)
                end)
            end
        end)
    end)

    dragElement.InputChanged:Connect(function(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end)

    Services.UserInputService.InputChanged:Connect(function(input)
        pcall(function()
            if input == dragInput and isDragging then updatePosition(input) end
        end)
    end)

    local function clampToViewport()
        pcall(function()
            local parentSize = parentScreenGui.AbsoluteSize
            local elementSize = uiElement.AbsoluteSize
            if parentSize.X <= 0 or parentSize.Y <= 0 then return end
            local current = uiElement.Position
            local absX = current.X.Scale * parentSize.X + current.X.Offset
            local absY = current.Y.Scale * parentSize.Y + current.Y.Offset
            local minX = anchor.X * elementSize.X
            local maxX = parentSize.X - (1 - anchor.X) * elementSize.X
            local minY = anchor.Y * elementSize.Y
            local maxY = parentSize.Y - (1 - anchor.Y) * elementSize.Y
            local newX = safeClamp(absX, minX, maxX)
            local newY = safeClamp(absY, minY, maxY)
            uiElement.Position = UDim2.new(newX / parentSize.X, 0, newY / parentSize.Y, 0)
        end)
    end

    parentScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampToViewport)
    if uiElement and uiElement.GetPropertyChangedSignal then
        uiElement:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampToViewport)
    end
    clampToViewport()

    pcall(function() uiElement.Active = true end)
    pcall(function() dragElement.Active = true end)
end

-- 🎯 设置按钮面板的拖动功能
setupDraggingInterface(controlPanel, hideButton)

-- 隐藏/显示UI功能
hideButton.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    for _, element in ipairs({mainInfoFrame, copyDataButton, consoleButton, serverHopButton, rejoinButton, closeButton}) do
        element.Visible = not isHidden
    end
    hideButton.Text = isHidden and "显示UI" or "隐藏UI"
end)

print("[inltree] ✅ Player information display loaded successfully.")

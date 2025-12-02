--[[
   📘 玩家信息显示器
   作者：inltree｜Lin×AI
   更新：优化拖动、优化界面、添加更多信息
   版本：v2.0 - 增强版
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
}
local LocalPlayer = Services.Players.LocalPlayer
local JoinTime = tick()
local PlaceId = game.PlaceId
local JobId = game.JobId

-- 📊 玩家统计变量
local totalPlayersJoined = 0
local totalPlayersLeft = 0

totalPlayersJoined = #Services.Players:GetPlayers()
Services.Players.PlayerAdded:Connect(function(player)
    totalPlayersJoined = totalPlayersJoined + 1
end)
Services.Players.PlayerRemoving:Connect(function(player)
    totalPlayersLeft = totalPlayersLeft + 1
end)

-- 🎨 样式配置
local Colors = {
    Text = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(51, 51, 51),
    Button = Color3.fromRGB(26, 26, 26),
    Alpha = 0.5
}
local FontStyle = {
    Font = Enum.Font.SourceSansBold,
    Size = 16
}

-- 🪟 主容器（在CoreGui中创建）
local playerInfoGui = Instance.new("ScreenGui")
playerInfoGui.Name = "PlayerInfoUI"
playerInfoGui.ResetOnSpawn = false
playerInfoGui.IgnoreGuiInset = true
playerInfoGui.Parent = game:GetService("CoreGui")

-- 📋 信息面板
local infoFrame = Instance.new("Frame", playerInfoGui)
infoFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
infoFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
infoFrame.BackgroundColor3 = Colors.Background
infoFrame.BackgroundTransparency = Colors.Alpha
infoFrame.BorderSizePixel = 2
infoFrame.BorderColor3 = Color3.fromRGB(255, 128, 0)
infoFrame.ClipsDescendants = true

local scrollFrame = Instance.new("ScrollingFrame", infoFrame)
scrollFrame.Size = UDim2.new(1, -10, 1, -10)
scrollFrame.Position = UDim2.new(0, 5, 0, 5)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local infoLabel = Instance.new("TextLabel", scrollFrame)
infoLabel.Size = UDim2.new(1, -10, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Colors.Text
infoLabel.Font = FontStyle.Font
infoLabel.TextSize = FontStyle.Size
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.RichText = true
infoLabel.TextWrapped = true
infoLabel.AutomaticSize = Enum.AutomaticSize.Y
infoLabel.Text = "None..."

-- 💻 平台枚举表
local PLATFORM_MAP = {
    [Enum.Platform.Windows] = { name = "Windows 系统", category = "桌面设备" },
    [Enum.Platform.IOS] = { name = "iOS 系统", category = "移动设备" },
    [Enum.Platform.Android] = { name = "Android 系统", category = "移动设备" },
    [Enum.Platform.OSX] = { name = "macOS 系统", category = "桌面设备" },
    [Enum.Platform.Linux] = { name = "Linux 系统", category = "桌面设备" },
    [Enum.Platform.XBoxOne] = { name = "Xbox One", category = "游戏主机" },
    [Enum.Platform.PS4] = { name = "PlayStation 4", category = "游戏主机" },
    [Enum.Platform.None] = { name = "None", category = "None" }
}

-- 🧭 获取平台信息
local function getPlatformInfo()
    local uis = Services.UserInputService
    local platform = uis:GetPlatform()
    local currentPlatform = PLATFORM_MAP[platform] or PLATFORM_MAP[Enum.Platform.None]

    local localTime = DateTime.now():ToLocalTime()
    local formattedTime = string.format("%d年%d月%d日 %02d:%02d:%02d",
        localTime.Year, localTime.Month, localTime.Day,
        localTime.Hour, localTime.Minute, localTime.Second)

    local executor = identifyexecutor and identifyexecutor() or "None"
    local inputDevices = {}
    if uis.TouchEnabled then table.insert(inputDevices, "触屏") end
    if uis.KeyboardEnabled then table.insert(inputDevices, "键盘") end
    if uis.MouseEnabled then table.insert(inputDevices, "鼠标") end
    if uis.GamepadEnabled then table.insert(inputDevices, "手柄") end

    local inputDesc = #inputDevices > 0 and table.concat(inputDevices, " | ") or "无特殊输入"

    return formattedTime, executor, currentPlatform.name .. " | 类别: " .. currentPlatform.category, tostring(platform), inputDesc
end

-- 🕒 在线时间
local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d时%02d分%02d秒", h, m, s)
end

-- 👥 好友统计
local function getFriendsCount()
    local players = Services.Players:GetPlayers()
    local myFriendsCount = 0
    
    for _, player in ipairs(players) do
        if player ~= LocalPlayer then
            local success, isFriend = pcall(function()
                return LocalPlayer:IsFriendsWith(player.UserId)
            end)
            
            if success and isFriend then
                myFriendsCount = myFriendsCount + 1
            end
        end
    end
    
    return myFriendsCount
end

-- 🧩 收集玩家数据
local function collectPlayerData()
    local player = LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    local userName, displayName, userId = player.Name, player.DisplayName, player.UserId
    local accountAge, clientId = player.AccountAge, Services.AnalyticsService:GetClientId()
    local membershipType = player.MembershipType
    local isPremium = (membershipType == Enum.MembershipType.Premium) and "是" or "否"
    local position = rootPart and rootPart.Position or Vector3.new(0, 0, 0)

    local placeId = game.PlaceId
    local ok, placeInfo = pcall(function()
        return Services.MarketplaceService:GetProductInfo(placeId)
    end)
    local placeName = ok and placeInfo.Name or "None"

    local playerCount = #Services.Players:GetPlayers()
    local maxPlayers = Services.Players.MaxPlayers
    
    local myFriendsCount = getFriendsCount()
    
    local userAgent = Services.HttpService:GetUserAgent()
    local currentTime, executor, platformDesc, platformEnum, inputDesc = getPlatformInfo()

    local sessionTime = tick() - JoinTime
    local ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    local memory = math.floor(Services.Stats:GetTotalMemoryUsageMb())
    local health = humanoid and math.floor(humanoid.Health) or 0
    local maxHealth = humanoid and math.floor(humanoid.MaxHealth) or 0

    return {
        userName = userName,
        displayName = displayName,
        userId = userId,
        accountAge = accountAge,
        isPremium = isPremium,
        
        clientId = clientId,
        placeId = placeId,
        placeName = placeName,
        jobId = JobId,
        playerCount = playerCount,
        maxPlayers = maxPlayers,
        totalJoined = totalPlayersJoined,
        totalLeft = totalPlayersLeft,
        
        myFriendsCount = myFriendsCount,
        
        userAgent = userAgent,
        currentTime = currentTime,
        executor = executor,
        platformDesc = platformDesc,
        inputDesc = inputDesc,
        platformEnum = platformEnum,
        position = string.format("(%.2f, %.2f, %.2f)", position.X, position.Y, position.Z),
        sessionTime = formatTime(sessionTime),
        ping = ping,
        fps = fps,
        memory = memory,
        health = health,
        maxHealth = maxHealth
    }
end

-- 📋 分类显示格式
local function formatPlayerData(d)
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
<font color="rgb(255,140,0)">Ping 延迟:</font> %d MS
<font color="rgb(0,255,255)">帧率 (FPS):</font> %d
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
        d.userName, d.displayName, d.userId, d.accountAge, d.isPremium,
        d.health, d.maxHealth, d.position, d.sessionTime,
        d.placeName, d.placeId, d.jobId, d.playerCount, d.maxPlayers,
        d.totalJoined, d.totalLeft, d.myFriendsCount,
        d.ping, d.fps, d.memory, d.currentTime, d.clientId, d.userAgent,
        d.executor, d.platformDesc, d.inputDesc, d.platformEnum)
end

-- 更新信息
local function updatePlayerInfo()
    pcall(function()
        infoLabel.Text = formatPlayerData(collectPlayerData())
    end)
end
task.defer(updatePlayerInfo)

-- 🔁 实时更新
task.spawn(function()
    while task.wait(0.2) do
        if playerInfoGui.Parent then
            pcall(updatePlayerInfo)
        else
            break
        end
    end
end)

-- 🎛️ 按钮面板
local buttonPanel = Instance.new("Frame", playerInfoGui)
buttonPanel.Size = UDim2.new(0, 80, 0, 80)
buttonPanel.AnchorPoint = Vector2.new(0.5, 0.5)
buttonPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
buttonPanel.BackgroundTransparency = 1
buttonPanel.BorderSizePixel = 2
buttonPanel.BorderColor3 = Color3.fromRGB(0, 128, 128)

-- 按钮生成函数
local function createButton(text, y, color, onClick)
    local btn = Instance.new("TextButton", buttonPanel)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.Text = text
    btn.Font = FontStyle.Font
    btn.TextSize = FontStyle.Size
    btn.TextColor3 = color
    btn.BackgroundColor3 = Colors.Button
    btn.BackgroundTransparency = Colors.Alpha
    btn.BorderSizePixel = 2
    btn.BorderColor3 = Color3.fromRGB(0, 128, 128)
    btn.TextScaled = true
    if onClick then btn.MouseButton1Click:Connect(onClick) end
    return btn
end

-- 伺服器跳转
local function serverHop()
    task.wait()
    print("[inltree] 🔍 正在搜索人数最少的服务器...")
    
    local Number = math.huge
    local SomeSRVS = {}
    local found = 0
    
    local success, result = pcall(function()
        for _, v in ipairs(Services.HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data) do
            if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= JobId then
                if v.playing < Number then
                    Number = v.playing
                    SomeSRVS[1] = v.id
                    found = v.playing
                end
            end
        end
        
        if #SomeSRVS > 0 then
            print("[inltree] ✅ 正在跳转服务器 | 玩家数量: " .. found)
            Services.TeleportService:TeleportToPlaceInstance(PlaceId, SomeSRVS[1], Services.Players.LocalPlayer)
        else
            warn("[inltree] ⚠️ 未找到合适的服务器")
        end
    end)
    
    if not success then
        warn("[inltree] ❌ 搜索服务器时出错:", result)
    end
end

-- 重新加入伺服器
local function rejoin()
    if #Services.Players:GetPlayers() <= 1 then
        Services.Players.LocalPlayer:Kick("重新加入中...\n(Rejoining...)")
        task.wait()
        Services.TeleportService:Teleport(PlaceId, Services.Players.LocalPlayer)
    else
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Services.Players.LocalPlayer)
    end
end

-- 控制台功能
local function openConsole()
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
local hidden = false
local buttonYPositions = {
    copy = 0,
    console = 35,
    serverhop = 70,
    rejoin = 105,
    close = 140,
    hide = 175
}

local copyButton = createButton("复制数据", buttonYPositions.copy, Color3.fromRGB(0, 255, 0), function()
    setclipboard(infoLabel.Text:gsub("<.->", ""))
end)

local consoleButton = createButton("控制台", buttonYPositions.console, Color3.fromRGB(255, 255, 128), openConsole)

local serverhopButton = createButton("传送伺服", buttonYPositions.serverhop, Color3.fromRGB(128, 255, 128), serverHop)

local rejoinButton = createButton("重新加入", buttonYPositions.rejoin, Color3.fromRGB(255, 178, 77), rejoin)

local closeButton = createButton("关闭UI", buttonYPositions.close, Color3.fromRGB(255, 0, 0), function()
    playerInfoGui:Destroy()
end)

local hideButton = createButton("隐藏UI", buttonYPositions.hide, Color3.fromRGB(255, 128, 0))

-- 🔧 优化的拖动逻辑
local function setupDragger(ui, dragui)
    dragui = dragui or ui
    local screenGui = ui:FindFirstAncestorWhichIsA("ScreenGui") or ui.Parent
    local dragging, dragInput, dragStart, startPos
    local anchor = ui.AnchorPoint

    local function safeClamp(v, lo, hi)
        if hi < lo then hi = lo end
        return math.clamp(v, lo, hi)
    end

    local function update(input)
        pcall(function()
            local p = screenGui.AbsoluteSize
            local s = ui.AbsoluteSize
            if p.X <= 0 or p.Y <= 0 then return end
            local startX = startPos.X.Scale * p.X + startPos.X.Offset
            local startY = startPos.Y.Scale * p.Y + startPos.Y.Offset
            local dx = input.Position.X - dragStart.X
            local dy = input.Position.Y - dragStart.Y
            local minX = anchor.X * s.X
            local maxX = p.X - (1 - anchor.X) * s.X
            local minY = anchor.Y * s.Y
            local maxY = p.Y - (1 - anchor.Y) * s.Y
            local nx = safeClamp(startX + dx, minX, maxX)
            local ny = safeClamp(startY + dy, minY, maxY)
            ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0)
        end)
    end

    dragui.InputBegan:Connect(function(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = ui.Position
                local c = input.Changed:Connect(function()
                    pcall(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end)
            end
        end)
    end)

    dragui.InputChanged:Connect(function(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end)

    Services.UserInputService.InputChanged:Connect(function(input)
        pcall(function()
            if input == dragInput and dragging then update(input) end
        end)
    end)

    local function clampToViewport()
        pcall(function()
            local p = screenGui.AbsoluteSize
            local s = ui.AbsoluteSize
            if p.X <= 0 or p.Y <= 0 then return end
            local curr = ui.Position
            local absX = curr.X.Scale * p.X + curr.X.Offset
            local absY = curr.Y.Scale * p.Y + curr.Y.Offset
            local minX = anchor.X * s.X
            local maxX = p.X - (1 - anchor.X) * s.X
            local minY = anchor.Y * s.Y
            local maxY = p.Y - (1 - anchor.Y) * s.Y
            local nx = safeClamp(absX, minX, maxX)
            local ny = safeClamp(absY, minY, maxY)
            ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0)
        end)
    end

    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampToViewport)
    if ui and ui.GetPropertyChangedSignal then
        ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampToViewport)
    end
    clampToViewport()

    pcall(function() ui.Active = true end)
    pcall(function() dragui.Active = true end)
end

-- 🎯 设置按钮面板的拖动功能
setupDragger(buttonPanel, hideButton)

-- 隐藏/显示UI功能
hideButton.MouseButton1Click:Connect(function()
    hidden = not hidden
    for _, v in ipairs({infoFrame, copyButton, consoleButton, serverhopButton, rejoinButton, closeButton}) do
        v.Visible = not hidden
    end
    hideButton.Text = hidden and "显示UI" or "隐藏UI"
end)

print("[inltree] ✅ Player information display loaded successfully.")

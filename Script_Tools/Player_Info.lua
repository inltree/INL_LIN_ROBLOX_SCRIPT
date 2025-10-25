--[[
   📘 玩家信息显示器
   作者：inltree｜Lin×AI
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
}
local localPlayer = Services.Players.LocalPlayer
local joinTime = tick() -- 玩家进入时间

-- 🎨 样式配置
local Colors = {
	Text = Color3.new(1, 1, 1),
	Background = Color3.new(0.2, 0.2, 0.2),
	Button = Color3.new(0.1, 0.1, 0.1),
	Alpha = 0.5
}
local FontStyle = {
	Font = Enum.Font.SourceSansBold,
	Size = 16
}

-- 🪟 主容器
local playerInfoGui = Instance.new("ScreenGui")
playerInfoGui.Name = "PlayerInfoUI"
playerInfoGui.ResetOnSpawn = false
playerInfoGui.IgnoreGuiInset = true
playerInfoGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- 📋 信息面板
local infoFrame = Instance.new("Frame", playerInfoGui)
infoFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
infoFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
infoFrame.BackgroundColor3 = Colors.Background
infoFrame.BackgroundTransparency = Colors.Alpha
infoFrame.BorderSizePixel = 0
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
infoLabel.Text = "Loading..."

-- 💻 平台映射表
local PLATFORM_MAP = {
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
local function getPlatformInfo()
	local uis = Services.UserInputService
	local platform = uis:GetPlatform()
	local currentPlatform = PLATFORM_MAP[platform] or PLATFORM_MAP[Enum.Platform.None]

	local localTime = DateTime.now():ToLocalTime()
	local formattedTime = string.format("%d年%d月%d日 %02d:%02d:%02d",
		localTime.Year, localTime.Month, localTime.Day,
		localTime.Hour, localTime.Minute, localTime.Second)

	local executor = identifyexecutor and identifyexecutor() or "未知执行器"
	local inputDevices = {}
	if uis.TouchEnabled then table.insert(inputDevices, "触屏") end
	if uis.KeyboardEnabled then table.insert(inputDevices, "键盘") end
	if uis.MouseEnabled then table.insert(inputDevices, "鼠标") end
	if uis.GamepadEnabled then table.insert(inputDevices, "手柄") end

	local inputDesc = #inputDevices > 0 and table.concat(inputDevices, " | ") or "无特殊输入"

	return formattedTime, executor, currentPlatform.name .. " | 类别: " .. currentPlatform.category, tostring(platform), inputDesc
end

-- 🕒 格式化在线时间
local function formatTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d时%02d分%02d秒", h, m, s)
end

-- 🧩 收集玩家数据
local function collectPlayerData()
	local player = localPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	local userName, displayName, userId = player.Name, player.DisplayName, player.UserId
	local accountAge, clientId = player.AccountAge, Services.AnalyticsService:GetClientId()
	local position = rootPart and rootPart.Position or Vector3.new(0, 0, 0)

	local placeId = game.PlaceId
	local ok, placeInfo = pcall(function()
		return Services.MarketplaceService:GetProductInfo(placeId)
	end)
	local placeName = ok and placeInfo.Name or "未知游戏"

	local playerCount = #Services.Players:GetPlayers()
	local userAgent = Services.HttpService:GetUserAgent()
	local currentTime, executor, platformDesc, platformEnum, inputDesc = getPlatformInfo()

	local sessionTime = tick() - joinTime
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
		clientId = clientId,
		placeId = placeId,
		placeName = placeName,
		playerCount = playerCount,
		userAgent = userAgent,
		currentTime = currentTime,
		executor = executor,
		platformDesc = platformDesc,
		inputDesc = inputDesc,
		platformEnum = platformEnum,
		position = string.format("(%.1f, %.1f, %.1f)", position.X, position.Y, position.Z),
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

<font color="rgb(255,255,255)" size="20"><b>🕹️ 游戏信息</b></font>
<font color="rgb(0,255,0)">生命值:</font> %d / %d
<font color="rgb(0,255,255)">玩家坐标:</font> %s
<font color="rgb(255,182,193)">在线时长:</font> %s
<font color="rgb(255,215,0)">游戏名称:</font> %s
<font color="rgb(255,165,0)">服务器ID:</font> %d
<font color="rgb(0,255,0)">当前玩家数:</font> %d

<font color="rgb(255,255,255)" size="20"><b>⚙️ 系统信息</b></font>
<font color="rgb(255,140,0)">Ping 延迟:</font> %d ms
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
		d.userName, d.displayName, d.userId, d.accountAge,
		d.health, d.maxHealth, d.position, d.sessionTime,
		d.placeName, d.placeId, d.playerCount,
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
	while task.wait(1) do
		if playerInfoGui.Parent then
			pcall(updatePlayerInfo)
		else
			break
		end
	end
end)

-- 🎛️ 按钮面板
local buttonPanel = Instance.new("Frame", playerInfoGui)
buttonPanel.Size = UDim2.new(0, 120, 0, 170)
buttonPanel.AnchorPoint = Vector2.new(0.5, 0.5)
buttonPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
buttonPanel.BackgroundTransparency = 1

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
	if onClick then btn.MouseButton1Click:Connect(onClick) end
	return btn
end

local hidden = false
local copyButton = createButton("复制数据", 0, Color3.new(0,1,0), function()
	setclipboard(infoLabel.Text:gsub("<.->", ""))
end)
local consoleButton = createButton("控制台", 40, Color3.new(1,1,0.5), function()
	pcall(function() Services.VirtualInputManager:SendKeyEvent(true, "F9", false, game) end)
end)
local closeButton = createButton("关闭UI", 80, Color3.new(1,0,0), function()
	playerInfoGui:Destroy()
end)
local hideButton = createButton("隐藏UI", 120, Color3.new(1,0.5,0))

-- 🎯 拖动逻辑（移动端 + PC）
local dragging, dragStart, initPos
local function clampToScreen(x, y)
	local vs = workspace.CurrentCamera.ViewportSize
	local hw, hh = buttonPanel.AbsoluteSize.X / 2, buttonPanel.AbsoluteSize.Y / 2
	return math.clamp(x, hw, vs.X - hw), math.clamp(y, hh, vs.Y - hh)
end

hideButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragStart = input.Position
		initPos = buttonPanel.Position
		local conn
		conn = Services.UserInputService.InputChanged:Connect(function(move)
			if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
				local delta = move.Position - dragStart
				if delta.Magnitude > 10 then dragging = true end
				if dragging then
					local newX = initPos.X.Offset + delta.X
					local newY = initPos.Y.Offset + delta.Y
					local cx, cy = clampToScreen(newX, newY)
					buttonPanel.Position = UDim2.new(0, cx, 0, cy)
				end
			end
		end)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				conn:Disconnect()
				if not dragging then
					hidden = not hidden
					for _,v in ipairs({infoFrame, copyButton, consoleButton, closeButton}) do
						v.Visible = not hidden
					end
					hideButton.Text = hidden and "显示UI" or "隐藏UI"
				end
				dragging = false
			end
		end)
	end
end)

--[[
  Auto Interact v2.1
  By inltree｜Lin × ChatGPT (GPT-5)
  🧩 多线程优化版本
]]

local config = getgenv().inltree_AutoInteract or {
	autoClick = false,
	autoTrigger = false,
	deepScan = false,
	radius = 100,
	interval = 0.1,
    maxThreads = 50,
	activeThreads = 0,
	running = false,
	minimized = false
}
getgenv().inltree_AutoInteract = config

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local coreGui = game.CoreGui
local inputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

-- 线程管理
local threadPool = {}
local function waitForThreadSlot()
	while config.activeThreads >= config.maxThreads do
		task.wait(0.1)
	end
end

local function createThread(func, ...)
	waitForThreadSlot()
	config.activeThreads += 1
	local thread = task.spawn(function(...)
		local success, err = pcall(func, ...)
		config.activeThreads -= 1
		if not success then
			warn("[inltree] ❌ 自动交互｜线程执行错误:", err)
		end
	end, ...)
	
	table.insert(threadPool, thread)
	return thread
end

local function cleanupThreads()
	for i = #threadPool, 1, -1 do
		if coroutine.status(threadPool[i]) == "dead" then
			table.remove(threadPool, i)
		end
	end
end

local function waitForCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	return char, char:WaitForChild("HumanoidRootPart")
end

local character, rootPart = waitForCharacter()
player.CharacterAdded:Connect(function(char)
	character, rootPart = char, char:WaitForChild("HumanoidRootPart")
end)

local function doInteract(obj)
	if obj:IsA("ClickDetector") and config.autoClick then
		createThread(function()
			pcall(fireclickdetector, obj)
		end)
	elseif obj:IsA("ProximityPrompt") and config.autoTrigger then
		createThread(function()
			pcall(fireproximityprompt, obj)
		end)
	end
end

local function getPos(target)
	if not target then return nil end
	if target:IsA("BasePart") then
		return target.Position
	elseif target:IsA("Attachment") and target.Parent:IsA("BasePart") then
		return target.Parent.Position
	elseif target:IsA("Model") and target.PrimaryPart then
		return target.PrimaryPart.Position
	end
	return nil
end

local function scanObject(obj)
	if not rootPart or not rootPart.Parent then return end
	createThread(function()
		local target = obj.Parent
		local pos = getPos(target)
		if pos and (pos - rootPart.Position).Magnitude <= config.radius then
			doInteract(obj)
		end
	end)
end

local function deepScanObject(obj)
	if not rootPart or not rootPart.Parent then return end
	createThread(function()
		for _, child in ipairs(obj:GetDescendants()) do
			if not config.running then break end
			if child:IsA("ClickDetector") or child:IsA("ProximityPrompt") then
				createThread(function()
					local pos = getPos(child.Parent)
					if pos and (pos - rootPart.Position).Magnitude <= config.radius then
						doInteract(child)
					end
				end)
			end
		end
	end)
end

local scanThread
local function startScan()
	if scanThread then 
		stopScan()
		task.wait(0.1)
	end
	config.running = true
	scanThread = task.spawn(function()
		while config.running do
			if not rootPart or not rootPart.Parent then break end
			
			createThread(function()
				for _, obj in ipairs(workspace:GetDescendants()) do
					if not config.running then break end
					if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
						createThread(function()
							if config.deepScan then
								deepScanObject(obj)
							else
								scanObject(obj)
							end
						end)
					end
				end
			end)
			
			task.wait(config.interval)
			cleanupThreads()
		end
		scanThread = nil
	end)
end

local function stopScan()
	config.running = false
	repeat
		task.wait(0.1)
		cleanupThreads()
	until config.activeThreads == 0
end

-- 新对象添加时的处理
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
		createThread(function()
			task.wait(0.1)
			if config.running then
				if config.deepScan then
					deepScanObject(obj)
				else
					scanObject(obj)
				end
			end
		end)
	end
end)

-- GUI部分
if coreGui:FindFirstChild("inltree_AutoInteract_UI") then
	coreGui.inltree_AutoInteract_UI:Destroy()
end

local gui = Instance.new("ScreenGui", coreGui)
gui.Name = "inltree_AutoInteract_UI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

local screen = workspace.CurrentCamera.ViewportSize
local width, height = 220, 280
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, width, 0, height)
frame.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
frame.BorderColor3 = Color3.fromRGB(80, 80, 90)
frame.BorderSizePixel = 2
frame.Active, frame.Draggable = true, true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font, title.TextSize, title.TextXAlignment = Enum.Font.SourceSansBold, 18, Enum.TextXAlignment.Left
title.Text = "自动交互控制 v2.1"

local minimizeBtn = Instance.new("TextButton", title)
minimizeBtn.Size = UDim2.new(0, 35, 1, 0)
minimizeBtn.Position = UDim2.new(1, -75, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
minimizeBtn.TextColor3, minimizeBtn.Text, minimizeBtn.Font, minimizeBtn.TextSize = Color3.new(1,1,1), config.minimized and "➕" or "➖", Enum.Font.SourceSansBold, 20

local closeBtn = Instance.new("TextButton", title)
closeBtn.Size = UDim2.new(0, 35, 1, 0)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.TextColor3, closeBtn.Text, closeBtn.Font, closeBtn.TextSize = Color3.new(1,1,1), "✖️", Enum.Font.SourceSansBold, 20

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1

local function makeToggle(label, value, callback, y)
	local btn = Instance.new("TextButton", content)
	btn.Size = UDim2.new(0.9, 0, 0, 28)
	btn.Position = UDim2.new(0.05, 0, 0, y)
	btn.BackgroundColor3 = value and Color3.fromRGB(60,180,60) or Color3.fromRGB(120,60,60)
	btn.BorderColor3 = Color3.fromRGB(70,70,80)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font, btn.TextSize = Enum.Font.SourceSansBold, 16
	btn.Text = label .. "：" .. (value and "ON" or "OFF")

	btn.MouseButton1Click:Connect(function()
		value = not value
		callback(value)
		btn.BackgroundColor3 = value and Color3.fromRGB(60,180,60) or Color3.fromRGB(120,60,60)
		btn.Text = label .. "：" .. (value and "ON" or "OFF")
	end)
end

local function makeInput(label, value, callback, y)
	local lbl = Instance.new("TextLabel", content)
	lbl.Size = UDim2.new(0.9, 0, 0, 20)
	lbl.Position = UDim2.new(0.05, 0, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text, lbl.TextColor3, lbl.Font, lbl.TextSize, lbl.TextXAlignment =
		label, Color3.new(1,1,1), Enum.Font.SourceSansBold, 15, Enum.TextXAlignment.Left

	local box = Instance.new("TextBox", content)
	box.Size = UDim2.new(0.9, 0, 0, 25)
	box.Position = UDim2.new(0.05, 0, 0, y + 20)
	box.BackgroundColor3 = Color3.fromRGB(65,65,75)
	box.BorderColor3 = Color3.fromRGB(100,100,110)
	box.Text = tostring(value)
	box.TextColor3, box.Font, box.TextSize, box.ClearTextOnFocus = Color3.new(1,1,1), Enum.Font.SourceSans, 15, false

	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num then
			callback(num)
			value = num
		else
			box.Text = tostring(value)
		end
	end)
end

makeToggle("自动点击", config.autoClick, function(v) config.autoClick = v end, 15)
makeToggle("自动触发", config.autoTrigger, function(v) config.autoTrigger = v end, 50)
makeToggle("深层检索", config.deepScan, function(v) config.deepScan = v end, 85)

makeInput("扫描半径", config.radius, function(v) config.radius = math.clamp(v, 0.01, 1440) end, 120)
makeInput("扫描间隔", config.interval, function(v) config.interval = math.clamp(v, 0.01, 1440) end, 155)
makeInput("最大线程", config.maxThreads, function(v) config.maxThreads = math.clamp(v, 1, 1440) end, 190)

-- 控制线程
local controlThread = task.spawn(function()
	while task.wait(0.5) do
		if not gui or not gui.Parent then break end
		
		if config.deepScan or config.autoClick or config.autoTrigger then
			if not config.running then 
				startScan() 
			end
		else
			if config.running then 
				stopScan() 
			end
		end
	end
end)

-- 最小化/关闭/快捷键隐藏功能
local function toggleMinimize()
	config.minimized = not config.minimized
	minimizeBtn.Text = config.minimized and "➕" or "➖"
	local newSize = config.minimized and UDim2.new(0, width, 0, 35) or UDim2.new(0, width, 0, height)
	tweenService:Create(frame, TweenInfo.new(0.25), { Size = newSize }):Play()
	content.Visible = not config.minimized
end
minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
	config.autoClick = false
	config.autoTrigger = false
	config.deepScan = false
	config.running = false

	if controlThread then 
		task.cancel(controlThread) 
	end
	stopScan()
	task.wait(0.1)
	if gui and gui.Parent then 
		gui:Destroy() 
	end
end)

local hidden = false
inputService.InputBegan:Connect(function(key, processed)
	if processed then return end
	if key.KeyCode == Enum.KeyCode.RightShift then
		hidden = not hidden
		frame.Visible = not hidden
	end
end)

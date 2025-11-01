--[[
   Player Teleport Tool v1.0.0
   By inltree｜Lin × ChatGPT (GPT-5)
   🔁 多目标循环传送
]]

local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local tweenService = game:GetService("TweenService")
local inputService = game:GetService("UserInputService")

local completelyStopped = false
--------------------------------------------------------
-- 角色加载
--------------------------------------------------------
local character, rootPart
local function waitForCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	rootPart = character:WaitForChild("HumanoidRootPart")
	return character, rootPart
end
waitForCharacter()
player.CharacterAdded:Connect(function(char)
	character = char
	rootPart = char:WaitForChild("HumanoidRootPart")
end)
--------------------------------------------------------
-- GUI 初始化
--------------------------------------------------------
if coreGui:FindFirstChild("inltree_Player_Teleport_UI") then
	coreGui.inltree_Teleport_UI:Destroy()
end

local gui = Instance.new("ScreenGui", coreGui)
gui.Name = "inltree_Player_Teleport_UI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

local width, height = 220, 180
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
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "玩家传送 v1.0"

local minimizeBtn = Instance.new("TextButton", title)
minimizeBtn.Size = UDim2.new(0, 35, 1, 0)
minimizeBtn.Position = UDim2.new(1, -75, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
minimizeBtn.TextColor3, minimizeBtn.Text = Color3.new(1,1,1), "➖"
minimizeBtn.Font, minimizeBtn.TextSize = Enum.Font.SourceSansBold, 20

local closeBtn = Instance.new("TextButton", title)
closeBtn.Size = UDim2.new(0, 35, 1, 0)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.TextColor3, closeBtn.Text = Color3.new(1,1,1), "✖️"
closeBtn.Font, closeBtn.TextSize = Enum.Font.SourceSansBold, 20

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1
--------------------------------------------------------
-- 通用函数
--------------------------------------------------------
local function makeInput(label, default, y, callback)
	local lbl = Instance.new("TextLabel", content)
	lbl.Size = UDim2.new(0.9, 0, 0, 20)
	lbl.Position = UDim2.new(0.05, 0, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextSize = 15
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local box = Instance.new("TextBox", content)
	box.Size = UDim2.new(0.9, 0, 0, 25)
	box.Position = UDim2.new(0.05, 0, 0, y + 20)
	box.BackgroundColor3 = Color3.fromRGB(65,65,75)
	box.BorderColor3 = Color3.fromRGB(100,100,110)
	box.TextColor3 = Color3.new(1,1,1)
	box.Font = Enum.Font.SourceSans
	box.TextSize = 15
	box.ClearTextOnFocus = false
	box.Text = tostring(default)

	box.Focused:Connect(function()
		box.Text = ""
	end)

	box.FocusLost:Connect(function()
		callback(box.Text)
	end)
	return box
end

local function makeToggleButton(label, y, colorOn, colorOff, callback)
	local lbl = Instance.new("TextLabel", content)
	lbl.Size = UDim2.new(0.6, 0, 0, 30)
	lbl.Position = UDim2.new(0.05, 0, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextSize = 15
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", content)
	btn.Size = UDim2.new(0.3, 0, 0, 30)
	btn.Position = UDim2.new(0.65, 0, 0, y)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 15
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = "OFF"
	btn.BackgroundColor3 = colorOff
	btn.BorderColor3 = Color3.fromRGB(70,70,80)

	local state = false
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and colorOn or colorOff
		callback(state)
	end)
	return btn
end
--------------------------------------------------------
-- 核心逻辑
--------------------------------------------------------
local distance = 3
local interval = 0.01
local targets = {}
local running = false

local function teleportPlayerToFront(targetPlayer)
	if not rootPart or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local targetHRP = targetPlayer.Character.HumanoidRootPart
	local frontPos = rootPart.CFrame * CFrame.new(0, 0, -distance)
	targetHRP.CFrame = frontPos
end

local function teleportTargetPlayers()
	for _, p in ipairs(game.Players:GetPlayers()) do
		if p ~= player then
			for _, name in ipairs(targets) do
				if string.find(string.lower(p.Name), name)
				or string.find(string.lower(p.DisplayName), name) then
					teleportPlayerToFront(p)
				end
			end
		end
	end
end

local function teleportAllPlayers()
	for _, p in ipairs(game.Players:GetPlayers()) do
		if p ~= player then
			teleportPlayerToFront(p)
		end
	end
end
--------------------------------------------------------
-- GUI 控件布局
--------------------------------------------------------
makeInput("目标玩家(多个英文逗号分隔，可模糊)", "", 20, function(text)
	targets = {}
	for name in string.gmatch(text, '([^,%s]+)') do
		table.insert(targets, string.lower(name))
	end
end)

makeToggleButton("循环传送", 80, Color3.fromRGB(60,180,80), Color3.fromRGB(100,100,100), function(state)
	running = state
end)
--------------------------------------------------------
-- 循环执行
--------------------------------------------------------
task.spawn(function()
	while not completelyStopped do
		task.wait(interval)
		if running then
			if #targets == 0 then
				teleportAllPlayers()
			else
				teleportTargetPlayers()
			end
		end
	end
end)
--------------------------------------------------------
-- 最小化与关闭
--------------------------------------------------------
local minimized = false
local function toggleMinimize()
	minimized = not minimized
	minimizeBtn.Text = minimized and "➕" or "➖"
	local newSize = minimized and UDim2.new(0, width, 0, 35) or UDim2.new(0, width, 0, height)
	tweenService:Create(frame, TweenInfo.new(0.25), { Size = newSize }):Play()
	content.Visible = not minimized
end
minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
	completelyStopped = true
	if gui then gui:Destroy() end
end)

local hidden = false
inputService.InputBegan:Connect(function(key, processed)
	if processed then return end
	if key.KeyCode == Enum.KeyCode.RightShift then
		hidden = not hidden
		frame.Visible = not hidden
	end
end)

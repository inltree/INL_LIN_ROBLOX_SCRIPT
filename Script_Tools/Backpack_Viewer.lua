--[[
   loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Backpack-and-Healthbar-Viewer-48870"))()

   Link：https://scriptblox.com/script/Universal-Script-Backpack-and-Healthbar-Viewer-48870
]]--

--// services
local ts = game:GetService("TweenService")
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")

--// config
local lp = players.LocalPlayer
if not lp then return end

local CONFIG = {
	distance = 16,
	scrollSpeed = 20,
	animTime = 0.3,
	platforms = {
		PC = {"rbxassetid://10688463768", Color3.fromRGB(80, 140, 220)},
		Mobile = {"rbxassetid://10688464303", Color3.fromRGB(80, 220, 120)},
		Console = {"rbxassetid://10688463319", Color3.fromRGB(220, 80, 80)},
		Unknown = {"", Color3.fromRGB(150, 150, 150)}
	}
}

--// 'secret' state management
_G.BillboardState = {
	enabled = true,
	uis = {}, -- { [Player]: { gui, root, main, currentState, tweens } }
	activeScroller = nil
}

--// functions
local function getPlayerPlatform(player)
	local platform = "Unknown"
	if player.GameplayPaused then platform = "Mobile" end
	if uis:GetPlatform() == Enum.Platform.Windows and player == lp then platform = "PC" end
	return platform
end

local function animate(state, direction)
	if state.tweens then
		for _, t in ipairs(state.tweens) do t:Cancel() end
	end
	state.tweens = {}

	local transparencyGoal, sizeGoal
	if direction == "in" then
		transparencyGoal, sizeGoal = 0.2, UDim2.fromScale(1, 1)
	else
		transparencyGoal, sizeGoal = 1, UDim2.fromScale(0.8, 0.8)
	end
	
	local transparencyTween = ts:Create(state.main, TweenInfo.new(CONFIG.animTime, Enum.EasingStyle.Quint), {BackgroundTransparency = transparencyGoal})
	local sizeTween = ts:Create(state.root, TweenInfo.new(CONFIG.animTime, Enum.EasingStyle.Quint), {Size = sizeGoal})

	table.insert(state.tweens, transparencyTween)
	table.insert(state.tweens, sizeTween)
	
	transparencyTween:Play()
	sizeTween:Play()
	
	return sizeTween
end

local function createElements(player)
	local state = { currentState = "hidden", tweens = {} }
	
	state.gui = Instance.new("BillboardGui")
	state.gui.Name, state.gui.AlwaysOnTop = "PlayerInfo", true
	state.gui.Size, state.gui.StudsOffset = UDim2.fromOffset(200, 80), Vector3.new(0, 2.2, 0)

	state.root = Instance.new("Frame", state.gui)
	state.root.Name, state.root.BackgroundTransparency = "Root", 1
	state.root.ClipsDescendants, state.root.AnchorPoint = true, Vector2.new(0.5, 0.5)
	state.root.Position, state.root.Size = UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8)

	state.main = Instance.new("Frame", state.root)
	state.main.Name, state.main.Size = "Main", UDim2.fromScale(1, 1)
	state.main.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
	state.main.Active, state.main.BackgroundTransparency = true, 1
	Instance.new("UICorner", state.main).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", state.main).Color = Color3.fromRGB(10, 11, 13)

	local platformIcon = Instance.new("ImageLabel", state.main)
	platformIcon.Name, platformIcon.Size = "PlatformIcon", UDim2.fromOffset(14, 14)
	platformIcon.Position, platformIcon.BackgroundTransparency = UDim2.new(0, 4, 0, 4), 1

	local healthBar = Instance.new("Frame", state.main)
	healthBar.Name = "HealthBar"
	-- FIX: Positioned at the top center
	healthBar.Size = UDim2.new(0.8, 0, 0, 8)
	healthBar.Position = UDim2.new(0.5, 0, 0, 4)
	healthBar.AnchorPoint = Vector2.new(0.5, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(10, 11, 13)
	Instance.new("UICorner", healthBar).CornerRadius = UDim.new(1, 0)
	
	local healthFill = Instance.new("Frame", healthBar)
	healthFill.Name, healthFill.Size = "Fill", UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
	Instance.new("UICorner", healthFill).CornerRadius = UDim.new(1, 0)
	
	local scroller = Instance.new("ScrollingFrame", state.main)
	scroller.Name = "Backpack"
	-- FIX: Adjusted to fit below the new healthbar position
	scroller.Size = UDim2.new(1, -10, 1, -18)
	scroller.Position = UDim2.new(0.5, 0, 1, -4)
	scroller.AnchorPoint = Vector2.new(0.5, 1)
	scroller.BackgroundTransparency, scroller.BorderSizePixel = 1, 0
	scroller.ScrollBarThickness, scroller.AutomaticCanvasSize = 4, Enum.AutomaticSize.Y
	scroller.MouseEnter:Connect(function() _G.BillboardState.activeScroller = scroller end)
	scroller.MouseLeave:Connect(function() _G.BillboardState.activeScroller = nil end)

	local grid = Instance.new("UIGridLayout", scroller)
	grid.CellSize, grid.CellPadding = UDim2.fromOffset(28, 28), UDim2.fromOffset(4, 4)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local tooltip = Instance.new("TextLabel", scroller)
	tooltip.Name, tooltip.Size = "Tooltip", UDim2.new(1, 0, 0, 20)
	tooltip.Position, tooltip.BackgroundColor3 = UDim2.new(0, 0, 1, 22), Color3.fromRGB(10, 11, 13)
	tooltip.Font, tooltip.TextColor3, tooltip.TextSize = Enum.Font.SourceSans, Color3.new(1, 1, 1), 14
	tooltip.Visible = false
	Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 4)
	
	_G.BillboardState.uis[player] = state
	return state
end

local function updateUI(player, char)
	if not _G.BillboardState.enabled then return end
	local state = _G.BillboardState.uis[player]
	if not (state and state.gui) then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local health = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		local fill = state.main.HealthBar.Fill
		fill.Size = UDim2.fromScale(health, 1)
		fill.BackgroundColor3 = Color3.fromHSV(0.33 * health, 0.7, 0.8)
	end
	
	local pData = CONFIG.platforms[getPlayerPlatform(player)]
	local pIcon = state.main.PlatformIcon
	pIcon.Image, pIcon.ImageColor3 = pData[1], pData[2]

	local scroller = state.main.Backpack
	local tooltip = scroller.Tooltip
	for _, child in scroller:GetChildren() do
		if child:IsA("ImageButton") then child:Destroy() end
	end
	
	for _, tool in player.Backpack:GetChildren() do
		if tool:IsA("Tool") then
			local icon = Instance.new("ImageButton", scroller)
			icon.Size, icon.BackgroundTransparency, icon.Image = UDim2.fromScale(1, 1), 1, tool.TextureId
			icon.MouseEnter:Connect(function() tooltip.Text, tooltip.Visible, tooltip.Parent = tool.Name, true, icon end)
			icon.MouseLeave:Connect(function() tooltip.Visible, tooltip.Parent = false, scroller end)
			icon.MouseButton1Click:Connect(function() tool:Clone().Parent = lp.Backpack end)
		end
	end
end

--// main loop
rs.Heartbeat:Connect(function()
	if not _G.BillboardState.enabled then return end
	local localChar = lp.Character
	if not (localChar and localChar.PrimaryPart) then return end
	local localPos = localChar.PrimaryPart.Position
	
	for _, player in players:GetPlayers() do
		if player == lp then continue end
		
		local state = _G.BillboardState.uis[player] or createElements(player)
		local char = player.Character

		if char and char.PrimaryPart and char:FindFirstChild("Head") then
			local dist = (localPos - char.PrimaryPart.Position).Magnitude
			
			if dist <= CONFIG.distance and state.currentState == "hidden" then
				state.currentState = "visible"
				state.gui.Adornee = char.Head
				state.gui.Parent = char.Head
				animate(state, "in")
			elseif dist > CONFIG.distance and state.currentState == "visible" then
				state.currentState = "hidden"
				local tween = animate(state, "out")
				tween.Completed:Wait()
				if state.currentState == "hidden" then state.gui.Parent = nil end
			end

			if state.currentState == "visible" then updateUI(player, char) end
		elseif state.currentState == "visible" then
			state.currentState = "hidden"
			state.gui.Parent = nil
		end
	end
end)

--// controller & cleanup
uis.InputChanged:Connect(function(input)
	if not _G.BillboardState.enabled or not _G.BillboardState.activeScroller then return end
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Gamepad1_Thumbstick2 then
		local scroller = _G.BillboardState.activeScroller
		scroller.CanvasPosition -= Vector2.new(0, input.Position.Y * CONFIG.scrollSpeed)
	end
end)

players.PlayerRemoving:Connect(function(player)
	if _G.BillboardState.uis[player] then
		_G.BillboardState.uis[player].gui:Destroy()
		_G.BillboardState.uis[player] = nil
	end
end)

lp.Chatted:Connect(function(msg)
	if msg == "#FreeSchlep" and _G.BillboardState.enabled then
		_G.BillboardState.enabled = false
		for _, state in pairs(_G.BillboardState.uis) do state.gui:Destroy() end
		_G.BillboardState.uis = {}
	end
end)
-- SimpleGUI.lua - 专业级 Roblox UI 库（长按打开设置面板）
-- 特性：长按按钮 → 专属设置面板（输入框、滑块、选项卡、点击按钮）
-- 风格：极简黑白灰 + 青蓝高亮 | CoreGui | 高性能

local SimpleGUI = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- 全局
local player = Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local gui = nil
local menus = {}
local panels = {}
local dragStates = {}

-- 配置
local config = {
    primary = Color3.fromRGB(0, 130, 230),
    background = Color3.fromRGB(28, 28, 28),
    surface = Color3.fromRGB(42, 42, 42),
    text = Color3.fromRGB(255, 255, 255),
    textSecondary = Color3.fromRGB(160, 160, 160),
    font = Enum.Font.Gotham,
    textSize = 14,
    menuWidth = 160,
    buttonHeight = 36,
    longPressTime = 0.5,
    panelWidth = 320,
    panelMinHeight = 200,
}

-- 工具
local function uid() return HttpService:GenerateGUID(false):gsub("-", "") end
local function corner(r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 6) return c end
local function stroke(t, col) local s=Instance.new("UIStroke") s.Thickness=t or 1 s.Color=col or config.primary s.Transparency=0.7 return s end

-- 初始化
function SimpleGUI.init(custom)
    if gui then gui:Destroy() end
    if custom then for k,v in pairs(custom) do config[k]=v end end
    gui = Instance.new("ScreenGui")
    gui.Name = "SimpleGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = coreGui
    return SimpleGUI
end

-- 拖动系统
local function enableDrag(frame, header)
    local id = uid()
    local state = { dragging = false, startPos = nil, startMouse = nil }

    local function start(i) state.dragging = true; state.startMouse = i.Position; state.startPos = frame.Position; frame.ZIndex = 100 end
    local function move(i)
        if not state.dragging then return end
        local d = i.Position - state.startMouse
        frame.Position = UDim2.new(state.startPos.X.Scale, state.startPos.X.Offset + d.X, state.startPos.Y.Scale, state.startPos.Y.Offset + d.Y)
    end
    local function stop() if state.dragging then state.dragging = false; frame.ZIndex = 10 end end

    local pressTime, conn
    header.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
        pressTime = tick()
        conn = RunService.Heartbeat:Connect(function()
            if tick() - pressTime >= config.longPressTime then
                conn:Disconnect()
                start(i)
            end
        end)
    end)
    header.InputEnded:Connect(function(i)
        if conn then conn:Disconnect() end
        if tick() - pressTime < config.longPressTime then return end
        stop()
    end)

    UserInputService.InputChanged:Connect(function(i)
        if state.dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            move(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then stop() end
    end)

    dragStates[id] = state
end

-- 按钮
local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, config.buttonHeight)
    btn.BackgroundColor3 = config.surface
    btn.Text = text
    btn.TextColor3 = config.text
    btn.TextSize = config.textSize
    btn.Font = config.font
    btn.Parent = parent
    corner(4).Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = config.primary:lerp(Color3.fromRGB(255,255,255), 0.9) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = config.surface end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

-- 通知
function SimpleGUI.notify(title, msg, success)
    local n = Instance.new("Frame")
    n.Size = UDim2.new(0, 220, 0, 50)
    n.Position = UDim2.new(1, 240, 1, -70)
    n.BackgroundColor3 = config.background
    n.ZIndex = 200
    n.Parent = gui
    corner(6).Parent = n
    stroke(1, success and config.primary or config.textSecondary).Parent = n

    Instance.new("TextLabel", n).Setup = function(self)
        self.Size = UDim2.new(1, -16, 0, 20)
        self.Position = UDim2.new(0, 8, 0, 5)
        self.BackgroundTransparency = 1
        self.Text = title
        self.TextColor3 = config.text
        self.TextSize = 13
        self.Font = config.font
    end

    Instance.new("TextLabel", n).Setup = function(self)
        self.Size = UDim2.new(1, -16, 0, 18)
        self.Position = UDim2.new(0, 8, 0, 25)
        self.BackgroundTransparency = 1
        self.Text = msg
        self.TextColor3 = success and config.primary or config.textSecondary
        self.TextSize = 11
        self.Font = config.font
    end

    for _, child in ipairs(n:GetChildren()) do
        if child.Setup then child:Setup() end
    end

    TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(1, -230, 1, -70)}):Play()
    task.delay(2, function()
        local out = TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(1, 240, 1, -70)})
        out:Play()
        out.Completed:Connect(function() n:Destroy() end)
    end)
end

-- 滑块
function SimpleGUI.createSlider(parent, label, min, max, step, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = config.text
    lbl.TextSize = 12
    lbl.Font = config.font
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 40, 0, 20)
    val.Position = UDim2.new(1, -45, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = config.primary
    val.TextSize = 12
    val.Font = config.font
    val.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -10, 0, 6)
    track.Position = UDim2.new(0, 5, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(65,65,65)
    track.Parent = frame
    corner(3).Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default-min)/(max-min), -8, 0.5, -8)
    knob.BackgroundColor3 = config.primary
    knob.Parent = track
    corner(8).Parent = knob

    local dragging = false
    local function update(pos)
        local rel = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * rel
        v = math.floor(v / step) * step
        v = math.clamp(v, min, max)
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        val.Text = string.format("%.2f", v):gsub("%.00$", "")
        if callback then callback(v) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(i.Position)
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position)
        end
    end)

    return frame
end

-- 输入框（面板内）
function SimpleGUI.createInput(parent, label, default, isNumber, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = config.text
    lbl.TextSize = 12
    lbl.Font = config.font
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 0, 28)
    box.Position = UDim2.new(0, 5, 0, 20)
    box.BackgroundColor3 = config.surface
    box.Text = tostring(default)
    box.TextColor3 = config.text
    box.TextSize = 13
    box.Font = config.font
    box.Parent = frame
    corner(4).Parent = box

    box.FocusLost:Connect(function(enter)
        if not enter then return end
        local value = box.Text
        if isNumber then
            value = tonumber(value)
            if not value then
                SimpleGUI.notify("错误", "请输入数字", false)
                box.Text = tostring(default)
                return
            end
        end
        if callback then callback(value) end
    end)

    return frame
end

-- 选项卡
function SimpleGUI.createTabs(parent, tabs)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 36)
    bar.BackgroundColor3 = config.surface
    bar.Parent = container
    corner(6).Parent = bar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -36)
    content.Position = UDim2.new(0, 0, 0, 36)
    content.BackgroundTransparency = 1
    content.Parent = container

    local activePage = nil
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.Position = UDim2.new(0, (i-1)*82, 0, 0)
        btn.BackgroundColor3 = config.surface
        btn.Text = tab.name
        btn.TextColor3 = config.textSecondary
        btn.TextSize = 12
        btn.Font = config.font
        btn.Parent = bar

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = content

        btn.MouseButton1Click:Connect(function()
            if activePage then activePage.Visible = false end
            page.Visible = true
            activePage = page
            for _, b in ipairs(bar:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = config.surface
                    b.TextColor3 = config.textSecondary
                end
            end
            btn.BackgroundColor3 = config.primary
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            if tab.onOpen then tab.onOpen(page) end
        end)

        if i == 1 then btn.MouseButton1Click:Fire() end
    end

    return container
end

-- 创建菜单（支持长按打开面板）
function SimpleGUI.createMenu(title, options, position)
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, config.menuWidth, 0, config.buttonHeight)
    menu.Position = position or UDim2.new(0, 20, 0, 20)
    menu.BackgroundColor3 = config.background
    menu.ZIndex = 5
    menu.Parent = gui
    corner(8).Parent = menu
    stroke(1).Parent = menu

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, config.buttonHeight)
    header.BackgroundTransparency = 1
    header.Text = title
    header.TextColor3 = config.text
    header.TextSize = config.textSize + 2
    header.Font = config.font
    header.Parent = menu

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, config.buttonHeight)
    content.BackgroundTransparency = 1
    content.Parent = menu

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local expanded = false
    local buttons = {}

    for i, opt in ipairs(options) do
        local btn = createButton(content, opt.name, function()
            if opt.type == "toggle" then
                opt.active = not opt.active
                btn.BackgroundColor3 = opt.active and config.primary or config.surface
                if opt.callback then opt.callback(opt.active) end
                SimpleGUI.notify(opt.name, opt.active and "已开启" or "已关闭", opt.active)
            elseif opt.type == "action" and opt.callback then
                opt.callback()
            end
        end)
        btn.LayoutOrder = i
        table.insert(buttons, btn)

        -- 长按打开设置面板
        if opt.settings then
            local pressTime, conn
            btn.InputBegan:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
                pressTime = tick()
                conn = RunService.Heartbeat:Connect(function()
                    if tick() - pressTime >= config.longPressTime then
                        conn:Disconnect()
                        SimpleGUI.openSettingsPanel(opt.name .. " 设置", opt.settings, btn)
                    end
                end)
            end)
            btn.InputEnded:Connect(function(i)
                if conn then conn:Disconnect() end
            end)
        end
    end

    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        local h = expanded and #options * config.buttonHeight or 0
        TweenService:Create(menu, TweenInfo.new(0.25), {Size = UDim2.new(0, config.menuWidth, 0, config.buttonHeight + h)}):Play()
        TweenService:Create(content, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, h)}):Play()
    end)

    enableDrag(menu, header)
    menus[title] = menu
    return menu
end

-- 打开设置面板
function SimpleGUI.openSettingsPanel(title, components, sourceButton)
    if panels[title] then
        panels[title]:Destroy()
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, config.panelWidth, 0, config.panelMinHeight)
    panel.Position = UDim2.new(0, sourceButton.AbsolutePosition.X + sourceButton.AbsoluteSize.X + 10, 0, sourceButton.AbsolutePosition.Y)
    panel.BackgroundColor3 = config.background
    panel.ZIndex = 10
    panel.Parent = gui
    corner(10).Parent = panel
    stroke(2).Parent = panel

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = config.surface
    header.Text = " " .. title
    header.TextColor3 = config.text
    header.TextSize = 15
    header.Font = config.font
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = panel
    corner(10).Parent = header

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = config.textSecondary
    close.TextSize = 22
    close.Font = config.font
    close.Parent = header
    close.MouseButton1Click:Connect(function()
        panel:Destroy()
        panels[title] = nil
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -50)
    scroll.Position = UDim2.new(0, 5, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scroll

    -- 添加组件
    local totalHeight = 0
    for _, comp in ipairs(components) do
        if comp.type == "slider" then
            local s = SimpleGUI.createSlider(scroll, comp.label, comp.min, comp.max, comp.step, comp.default, comp.callback)
            totalHeight += 60
        elseif comp.type == "input" then
            local i = SimpleGUI.createInput(scroll, comp.label, comp.default, comp.isNumber, comp.callback)
            totalHeight += 60
        elseif comp.type == "button" then
            local b = createButton(scroll, comp.label, comp.callback)
            totalHeight += config.buttonHeight + 10
        elseif comp.type == "tabs" then
            local t = SimpleGUI.createTabs(scroll, comp.tabs)
            t.Position = UDim2.new(0, 0, 0, totalHeight)
            totalHeight += 300
        end
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
    enableDrag(panel, header)
    panels[title] = panel

    return panel
end

return SimpleGUI

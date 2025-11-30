--[[
    YC GUI Library - Optimized Pure Version
    仅保留性能/内存/交互/可维护性优化，不含任何注入器闪避或反作弊代码
]]
local Library = {}
local ConfigName = "YCUI/settings_adaptive.json"

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

----------------------------------------
-- 设计令牌：所有颜色/尺寸/字号统一入口
----------------------------------------
local DesignTokens = {
    CornerRadius = 10,
    StrokeThickness = 1.5,
    ScrollThickness = 6,
    HUDBarHeight = 22,
    HUDFont = Enum.Font.GothamBold,
    HUDTextSize = 18,
    RippleDuration = 0.4,
    SaveDelay = 0.8,
    MaxRipple = 20,
    MinDragDist = 15, -- 移动端误触像素
}

----------------------------------------
-- 弱表 + 对象池
----------------------------------------
local RipplePool = setmetatable({}, {__mode = "v"})
local function AcquireRipple()
    return #RipplePool > 0 and table.remove(RipplePool) or Instance.new("Frame")
end
local function ReleaseRipple(f)
    if #RipplePool < DesignTokens.MaxRipple then
        f:ClearAllChildren(); f.Size = UDim2.new(0, 0, 0, 0); f.Position = UDim2.new(0, 0, 0, 0)
        table.insert(RipplePool, f)
    else
        f:Destroy()
    end
end

----------------------------------------
-- 配置批保存
----------------------------------------
local lastSave = 0
local savePending = false
local function SaveConfigDeferred()
    if savePending then return end
    savePending = true
    task.wait(DesignTokens.SaveDelay)
    savePending = false
    pcall(function()
        writefile(ConfigName, HttpService:JSONEncode(Library.Config))
    end)
end

----------------------------------------
-- 默认配置
----------------------------------------
local DefaultConfig = {
    ShowHUD = true,
    ShowNotifs = true,
    NotifDuration = 3,
    UIScale = 1.0,
    WindowWidth = 180,
    WindowMaxHeight = 350,
    ItemHeight = 32,
    Theme = "Default",
    UIVisible = true,
    UseCorners = false,
    UseStroke = false,
}
Library.Config = HttpService:JSONDecode(HttpService:JSONEncode(DefaultConfig))

----------------------------------------
-- 全局弱表
----------------------------------------
Library.Globals = {
    Windows = {},
    Elements = {},
    ThemeObjects = setmetatable({}, {__mode = "v"}),
    StyleObjects = setmetatable({}, {__mode = "v"}),
    ActiveNotifs = setmetatable({}, {__mode = "v"}),
    HUDGradients = setmetatable({}, {__mode = "v"}),
    BoundKeys = {},
    IslandObject = nil,
    TopZIndex = 100,
    Connections = {}, -- 统一收事件
}

----------------------------------------
-- 主题
----------------------------------------
Library.Themes = {
    ["Default"] = {
        Main = Color3.fromRGB(20, 20, 25), MainTrans = 0.1,
        Text = Color3.fromRGB(255, 255, 255), TextDark = Color3.fromRGB(160, 160, 170),
        Accent = Color3.fromRGB(100, 20, 220),
    },
    ["Ocean"] = {
        Main = Color3.fromRGB(15, 25, 30), MainTrans = 0.1,
        Text = Color3.fromRGB(240, 255, 255), TextDark = Color3.fromRGB(140, 160, 170),
        Accent = Color3.fromRGB(0, 100, 180),
    },
}
local CurrentThemeData = Library.Themes["Default"]

----------------------------------------
-- 通用函数
----------------------------------------
local function RegisterConnection(conn)
    table.insert(Library.Globals.Connections, conn)
end
local function ClampToScreen(size)
    local vps = Camera.ViewportSize
    return UDim2.new(
        0, math.clamp(size.X.Offset, 0, vps.X - size.X.Offset),
        0, math.clamp(size.Y.Offset, 0, vps.Y - size.Y.Offset)
    )
end

----------------------------------------
-- UI 创建辅助
----------------------------------------
local function ApplyStyle(obj, hasStroke, radius)
    table.insert(Library.Globals.StyleObjects, {Object = obj, HasStroke = hasStroke, Radius = radius})
    local corner = obj:FindFirstChild("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Library.Config.UseCorners and radius or 0)
    corner.Parent = obj
    if hasStroke then
        local stroke = obj:FindFirstChild("UIStroke") or Instance.new("UIStroke")
        stroke.Thickness = DesignTokens.StrokeThickness
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = CurrentThemeData.Accent
        stroke.Transparency = Library.Config.UseStroke and 0 or 1
        stroke.Parent = obj
    end
end

local function RegisterTheme(obj, t)
    table.insert(Library.Globals.ThemeObjects, {Object = obj, Type = t})
    local theme = CurrentThemeData
    if t == "Window" then
        obj.BackgroundColor3 = theme.Main; obj.BackgroundTransparency = theme.MainTrans
    elseif t == "Text" then obj.TextColor3 = theme.Text
    elseif t == "TextDark" then obj.TextColor3 = theme.TextDark
    elseif t == "Accent" then obj.BackgroundColor3 = theme.Accent
    end
end

----------------------------------------
-- 涟漪
----------------------------------------
local function CreateRipple(btn, isCenter)
    local ripple = AcquireRipple()
    ripple.Parent = btn
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.8
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0); corner.Parent = ripple
    local pos = isCenter and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, UserInputService:GetMouseLocation().X - btn.AbsolutePosition.X, 0, UserInputService:GetMouseLocation().Y - btn.AbsolutePosition.Y)
    ripple.Position = pos
    ripple.Size = UDim2.new(0, 0, 0, 0)
    local size = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.5
    local tween = TweenService:Create(ripple, TweenInfo.new(DesignTokens.RippleDuration), {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1})
    tween:Play()
    tween.Completed:Connect(function()
        ripple.Parent = nil; ReleaseRipple(ripple)
    end)
end

----------------------------------------
-- 初始化 GUI
----------------------------------------
if CoreGui:FindFirstChild("YC_GUI_Adaptive") then CoreGui.YC_GUI_Adaptive:Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YC_GUI_Adaptive"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false
ScreenGui.Parent = CoreGui
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"; Backdrop.Parent = ScreenGui
Backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
Backdrop.BackgroundTransparency = 1
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.ZIndex = 0; Backdrop.Visible = false

----------------------------------------
-- HUD 梯度更新（合并到一次 RenderStep）
----------------------------------------
local function UpdateGradients()
    local t = tick() * 2; local phase = (math.sin(t) + 1) / 2
    local c1 = CurrentThemeData.Accent:Lerp(Color3.new(1, 1, 1), phase * 0.3)
    local seq = ColorSequence.new({ColorSequenceKeypoint.new(0, CurrentThemeData.Accent), ColorSequenceKeypoint.new(1, c1)})
    for _, g in ipairs(Library.Globals.HUDGradients) do
        if g and g.Parent then g.Color = seq; g.Rotation = -90 end
    end
end
RegisterConnection(RunService.RenderStepped:Connect(UpdateGradients))

----------------------------------------
-- 配置读写
----------------------------------------
local function LoadConfig()
    if isfile(ConfigName) then
        local s, r = pcall(function() return HttpService:JSONDecode(readfile(ConfigName)) end)
        if s and r then
            for k, v in pairs(r) do Library.Config[k] = v end
            CurrentThemeData = Library.Themes[Library.Config.Theme] or Library.Themes["Default"]
        end
    end
end
LoadConfig()

----------------------------------------
-- HUD
----------------------------------------
local HUDFrame = Instance.new("Frame")
HUDFrame.Name = "HUD"; HUDFrame.Parent = ScreenGui
HUDFrame.Position = UDim2.new(1, -10, 0, 50)
HUDFrame.AnchorPoint = Vector2.new(1, 0)
HUDFrame.Size = UDim2.new(0, 300, 1, -60)
HUDFrame.BackgroundTransparency = 1
HUDFrame.Visible = Library.Config.ShowHUD
local HUDLayout = Instance.new("UIListLayout")
HUDLayout.Parent = HUDFrame; HUDLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
HUDLayout.SortOrder = Enum.SortOrder.LayoutOrder; HUDLayout.Padding = UDim.new(0, 0)

local function UpdateHUD(name, enabled)
    if not Library.Config.ShowHUD then return end
    local old = HUDFrame:FindFirstChild(name)
    if enabled then
        if old then return end
        local w = TextService:GetTextSize(name, DesignTokens.HUDTextSize, DesignTokens.HUDFont, Vector2.new(1000, 1000)).X
        local wrap = Instance.new("Frame"); wrap.Name = name; wrap.Parent = HUDFrame
        wrap.BackgroundTransparency = 1; wrap.Size = UDim2.new(0, w + 14, 0, DesignTokens.HUDBarHeight)
        wrap.LayoutOrder = -math.floor(w)
        local cont = Instance.new("Frame"); cont.Name = "Container"; cont.Parent = wrap
        cont.BackgroundColor3 = Color3.new(0, 0, 0); cont.BackgroundTransparency = 0.4
        cont.Size = UDim2.new(1, 0, 1, 0); cont.Position = UDim2.new(1, 50, 0, 0); cont.BorderSizePixel = 0
        local bar = Instance.new("Frame"); bar.Name = "FlowBar"; bar.Parent = cont
        bar.Size = UDim2.new(0, 3, 1, 0); bar.Position = UDim2.new(1, -3, 0, 0); bar.BorderSizePixel = 0; bar.BackgroundColor3 = Color3.new(1, 1, 1)
        local grad = Instance.new("UIGradient"); grad.Parent = bar; grad.Rotation = -90; table.insert(Library.Globals.HUDGradients, grad)
        local lab = Instance.new("TextLabel"); lab.Parent = cont; lab.Text = name; lab.Font = DesignTokens.HUDFont; lab.TextSize = DesignTokens.HUDTextSize
        lab.BackgroundTransparency = 1; lab.Size = UDim2.new(1, -8, 1, 0); lab.Position = UDim2.new(0, 0, 0, 0); lab.TextXAlignment = Enum.TextXAlignment.Right
        RegisterTheme(lab, "Text")
        TweenService:Create(cont, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    else
        if old then
            local cont = old:FindFirstChild("Container")
            if cont then
                local out = TweenService:Create(cont, TweenInfo.new(0.3), {Position = UDim2.new(1, 50, 0, 0)})
                out:Play(); out.Completed:Connect(function() old:Destroy() end)
            else old:Destroy() end
        end
    end
end

----------------------------------------
-- 通知
----------------------------------------
function Library:Notify(title, status)
    if not Library.Config.ShowNotifs then return end
    local frame = Instance.new("Frame"); frame.Parent = ScreenGui; frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.15; frame.BorderSizePixel = 0; frame.Size = UDim2.new(0, 200, 0, 35)
    frame.Position = UDim2.new(1, 50, 1, -50)
    local bar = Instance.new("Frame"); bar.Parent = frame; bar.Size = UDim2.new(0, 2, 1, 0); bar.BorderSizePixel = 0
    RegisterTheme(bar, "Accent")
    local titleLab = Instance.new("TextLabel"); titleLab.Parent = frame; titleLab.Text = title; titleLab.Font = Enum.Font.GothamBold
    titleLab.TextSize = 14; titleLab.BackgroundTransparency = 1; titleLab.Size = UDim2.new(1, -10, 0.5, 0); titleLab.Position = UDim2.new(0, 10, 0, 3); titleLab.TextXAlignment = Enum.TextXAlignment.Left
    local stateLab = Instance.new("TextLabel"); stateLab.Parent = frame; stateLab.Text = status and "已开启" or "已关闭"
    stateLab.Font = Enum.Font.Gotham; stateLab.TextSize = 11; stateLab.TextColor3 = status and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    stateLab.BackgroundTransparency = 1; stateLab.Size = UDim2.new(1, -10, 0.5, 0); stateLab.Position = UDim2.new(0, 10, 0.5, -2); stateLab.TextXAlignment = Enum.TextXAlignment.Left
    local timerFrame = Instance.new("Frame"); timerFrame.Parent = frame; timerFrame.BorderSizePixel = 0; timerFrame.Position = UDim2.new(0, 0, 1, -2); timerFrame.Size = UDim2.new(1, 0, 0, 2); timerFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    local timerTween = TweenService:Create(timerFrame, TweenInfo.new(Library.Config.NotifDuration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
    timerTween:Play()
    table.insert(Library.Globals.ActiveNotifs, frame)
    local yOffset = 0; for i = #Library.Globals.ActiveNotifs, 1, -1 do local n = Library.Globals.ActiveNotifs[i]; if n.Parent then TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(1, -210, 1, -50 - yOffset)}):Play(); yOffset = yOffset + 40 end end
    TweenService:Create(frame, TweenInfo.new(0.3), {Position = UDim2.new(1, -210, 1, -50 - yOffset)}):Play()
    timerTween.Completed:Connect(function()
        for i, v in ipairs(Library.Globals.ActiveNotifs) do if v == frame then table.remove(Library.Globals.ActiveNotifs, i); break end end
        local out = TweenService:Create(frame, TweenInfo.new(0.3), {Position = frame.Position + UDim2.new(0, 250, 0, 0)})
        out:Play(); out.Completed:Connect(function() frame:Destroy() end)
    end)
end

----------------------------------------
-- 窗口
----------------------------------------
function Library:CreateWindow(title, pos, isMain, isSub)
    local Window = {}; local isFolded = false; local isOpen = not isSub
    if isSub and not Library.Config.UIVisible then isOpen = false end
    local headerH = Library.Config.ItemHeight + 6
    local main = Instance.new("Frame"); main.Name = "Window_" .. title; main.Parent = ScreenGui
    main.Position = pos; main.Size = UDim2.new(0, Library.Config.WindowWidth, 0, headerH)
    main.BorderSizePixel = 0; main.Visible = isOpen; main.ZIndex = 10
    RegisterTheme(main, "Window"); ApplyStyle(main, true, DesignTokens.CornerRadius)
    local scale = Instance.new("UIScale"); scale.Parent = main; scale.Scale = Library.Config.UIScale
    local header = Instance.new("Frame"); header.Parent = main; header.BackgroundTransparency = 1; header.Size = UDim2.new(1, 0, 0, headerH)
    local titleLabel = Instance.new("TextLabel"); titleLabel.Parent = header; titleLabel.Text = title; titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = math.clamp(headerH * 0.45, 12, 24); titleLabel.Size = UDim2.new(1, -10, 1, 0); titleLabel.Position = UDim2.new(0, 10, 0, 0); titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.BackgroundTransparency = 1
    RegisterTheme(titleLabel, "Text")
    local container = Instance.new("ScrollingFrame"); container.Name = "Container"; container.Parent = main
    container.BackgroundTransparency = 1; container.BorderSizePixel = 0; container.Position = UDim2.new(0, 0, 0, headerH)
    container.Size = UDim2.new(1, 0, 0, 0); container.ScrollBarThickness = DesignTokens.ScrollThickness; container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RegisterTheme(container, "Scroll")
    local list = Instance.new("UIListLayout"); list.Parent = container; list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0, 0)
    local winData = {Main = main, Header = header, Title = titleLabel, Container = container, List = list, IsOpen = isOpen, IsSub = isSub}
    table.insert(Library.Globals.Windows, winData)
    if isSub then Library.Globals.SubWindows[title] = winData end
    -- 自适应高度
    local function RefreshH()
        local contentH = list.AbsoluteContentSize.Y
        local screenHeight = Camera.ViewportSize.Y / (Library.Config.UIScale > 0 and Library.Config.UIScale or 1)
        local maxPerScreen = math.clamp(screenHeight - 100, 100, Library.Config.WindowMaxHeight)
        local actualMax = math.min(Library.Config.WindowMaxHeight, maxPerScreen)
        local finalH = math.min(contentH, actualMax)
        if isFolded then
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, Library.Config.WindowWidth, 0, headerH)}):Play()
            container.Visible = false
        else
            container.Visible = true; container.ScrollingEnabled = contentH > actualMax
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, Library.Config.WindowWidth, 0, headerH + finalH)}):Play()
            container.Size = UDim2.new(1, 0, 0, finalH)
        end
    end
    winData.RefreshHeight = RefreshH
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshH)
    -- 拖拽
    local drag, dStart, sPos, sTime, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType.Name:match("Mouse") or i.UserInputType.Name:match("Touch") then
            Library.Globals.TopZIndex = Library.Globals.TopZIndex + 1; main.ZIndex = Library.Globals.TopZIndex
            drag = true; dStart = i.Position; sPos = main.Position; sTime = tick(); startPos = i.Position
        end
    end)
    RegisterConnection(UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType.Name:match("Mouse") or i.UserInputType.Name:match("Touch")) then
            local delta = i.Position - dStart
            if (i.Position - startPos).Magnitude < DesignTokens.MinDragDist then return end
            TweenService:Create(main, TweenInfo.new(0.05), {Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)}):Play()
        end
    end))
    header.InputEnded:Connect(function(i)
        if i.UserInputType.Name:match("Mouse") or i.UserInputType.Name:match("Touch") then
            drag = false; if (i.Position - dStart).Magnitude < DesignTokens.MinDragDist and tick() - sTime < 0.3 then isFolded = not isFolded; RefreshH() end
        end
    end)
    -- 越界保护
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        main.Position = ClampToScreen(main.Position)
    end)
    ----------------------------------------
    -- 控件
    ----------------------------------------
    function Window:CreateButton(name, callback)
        local h = Library.Config.ItemHeight
        local btn = Instance.new("TextButton"); btn.Parent = container; btn.BackgroundTransparency = 1; btn.Size = UDim2.new(1, 0, 0, h); btn.Text = ""; btn.BorderSizePixel = 0; btn.ClipsDescendants = true
        ApplyStyle(btn, false, 6)
        local txt = Instance.new("TextLabel"); txt.Parent = btn; txt.Text = name; txt.Font = Enum.Font.GothamSemibold
        txt.TextSize = math.clamp(h * 0.42, 10, 20); txt.BackgroundTransparency = 1; txt.Size = UDim2.new(1, -10, 1, 0); txt.Position = UDim2.new(0, 10, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Left
        RegisterTheme(txt, "TextDark")
        btn.MouseButton1Click:Connect(function() CreateRipple(btn); pcall(callback) end)
    end
    function Window:CreateModule(name, callback, allowBind)
        if allowBind == nil then allowBind = true end
        local Mod = {}; local enabled = false; local setOpen = false; local bindKey = nil
        local h = Library.Config.ItemHeight
        local btn = Instance.new("TextButton"); btn.Parent = container; btn.BackgroundTransparency = 1; btn.Size = UDim2.new(1, 0, 0, h); btn.Text = ""; btn.BorderSizePixel = 0; btn.ClipsDescendants = true
        ApplyStyle(btn, false, 6)
        local txt = Instance.new("TextLabel"); txt.Parent = btn; txt.Text = name; txt.Font = Enum.Font.GothamSemibold
        txt.TextSize = math.clamp(h * 0.42, 10, 20); txt.BackgroundTransparency = 1; txt.Size = UDim2.new(1, -35, 1, 0); txt.Position = UDim2.new(0, 10, 0, 0); txt.TextXAlignment = Enum.TextXAlignment.Left
        RegisterTheme(txt, "TextDark")
        local dots = Instance.new("TextButton"); dots.Parent = btn; dots.Text = "..."; dots.Font = Enum.Font.GothamBold
        dots.TextSize = math.clamp(h * 0.42, 10, 20) + 4; dots.BackgroundTransparency = 1; dots.Size = UDim2.new(0, h, 1, 0); dots.Position = UDim2.new(1, -h, 0, 0); dots.Visible = allowBind
        RegisterTheme(dots, "TextDark")
        local setFrame = Instance.new("Frame"); setFrame.Parent = container; setFrame.BackgroundTransparency = 0.5; RegisterTheme(setFrame, "SettingBg")
        setFrame.Size = UDim2.new(1, 0, 0, 0); setFrame.ClipsDescendants = true; setFrame.Visible = false; setFrame.BorderSizePixel = 0
        local setList = Instance.new("UIListLayout"); setList.Parent = setFrame; setList.Padding = UDim.new(0, 0)
        local function Toggle(isRemote)
            enabled = not enabled
            if enabled then
                RegisterTheme(txt, "Text"); RegisterTheme(dots, "Text")
                TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0.8, BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
            else
                RegisterTheme(txt, "TextDark"); RegisterTheme(dots, "TextDark")
                TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
            if isRemote then CreateRipple(btn, true) end
            UpdateHUD(name, enabled); Library:Notify(name, enabled); pcall(callback, enabled)
        end
        function Mod:Set(bool) if bool ~= enabled then Toggle() end end
        if allowBind then
            local kb = Instance.new("TextButton"); kb.Parent = setFrame; kb.Size = UDim2.new(1, 0, 0, 24); kb.BackgroundTransparency = 1; kb.Text = ""
            local kl = Instance.new("TextLabel"); kl.Parent = kb; kl.Text = "绑定: 无"; kl.Font = Enum.Font.Gotham; kl.TextSize = 11; kl.BackgroundTransparency = 1; kl.Size = UDim2.new(1, -20, 1, 0); kl.Position = UDim2.new(0, 10, 0, 0); kl.TextXAlignment = Enum.TextXAlignment.Left
            RegisterTheme(kl, "TextDark")
            local listening = false
            kb.MouseButton1Click:Connect(function()
                if listening then return end; listening = true; kl.Text = "按下按键..."
                local c; c = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false; c:Disconnect()
                        if i.KeyCode.Name == "Backspace" or i.KeyCode.Name == "Delete" then
                            if bindKey then Library.Globals.BoundKeys[bindKey] = nil end; bindKey = nil; kl.Text = "绑定: 无"
                        else
                            if bindKey then Library.Globals.BoundKeys[bindKey] = nil end; bindKey = i.KeyCode; Library.Globals.BoundKeys[bindKey] = Toggle; kl.Text = "绑定: " .. i.KeyCode.Name
                        end
                    end
                end)
            end)
            local pressStart = 0
            btn.InputBegan:Connect(function(i)
                if i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("MouseButton1") then
                    pressStart = tick()
                end
            end)
            btn.InputEnded:Connect(function(i)
                if i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("MouseButton1") then
                    if tick() - pressStart < 0.6 then CreateRipple(btn); Toggle() end
                end
            end)
        else
            btn.MouseButton1Click:Connect(function() CreateRipple(btn); Toggle() end)
        end
        dots.MouseButton1Click:Connect(function()
            setOpen = not setOpen; setFrame.Visible = true
            local th = setOpen and setList.AbsoluteContentSize.Y or 0
            TweenService:Create(setFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, th)}):Play()
            local c; c = RunService.RenderStepped:Connect(function()
                List:ApplyLayout(); if winData.RefreshHeight then winData.RefreshHeight() end; if math.abs(setFrame.Size.Y.Offset - th) < 1 then c:Disconnect() end
            end)
            if not setOpen then task.delay(0.3, function() setFrame.Visible = false end) end
        end)
        function Mod:CreateSlider(txt, min, max, def, call)
            if not dots.Visible then dots.Visible = true end; local v = def
            local f = Instance.new("Frame"); f.Parent = setFrame; f.BackgroundTransparency = 1; f.Size = UDim2.new(1, 0, 0, 30); f.BorderSizePixel = 0
            local l = Instance.new("TextLabel"); l.Parent = f; l.Text = txt .. ": " .. v; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, 0, 14); RegisterTheme(l, "TextDark")
            local b = Instance.new("Frame"); b.Parent = f; b.BackgroundColor3 = Color3.fromRGB(60, 60, 60); b.BorderSizePixel = 0; b.Position = UDim2.new(0, 8, 0, 18); b.Size = UDim2.new(1, -16, 0, 4)
            local fil = Instance.new("Frame"); fil.Parent = b; fil.BorderSizePixel = 0; fil.Size = UDim2.new((def - min) / (max - min), 0, 1, 0); RegisterTheme(fil, "Accent")
            local t = Instance.new("TextButton"); t.Parent = f; t.BackgroundTransparency = 1; t.Text = ""; t.Size = UDim2.new(1, 0, 0, 25); t.Position = UDim2.new(0, 0, 0, 5); t.ZIndex = 10
            local d = false; t.InputBegan:Connect(function(i) if i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("Mouse") then d = true end end)
            RegisterConnection(UserInputService.InputEnded:Connect(function(i) if i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("Mouse") then d = false end end))
            RegisterConnection(UserInputService.InputChanged:Connect(function(i)
                if d and (i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("Mouse")) then
                    local p = math.clamp((i.Position.X - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1); v = math.floor(min + (max - min) * p)
                    l.Text = txt .. ": " .. v; fil.Size = UDim2.new(p, 0, 1, 0); pcall(call, v)
                end
            end))
            pcall(call, v)
        end
        function Mod:CreateSwitch(txt, call, defaultState)
            if not dots.Visible then dots.Visible = true end; local on = defaultState or false
            local b = Instance.new("TextButton"); b.Parent = setFrame; b.BackgroundTransparency = 1; b.Size = UDim2.new(1, 0, 0, 24); b.Text = ""; b.BorderSizePixel = 0
            local l = Instance.new("TextLabel"); l.Parent = b; l.Text = txt; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -30, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.TextXAlignment = Enum.TextXAlignment.Left; RegisterTheme(l, "TextDark")
            local box = Instance.new("Frame"); box.Parent = b; box.Size = UDim2.new(0, 12, 0, 12); box.Position = UDim2.new(1, -20, 0.5, -6); box.BackgroundColor3 = Color3.fromRGB(60, 60, 60); box.BorderSizePixel = 0
            local ind = Instance.new("Frame"); ind.Parent = box; ind.Size = UDim2.new(1, -2, 1, -2); ind.Position = UDim2.new(0, 1, 0, 1); ind.Visible = on; ind.BorderSizePixel = 0; RegisterTheme(ind, "Accent")
            b.MouseButton1Click:Connect(function() on = not on; ind.Visible = on; pcall(call, on) end)
            if on then pcall(call, on) end
        end
        return Mod
    end
    return Window
end

----------------------------------------
-- 对外接口
----------------------------------------
function Library:CreateMainControl(title) return self:CreateWindow(title, UDim2.new(0, 20, 0, 60), true, false) end
function Library:CreateChildWindow(title) return self:CreateWindow(title, UDim2.new(0.5, -Library.Config.WindowWidth / 2, 0.5, -100), false, true) end
function Library:SetHUDVisible(v) Library.Config.ShowHUD = v; HUDFrame.Visible = v; SaveConfigDeferred() end
function Library:SetNotifsVisible(v) Library.Config.ShowNotifs = v; SaveConfigDeferred() end
function Library:SetTheme(name)
    if Library.Themes[name] then
        CurrentThemeData = Library.Themes[name]; Library.Config.Theme = name
        for _, data in ipairs(Library.Globals.ThemeObjects) do
            local obj = data.Object; if obj and obj.Parent then
                if data.Type == "Window" then TweenService:Create(obj, TweenInfo.new(0.5), {BackgroundColor3 = CurrentThemeData.Main}):Play()
                elseif data.Type == "Text" then TweenService:Create(obj, TweenInfo.new(0.5), {TextColor3 = CurrentThemeData.Text}):Play()
                elseif data.Type == "TextDark" then TweenService:Create(obj, TweenInfo.new(0.5), {TextColor3 = CurrentThemeData.TextDark}):Play()
                elseif data.Type == "Accent" then TweenService:Create(obj, TweenInfo.new(0.5), {BackgroundColor3 = CurrentThemeData.Accent}):Play()
                end
            end
        end
        SaveConfigDeferred()
    end
end

----------------------------------------
-- 内置设置
----------------------------------------
function Library:SetupSettings()
    local sets = self:CreateWindow("UI设置", UDim2.new(0.5, -100, 0.5, -100))
    local uiConf = sets:CreateModule("界面配置", function() end, false)
    uiConf:CreateDropdown("主题选择", {"Default", "Ocean"}, function(v) Library:SetTheme(v); Library:Notify("主题切换", v) end)
    uiConf:CreateSlider("整体缩放(%)", 50, 150, math.floor(Library.Config.UIScale * 100), function(v) Library.Config.UIScale = v / 100; for _, w in ipairs(Library.Globals.Windows) do local s = w.Main:FindFirstChild("UIScale"); if s then TweenService:Create(s, TweenInfo.new(0.3), {Scale = Library.Config.UIScale}):Play() end; if w.RefreshHeight then w.RefreshHeight() end end; SaveConfigDeferred() end)
    uiConf:CreateSlider("窗口宽度", 100, 300, Library.Config.WindowWidth, function(v) Library.Config.WindowWidth = v; for _, w in ipairs(Library.Globals.Windows) do TweenService:Create(w.Main, TweenInfo.new(0.3), {Size = UDim2.new(0, v, 0, w.Main.Size.Y.Offset)}):Play(); if w.RefreshHeight then w.RefreshHeight() end end; SaveConfigDeferred() end)
    local styleConf = sets:CreateModule("样式设置", function() end, false)
    styleConf:CreateSwitch("圆角风格", function(v) Library.Config.UseCorners = v; for _, data in ipairs(Library.Globals.StyleObjects) do local obj = data.Object; if obj and obj.Parent then local corner = obj:FindFirstChild("UICorner"); if corner then TweenService:Create(corner, TweenInfo.new(0.3), {CornerRadius = UDim.new(0, v and data.Radius or 0)}):Play() end end end; SaveConfigDeferred() end, Library.Config.UseCorners)
    styleConf:CreateSwitch("UI 描边", function(v) Library.Config.UseStroke = v; for _, data in ipairs(Library.Globals.StyleObjects) do local obj = data.Object; if obj and obj.Parent and data.HasStroke then local stroke = obj:FindFirstChild("UIStroke"); if stroke then TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = v and 0 or 1}):Play() end end end; SaveConfigDeferred() end, Library.Config.UseStroke)
    local funcConf = sets:CreateModule("功能开关", function() end, false)
    funcConf:CreateSwitch("显示 HUD", function(v) Library:SetHUDVisible(v) end, Library.Config.ShowHUD)
    funcConf:CreateSwitch("显示 通知", function(v) Library:SetNotifsVisible(v) end, Library.Config.ShowNotifs)
    sets:CreateButton("保存当前配置", function() SaveConfigDeferred(); Library:Notify("配置已保存", true) end)
    return sets
end

----------------------------------------
-- 启动
----------------------------------------
task.spawn(function()
    local loader = Instance.new("ScreenGui"); loader.Name = "YC_Loader"; loader.IgnoreGuiInset = true; loader.DisplayOrder = 10000; loader.Parent = CoreGui
    local main = Instance.new("Frame"); main.Parent = loader; main.BackgroundColor3 = Color3.new(0, 0, 0); main.BackgroundTransparency = 0; main.Size = UDim2.new(1, 0, 1, 0); main.ZIndex = 1
    local cen = Instance.new("Frame"); cen.Parent = main; cen.Size = UDim2.new(0, 400, 0, 150); cen.AnchorPoint = Vector2.new(0.5, 0.5); cen.Position = UDim2.new(0.5, 0, 0.5, 0); cen.BackgroundTransparency = 1; cen.ZIndex = 2
    local mainTitle = Instance.new("TextLabel"); mainTitle.Parent = cen; mainTitle.Text = "YC GUI"; mainTitle.Font = Enum.Font.GothamBlack; mainTitle.TextSize = 60; mainTitle.TextColor3 = Color3.new(1, 1, 1); mainTitle.Size = UDim2.new(1, 0, 0, 70); mainTitle.Position = UDim2.new(0, 0, 0.5, -40); mainTitle.AnchorPoint = Vector2.new(0, 0.5); mainTitle.BackgroundTransparency = 1; mainTitle.TextTransparency = 1
    local titleScale = Instance.new("UIScale"); titleScale.Parent = mainTitle; titleScale.Scale = 1.1
    local mainGradient = Instance.new("UIGradient"); mainGradient.Parent = mainTitle; mainGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 50, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255))})
    local subTitle = Instance.new("TextLabel"); subTitle.Parent = cen; subTitle.Text = "Library Loaded"; subTitle.Font = Enum.Font.Gotham; subTitle.TextSize = 16; subTitle.TextColor3 = Color3.fromRGB(220, 220, 220); subTitle.Size = UDim2.new(1, 0, 0, 20); subTitle.AnchorPoint = Vector2.new(1, 0); subTitle.Position = UDim2.new(1, -20, 0.5, 25); subTitle.TextXAlignment = Enum.TextXAlignment.Right; subTitle.BackgroundTransparency = 1; subTitle.TextTransparency = 1
    main.BackgroundTransparency = 0.3
    local t1 = TweenService:Create(mainTitle, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0})
    local t2 = TweenService:Create(titleScale, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1.0})
    t1:Play(); t2:Play(); task.wait(0.4)
    local subPosFinal = UDim2.new(1, -20, 0.5, 15)
    local t3 = TweenService:Create(subTitle, TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, Position = subPosFinal})
    t3:Play(); task.wait(1.5)
    TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    TweenService:Create(mainTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
    TweenService:Create(titleScale, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1.1}):Play()
    TweenService:Create(subTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, Position = subPosFinal + UDim2.new(0, 0, 0, 10)}):Play()
    task.wait(0.5); ScreenGui.Enabled = true; loader:Destroy()
end)

return Library

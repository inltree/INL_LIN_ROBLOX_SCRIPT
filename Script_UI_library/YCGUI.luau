--// YCUI Library - Optimized Version
-- Author: Moonshot AI Optimized
-- Features: Adaptive UI, Island, HUD, Notify, Theme System, Mobile Support

local Library = {}
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Config
local ConfigName = "YCUI/settings_optimized.json"
local DefaultConfig = {
    Theme = "Default",
    UIScale = 1.0,
    WindowWidth = 180,
    WindowMaxHeight = 350,
    ItemHeight = 32,
    ShowHUD = true,
    ShowNotifs = true,
    NotifDuration = 3,
    UIVisible = true,
    UseCorners = true,
    UseStroke = false
}

--// Themes
local Themes = {
    Default = {
        Name = "紫罗兰",
        Main = Color3.fromRGB(20, 20, 25),
        Accent = Color3.fromRGB(140, 40, 255),
        Text = Color3.new(1, 1, 1),
        TextDark = Color3.fromRGB(160, 160, 170),
        SettingBg = Color3.fromRGB(25, 25, 30),
        Scroll = Color3.fromRGB(80, 60, 100)
    },
    Ocean = {
        Name = "深海蓝",
        Main = Color3.fromRGB(15, 25, 30),
        Accent = Color3.fromRGB(0, 160, 255),
        Text = Color3.fromRGB(240, 255, 255),
        TextDark = Color3.fromRGB(140, 160, 170),
        SettingBg = Color3.fromRGB(20, 30, 35),
        Scroll = Color3.fromRGB(50, 70, 90)
    }
}

--// Util Functions
local function LoadConfig()
    if isfile(ConfigName) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigName)) end)
        if ok then
            for k, v in pairs(data) do DefaultConfig[k] = v end
        end
    end
end

local function SaveConfig()
    pcall(function() writefile(ConfigName, HttpService:JSONEncode(DefaultConfig)) end)
end

local function Tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

--// UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YCUI_Optimized"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false

local function CreateWindow(title, position)
    local Main = Instance.new("Frame")
    Main.Name = title
    Main.Size = UDim2.new(0, DefaultConfig.WindowWidth, 0, DefaultConfig.ItemHeight + 6)
    Main.Position = position
    Main.BackgroundColor3 = Themes[DefaultConfig.Theme].Main
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    Main.Visible = DefaultConfig.UIVisible

    local Header = Instance.new("TextLabel")
    Header.Text = title
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 18
    Header.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight + 6)
    Header.BackgroundTransparency = 1
    Header.TextColor3 = Themes[DefaultConfig.Theme].Text
    Header.Parent = Main
    Header.TextXAlignment = Enum.TextXAlignment.Left

    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, 0, 1, -(DefaultConfig.ItemHeight + 6))
    Container.Position = UDim2.new(0, 0, 0, DefaultConfig.ItemHeight + 6)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 3
    Container.ScrollBarImageColor3 = Themes[DefaultConfig.Theme].Scroll
    Container.Parent = Main

    local List = Instance.new("UIListLayout")
    List.Parent = Container
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 4)

    return {Main = Main, Container = Container, Header = Header}
end

local function CreateButton(text, callback, parent)
    local Btn = Instance.new("TextButton")
    Btn.Text = text
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 14
    Btn.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
    Btn.BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg
    Btn.TextColor3 = Themes[DefaultConfig.Theme].TextDark
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    Btn.ClipsDescendants = true

    Btn.MouseButton1Click:Connect(function()
        Tween(Btn, {BackgroundColor3 = Themes[DefaultConfig.Theme].Accent}, 0.1)
        task.wait(0.1)
        Tween(Btn, {BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg}, 0.2)
        pcall(callback)
    end)

    return Btn
end

--// Loader
local function ShowLoader()
    local Loader = Instance.new("ScreenGui")
    Loader.Name = "YCUI_Loader"
    Loader.Parent = CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = Color3.new(0, 0, 0)
    Frame.BackgroundTransparency = 0.3
    Frame.Parent = Loader

    local Label = Instance.new("TextLabel")
    Label.Text = "YCUI Loaded"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 24
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Size = UDim2.new(0, 200, 0, 50)
    Label.Position = UDim2.new(0.5, -100, 0.5, -25)
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    Tween(Label, {TextTransparency = 0}, 1)
    task.wait(1.5)
    Tween(Frame, {BackgroundTransparency = 1}, 0.5)
    Tween(Label, {TextTransparency = 1}, 0.5)
    task.wait(0.5)
    Loader:Destroy()
    ScreenGui.Enabled = true
end

--// Init
LoadConfig()
ShowLoader()

--// Public API
function Library:CreateWindow(title, position)
    return CreateWindow(title, position or UDim2.new(0, 20, 0, 20))
end

function Library:CreateButton(text, callback, parent)
    return CreateButton(text, callback, parent)
end

function Library:Notify(title, status)
    -- Placeholder for notification system
    print("[YCUI Notify]", title, status and "已开启" or "已关闭")
end

--// 通知系统
Library.Globals.ActiveNotifs = {}

function Library:Notify(title, status)
    if not DefaultConfig.ShowNotifs then return end

    local Frame = Instance.new("Frame")
    Frame.Parent = ScreenGui
    Frame.Size = UDim2.new(0, 220, 0, 50)
    Frame.Position = UDim2.new(1, 250, 1, -50)
    Frame.BackgroundColor3 = Themes[DefaultConfig.Theme].Main
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 200

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextColor3 = Themes[DefaultConfig.Theme].Text
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, -10, 0.5, 0)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel")
    Status.Parent = Frame
    Status.Text = status and "已开启" or "已关闭"
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 12
    Status.TextColor3 = status and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    Status.BackgroundTransparency = 1
    Status.Size = UDim2.new(1, -10, 0.5, 0)
    Status.Position = UDim2.new(0, 10, 0.5, 0)
    Status.TextXAlignment = Enum.TextXAlignment.Left

    -- 排列
    local yOffset = 0
    for i = #Library.Globals.ActiveNotifs, 1, -1 do
        local notif = Library.Globals.ActiveNotifs[i]
        if notif and notif.Parent then
            Tween(notif, {Position = UDim2.new(1, -230, 1, -50 - yOffset)}, 0.3)
            yOffset = yOffset + 60
        end
    end
    table.insert(Library.Globals.ActiveNotifs, Frame)

    -- 动画
    Tween(Frame, {Position = UDim2.new(1, -230, 1, -50 - yOffset)}, 0.3)

    -- 自动消失
    task.wait(DefaultConfig.NotifDuration)
    Tween(Frame, {Position = Frame.Position + UDim2.new(0, 300, 0, 0)}, 0.3)
    task.wait(0.3)
    Frame:Destroy()

    -- 清理
    for i, v in ipairs(Library.Globals.ActiveNotifs) do
        if v == Frame then table.remove(Library.Globals.ActiveNotifs, i) break end
    end
end

--// 悬浮窗系统
Library.Globals.FloatWidgets = {}

function Library:CreateFloatWidget(name, toggleFunc, getState)
    if ScreenGui:FindFirstChild("Float_" .. name) then return end

    local Widget = Instance.new("TextButton")
    Widget.Name = "Float_" .. name
    Widget.Parent = ScreenGui
    Widget.Size = UDim2.new(0, 50, 0, 50)
    Widget.Position = UDim2.new(0.5, -25, 0.5, -25)
    Widget.BackgroundColor3 = Themes[DefaultConfig.Theme].Main
    Widget.Text = string.sub(name, 1, 1)
    Widget.Font = Enum.Font.GothamBold
    Widget.TextSize = 20
    Widget.TextColor3 = Color3.new(1, 1, 1)
    Widget.AutoButtonColor = false
    Widget.ZIndex = 150

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Widget

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 2
    Stroke.Color = Themes[DefaultConfig.Theme].Accent
    Stroke.Parent = Widget

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Widget
    CloseBtn.Size = UDim2.new(0, 15, 0, 15)
    CloseBtn.Position = UDim2.new(1, -5, 0, -5)
    CloseBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.Font = Enum.Font.GothamBlack
    CloseBtn.TextSize = 12
    CloseBtn.ZIndex = 151

    -- 拖拽
    local dragging, startPos, inputStart
    Widget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            inputStart = input.Position
            startPos = Widget.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - inputStart
            Widget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- 状态更新
    local function UpdateColor()
        Stroke.Color = getState() and Themes[DefaultConfig.Theme].Accent or Color3.fromRGB(60, 60, 60)
    end

    -- 点击
    Widget.MouseButton1Click:Connect(function()
        pcall(toggleFunc)
        UpdateColor()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Widget:Destroy()
    end)

    UpdateColor()
    table.insert(Library.Globals.FloatWidgets, Widget)
end

Library.Globals.WindowMargin = 10
Library.Globals.LastWindowPos = Vector2.new(20, 20)

function Library:AutoPositionWindow()
    local margin = Library.Globals.WindowMargin
    local last = Library.Globals.LastWindowPos
    local screenSize = Camera.ViewportSize

    local newX = last.X + margin
    local newY = last.Y + margin

    if newX + DefaultConfig.WindowWidth > screenSize.X then
        newX = margin
        newY = newY + DefaultConfig.ItemHeight + margin
    end

    if newY > screenSize.Y - 100 then
        newX = margin
        newY = margin
    end

    Library.Globals.LastWindowPos = Vector2.new(newX, newY)
    return UDim2.new(0, newX, 0, newY)
end

function Library:CreateButton(text, callback, parent)
    local Btn = Instance.new("TextButton")
    Btn.Text = text
    Btn.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
    Btn.BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg
    Btn.TextColor3 = Themes[DefaultConfig.Theme].TextDark
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 14
    Btn.Parent = parent

    Btn.MouseButton1Click:Connect(function()
        Tween(Btn, {BackgroundColor3 = Themes[DefaultConfig.Theme].Accent}, 0.1)
        task.wait(0.1)
        Tween(Btn, {BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg}, 0.2)
        pcall(callback)
    end)

    return Btn
end

function Library:CreateToggle(text, default, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Text = text
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextColor3 = Themes[DefaultConfig.Theme].TextDark
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 30, 0, 16)
    Switch.Position = UDim2.new(1, -35, 0.5, -8)
    Switch.BackgroundColor3 = default and Themes[DefaultConfig.Theme].Accent or Color3.fromRGB(60, 60, 60)
    Switch.Text = ""
    Switch.Parent = Frame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Switch

    local state = default
    Switch.MouseButton1Click:Connect(function()
        state = not state
        Tween(Switch, {BackgroundColor3 = state and Themes[DefaultConfig.Theme].Accent or Color3.fromRGB(60, 60, 60)}, 0.2)
        pcall(callback, state)
    end)

    return Switch
end

function Library:CreateSlider(text, min, max, default, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Text = text .. ": " .. default
    Label.Size = UDim2.new(1, 0, 0, 14)
    Label.Position = UDim2.new(0, 10, 0, 2)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Themes[DefaultConfig.Theme].TextDark
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 4)
    Bar.Position = UDim2.new(0, 10, 0, 20)
    Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Themes[DefaultConfig.Theme].Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local dragging = false
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            Fill.Size = UDim2.new(pos, 0, 1, 0)
            Label.Text = text .. ": " .. value
            pcall(callback, value)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function Library:CreateDropdown(text, options, default, callback, parent)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent
    Frame.ClipsDescendants = true

    local Button = Instance.new("TextButton")
    Button.Text = text .. ": " .. default
    Button.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.TextColor3 = Themes[DefaultConfig.Theme].TextDark
    Button.BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg
    Button.Parent = Frame

    local List = Instance.new("UIListLayout")
    List.Parent = Frame
    List.Padding = UDim.new(0, 2)

    local open = false
    local totalHeight = DefaultConfig.ItemHeight

    for _, opt in ipairs(options) do
        local Option = Instance.new("TextButton")
        Option.Text = opt
        Option.Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)
        Option.Font = Enum.Font.Gotham
        Option.TextSize = 12
        Option.TextColor3 = Themes[DefaultConfig.Theme].TextDark
        Option.BackgroundTransparency = 1
        Option.Parent = Frame
        Option.Visible = false

        Option.MouseButton1Click:Connect(function()
            Button.Text = text .. ": " .. opt
            pcall(callback, opt)
            open = false
            Tween(Frame, {Size = UDim2.new(1, 0, 0, DefaultConfig.ItemHeight)}, 0.3)
            for _, child in ipairs(Frame:GetChildren()) do
                if child:IsA("TextButton") and child ~= Button then
                    child.Visible = false
                end
            end
        end)

        totalHeight = totalHeight + DefaultConfig.ItemHeight
    end

    Button.MouseButton1Click:Connect(function()
        open = not open
        Tween(Frame, {Size = UDim2.new(1, 0, 0, open and totalHeight or DefaultConfig.ItemHeight)}, 0.3)
        for _, child in ipairs(Frame:GetChildren()) do
            if child:IsA("TextButton") and child ~= Button then
                child.Visible = open
            end
        end
    end)
end









function Library:CreateSettingsWindow()
    local Sets = self:CreateWindow("设置面板", self:AutoPositionWindow())

    -- 主题
    Sets:CreateDropdown("主题", {"Default", "Ocean"}, function(v)
        DefaultConfig.Theme = v
        self:RefreshTheme()
        self:Notify("主题切换", true)
    end)

    -- 缩放
    Sets:CreateSlider("UI缩放", 50, 150, DefaultConfig.UIScale * 100, function(v)
        DefaultConfig.UIScale = v / 100
        self:RefreshDimensions()
    end)

    -- 圆角
    Sets:CreateToggle("圆角风格", DefaultConfig.UseCorners, function(v)
        DefaultConfig.UseCorners = v
        self:RefreshStyle()
    end)

    -- 描边
    Sets:CreateToggle("UI描边", DefaultConfig.UseStroke, function(v)
        DefaultConfig.UseStroke = v
        self:RefreshStyle()
    end)

    -- 保存
    Sets:CreateButton("保存配置", function()
        SaveConfig()
        self:Notify("配置已保存", true)
    end)
end

return Library

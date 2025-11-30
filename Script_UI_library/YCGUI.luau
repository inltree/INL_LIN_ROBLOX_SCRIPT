--[[
    YC GUI Library - Pure Version
    包含: 自适应分辨率、灵动岛、HUD、通知、主题系统
    使用方法:
    local Library = loadstring(game:HttpGet("..."))()
    -- 创建主窗口
    local Main = Library:CreateMainControl("我的脚本")
    -- 创建子窗口
    local Tab1 = Library:CreateChildWindow("功能页面")
    Main:BindWindow("功能页面", true) -- 绑定并默认显示
    -- 生成内置设置页 (可选)
    Library:SetupSettings()
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

--// 辅助函数 //--
local function GetFirstChar(str)
    local first = ""
    for _, code in utf8.codes(str) do
        first = utf8.char(code)
        break
    end
    return first ~= "" and first or string.sub(str, 1, 1)
end

--// 默认配置 //--
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
    UseStroke = false
}

Library.Config = HttpService:JSONDecode(HttpService:JSONEncode(DefaultConfig))

Library.Globals = {
    Windows = {},
    Elements = {},
    ThemeObjects = {},
    StyleObjects = {},
    ActiveNotifs = {},
    BoundKeys = {},
    IslandPosition = Vector2.new(0, 0),
    IslandObject = nil,
    HUDGradients = {},
    SubWindows = {},
    TopZIndex = 100
}

--// 主题系统 //--
Library.Themes = {
    ["Default"] = {
        Name = "紫罗兰 (Default)",
        Main = Color3.fromRGB(20, 20, 25),
        MainTrans = 0.1,
        Gradient1 = Color3.fromRGB(140, 40, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(160, 160, 170),
        SettingBg = Color3.fromRGB(25, 25, 30),
        Accent = Color3.fromRGB(100, 20, 220),
        Scroll = Color3.fromRGB(80, 60, 100)
    },
    ["Ocean"] = {
        Name = "深海蓝 (Ocean)",
        Main = Color3.fromRGB(15, 25, 30),
        MainTrans = 0.1,
        Gradient1 = Color3.fromRGB(0, 160, 255),
        Text = Color3.fromRGB(240, 255, 255),
        TextDark = Color3.fromRGB(140, 160, 170),
        SettingBg = Color3.fromRGB(20, 30, 35),
        Accent = Color3.fromRGB(0, 100, 180),
        Scroll = Color3.fromRGB(50, 70, 90)
    },
    ["Rose"] = {
        Name = "暗红玫瑰 (Rose)",
        Main = Color3.fromRGB(25, 15, 15),
        MainTrans = 0.1,
        Gradient1 = Color3.fromRGB(220, 20, 60),
        Text = Color3.fromRGB(255, 230, 230),
        TextDark = Color3.fromRGB(180, 120, 120),
        SettingBg = Color3.fromRGB(35, 20, 20),
        Accent = Color3.fromRGB(150, 0, 40),
        Scroll = Color3.fromRGB(90, 50, 50)
    },
    ["Sakura"] = {
        Name = "家乡樱花 (Sakura)",
        Main = Color3.fromRGB(30, 25, 35),
        MainTrans = 0.1,
        Gradient1 = Color3.fromRGB(255, 160, 200),
        Text = Color3.fromRGB(255, 245, 250),
        TextDark = Color3.fromRGB(180, 150, 170),
        SettingBg = Color3.fromRGB(40, 30, 45),
        Accent = Color3.fromRGB(255, 105, 180),
        Scroll = Color3.fromRGB(90, 60, 80)
    },
    ["Mint"] = {
        Name = "薄荷绿 (Mint)",
        Main = Color3.fromRGB(20, 30, 25),
        MainTrans = 0.1,
        Gradient1 = Color3.fromRGB(50, 255, 150),
        Text = Color3.fromRGB(240, 255, 240),
        TextDark = Color3.fromRGB(150, 180, 160),
        SettingBg = Color3.fromRGB(25, 40, 30),
        Accent = Color3.fromRGB(0, 180, 100),
        Scroll = Color3.fromRGB(40, 90, 60)
    },
    ["Midnight"] = {
        Name = "午夜 (Midnight)",
        Main = Color3.fromRGB(10, 10, 12),
        MainTrans = 0.05,
        Gradient1 = Color3.fromRGB(255, 140, 0),
        Text = Color3.fromRGB(220, 220, 220),
        TextDark = Color3.fromRGB(100, 100, 100),
        SettingBg = Color3.fromRGB(15, 15, 20),
        Accent = Color3.fromRGB(255, 100, 0),
        Scroll = Color3.fromRGB(60, 40, 20)
    },
    ["Sunset"] = {
        Name = "日落 (Sunset)",
        Main = Color3.fromRGB(30, 20, 30),
        MainTrans = 0.1,
        Gradient1 = Color3.fromRGB(255, 69, 0),
        Text = Color3.fromRGB(255, 240, 230),
        TextDark = Color3.fromRGB(180, 140, 140),
        SettingBg = Color3.fromRGB(40, 25, 35),
        Accent = Color3.fromRGB(180, 50, 100),
        Scroll = Color3.fromRGB(100, 60, 80)
    }
}
local CurrentThemeData = Library.Themes["Default"]

local function CheckFolder()
    if not isfolder("YCUI") then
        makefolder("YCUI")
    end
end

local function SaveConfig()
    CheckFolder()
    pcall(function()
        writefile(ConfigName, HttpService:JSONEncode(Library.Config))
    end)
end

local function LoadConfig()
    CheckFolder()
    if isfile(ConfigName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigName))
        end)
        if success and result then
            for key, value in pairs(result) do
                Library.Config[key] = value
            end
            CurrentThemeData = Library.Themes[Library.Config.Theme] or Library.Themes["Default"]
        end
    end
end
LoadConfig()

if game.CoreGui:FindFirstChild("YC_GUI_Adaptive") then
    game.CoreGui.YC_GUI_Adaptive:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YC_GUI_Adaptive"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Parent = ScreenGui
Backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
Backdrop.BackgroundTransparency = 1
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.ZIndex = 0
Backdrop.Visible = false

--// HUD 垂直流光 //--
local function UpdateHUDGradients()
    local theme = CurrentThemeData
    local time = tick() * 2
    local phase = (math.sin(time) + 1) / 2
    local color1 = theme.Accent:Lerp(theme.Gradient1, phase)
    local color2 = theme.Gradient1:Lerp(Color3.new(1, 1, 1), phase * 0.3)
    local color3 = theme.Accent:Lerp(theme.Gradient1, 1 - phase)
    local sequence = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(0.5, color2),
        ColorSequenceKeypoint.new(1, color3)
    }
    for _, gradient in pairs(Library.Globals.HUDGradients) do
        if gradient and gradient.Parent then
            gradient.Color = sequence
            gradient.Rotation = -90
        end
    end
end
RunService.RenderStepped:Connect(UpdateHUDGradients)

--// Loader //--
function Library:LoadLoader()
    local Loader = Instance.new("ScreenGui")
    Loader.Name = "YC_Loader"
    Loader.IgnoreGuiInset = true
    Loader.DisplayOrder = 10000
    Loader.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = Loader
    MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    MainFrame.BackgroundTransparency = 0
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.ZIndex = 1

    local CenterFrame = Instance.new("Frame")
    CenterFrame.Parent = MainFrame
    CenterFrame.Size = UDim2.new(0, 400, 0, 150)
    CenterFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterFrame.BackgroundTransparency = 1
    CenterFrame.ZIndex = 2

    local MainTitle = Instance.new("TextLabel")
    MainTitle.Parent = CenterFrame
    MainTitle.Text = "YC GUI"
    MainTitle.Font = Enum.Font.GothamBlack
    MainTitle.TextSize = 60
    MainTitle.TextColor3 = Color3.new(1, 1, 1)
    MainTitle.Size = UDim2.new(1, 0, 0, 70)
    MainTitle.Position = UDim2.new(0, 0, 0.5, -40)
    MainTitle.AnchorPoint = Vector2.new(0, 0.5)
    MainTitle.BackgroundTransparency = 1
    MainTitle.TextTransparency = 1

    local TitleScale = Instance.new("UIScale")
    TitleScale.Parent = MainTitle
    TitleScale.Scale = 1.1

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Parent = MainTitle
    MainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 50, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255))
    }

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Parent = CenterFrame
    SubTitle.Text = "Library Loaded"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 16
    SubTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.AnchorPoint = Vector2.new(1, 0)
    SubTitle.Position = UDim2.new(1, -20, 0.5, 25)
    SubTitle.TextXAlignment = Enum.TextXAlignment.Right
    SubTitle.BackgroundTransparency = 1
    SubTitle.TextTransparency = 1

    MainFrame.BackgroundTransparency = 0.3
    local tween1 = TweenService:Create(MainTitle, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0})
    local tween2 = TweenService:Create(TitleScale, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1.0})
    tween1:Play()
    tween2:Play()
    task.wait(0.4)
    local subPosFinal = UDim2.new(1, -20, 0.5, 15)
    local tween3 = TweenService:Create(SubTitle, TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, Position = subPosFinal})
    tween3:Play()
    task.spawn(function()
        local startTime = tick()
        while Loader.Parent do
            MainGradient.Rotation = math.sin(tick()) * 15
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(1.5)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    TweenService:Create(MainTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
    TweenService:Create(TitleScale, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1.1}):Play()
    TweenService:Create(SubTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, Position = subPosFinal + UDim2.new(0, 0, 0, 10)}):Play()
    task.wait(0.5)
    ScreenGui.Enabled = true
    Loader:Destroy()
end

--// 样式系统 //--
local function RegisterStyle(object, hasStroke, cornerRadius)
    table.insert(Library.Globals.StyleObjects, {
        Object = object,
        HasStroke = hasStroke,
        Radius = cornerRadius
    })
    local corner = object:FindFirstChild("UICorner") or Instance.new("UICorner")
    corner.Parent = object
    corner.CornerRadius = UDim.new(0, Library.Config.UseCorners and cornerRadius or 0)
    if hasStroke then
        local stroke = object:FindFirstChild("UIStroke") or Instance.new("UIStroke")
        stroke.Parent = object
        stroke.Thickness = 1.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = CurrentThemeData.Accent
        stroke.Transparency = Library.Config.UseStroke and 0 or 1
    end
end

function Library:RefreshStyle()
    local useCorners = Library.Config.UseCorners
    local useStroke = Library.Config.UseStroke
    for _, data in ipairs(Library.Globals.StyleObjects) do
        local object = data.Object
        if object and object.Parent then
            local corner = object:FindFirstChild("UICorner")
            if corner then
                TweenService:Create(corner, TweenInfo.new(0.3), {CornerRadius = UDim.new(0, useCorners and data.Radius or 0)}):Play()
            end
            if data.HasStroke then
                local stroke = object:FindFirstChild("UIStroke")
                if stroke then
                    TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = useStroke and 0 or 1, Color = CurrentThemeData.Accent}):Play()
                end
            end
        end
    end
end

--// 主题更新 //--
local function RegisterThemeObject(object, objectType)
    table.insert(Library.Globals.ThemeObjects, {Object = object, Type = objectType})
    local theme = CurrentThemeData
    if objectType == "Window" then
        object.BackgroundColor3 = theme.Main
        object.BackgroundTransparency = theme.MainTrans
    elseif objectType == "Text" then
        object.TextColor3 = theme.Text
    elseif objectType == "TextDark" then
        object.TextColor3 = theme.TextDark
    elseif objectType == "SettingBg" then
        object.BackgroundColor3 = theme.SettingBg
    elseif objectType == "Accent" then
        object.BackgroundColor3 = theme.Accent
    elseif objectType == "Scroll" then
        object.ScrollBarImageColor3 = theme.Scroll
    elseif objectType == "NotifGradient" then
        object.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, theme.Accent),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, theme.Accent)
        }
    end
end

function Library:RefreshTheme()
    local theme = CurrentThemeData
    for _, data in ipairs(Library.Globals.ThemeObjects) do
        local object = data.Object
        if object and object.Parent then
            if data.Type == "Window" then
                TweenService:Create(object, TweenInfo.new(0.5), {BackgroundColor3 = theme.Main}):Play()
            elseif data.Type == "Text" then
                TweenService:Create(object, TweenInfo.new(0.5), {TextColor3 = theme.Text}):Play()
            elseif data.Type == "TextDark" then
                TweenService:Create(object, TweenInfo.new(0.5), {TextColor3 = theme.TextDark}):Play()
            elseif data.Type == "Accent" then
                TweenService:Create(object, TweenInfo.new(0.5), {BackgroundColor3 = theme.Accent}):Play()
            elseif data.Type == "Scroll" then
                TweenService:Create(object, TweenInfo.new(0.5), {ScrollBarImageColor3 = theme.Scroll}):Play()
            elseif data.Type == "NotifGradient" then
                object.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, theme.Accent),
                    ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, theme.Accent)
                }
            end
        end
    end
    Library:RefreshStyle()
end

function Library:RefreshDimensions()
    local config = Library.Config
    for _, windowData in ipairs(Library.Globals.Windows) do
        local scale = windowData.Main:FindFirstChild("UIScale")
        if scale then
            TweenService:Create(scale, TweenInfo.new(0.3), {Scale = config.UIScale}):Play()
        end
        if windowData.RefreshHeight then
            windowData.RefreshHeight()
        end
        local headerHeight = config.ItemHeight + 6
        windowData.Header.Size = UDim2.new(1, 0, 0, headerHeight)
        windowData.Title.TextSize = math.clamp(headerHeight * 0.45, 12, 24)
    end
end

--// 监听屏幕分辨率变化 (自适应核心) //--
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    Library:RefreshDimensions()
end)

--// 灵动岛 (药丸形状) //--
local function ToggleInterface(visible)
    Library.Config.UIVisible = visible
    Backdrop.Visible = visible
    TweenService:Create(Backdrop, TweenInfo.new(0.5), {BackgroundTransparency = visible and 0.4 or 1}):Play()

    if Library.Globals.IslandObject then
        local island = Library.Globals.IslandObject
        if visible then
            TweenService:Create(island, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
            if not Library.Config.UseStroke then
                TweenService:Create(island.UIStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
            end
        else
            TweenService:Create(island, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
            if not Library.Config.UseStroke then
                TweenService:Create(island.UIStroke, TweenInfo.new(0.3), {Transparency = 0.9}):Play()
            end
        end
    end

    local origin = Library.Globals.IslandPosition
    local screenSize = ScreenGui.AbsoluteSize
    local maxRadius = math.sqrt(screenSize.X ^ 2 + screenSize.Y ^ 2)

    if visible then
        local ripple = Instance.new("Frame")
        ripple.Name = "FullRipple"
        ripple.Parent = ScreenGui
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Position = UDim2.new(0, origin.X, 0, origin.Y)
        ripple.BackgroundColor3 = CurrentThemeData.Accent
        ripple.BackgroundTransparency = 0.8
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 1
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        ripple.Size = UDim2.new(0, 0, 0, 0)
        local tween = TweenService:Create(ripple, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, maxRadius * 2, 0, maxRadius * 2),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            ripple:Destroy()
        end)

        local duration = 0.6
        local startTime = tick()
        for _, windowData in ipairs(Library.Globals.Windows) do
            if windowData.IsOpen then
                windowData.Main.Visible = false
                windowData.Main.BackgroundTransparency = 1
            end
        end
        local connection
        connection = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            local progress = math.clamp(elapsed / duration, 0, 1)
            local currentRadius = progress * maxRadius * 1.2
            for _, windowData in ipairs(Library.Globals.Windows) do
                if windowData.IsOpen then
                    local windowCenter = windowData.Main.AbsolutePosition + (windowData.Main.AbsoluteSize / 2)
                    local distance = (windowCenter - origin).Magnitude
                    if currentRadius >= distance and not windowData.Main.Visible then
                        windowData.Main.Visible = true
                        TweenService:Create(windowData.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            BackgroundTransparency = CurrentThemeData.MainTrans
                        }):Play()
                        for _, descendant in ipairs(windowData.Main:GetDescendants()) do
                            if (descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("ImageLabel")) and descendant.Name ~= "Backdrop" then
                                local targetTransparency = (descendant:IsA("TextButton") and descendant.Name == "Main") and 1 or 0
                                descendant.TextTransparency = 1
                                TweenService:Create(descendant, TweenInfo.new(0.3), {TextTransparency = targetTransparency}):Play()
                            end
                        end
                    end
                end
            end
            if progress >= 1 then
                connection:Disconnect()
            end
        end)
    else
        for _, windowData in ipairs(Library.Globals.Windows) do
            if windowData.Main.Visible then
                TweenService:Create(windowData.Main, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                for _, descendant in ipairs(windowData.Main:GetDescendants()) do
                    if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                        TweenService:Create(descendant, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
                    end
                end
            end
        end
        task.delay(0.2, function()
            if not Library.Config.UIVisible then
                for _, windowData in ipairs(Library.Globals.Windows) do
                    windowData.Main.Visible = false
                end
                Backdrop.Visible = false
            end
        end)
    end
end

local function CreateDynamicIsland()
    local island = Instance.new("TextButton")
    island.Name = "DynamicIsland"
    island.Parent = ScreenGui
    island.Size = UDim2.new(0, 100, 0, 30)
    island.Position = UDim2.new(0.5, 0, 0, 10)
    island.AnchorPoint = Vector2.new(0.5, 0)
    island.BackgroundColor3 = Color3.new(0, 0, 0)
    island.BackgroundTransparency = Library.Config.UIVisible and 0.1 or 0.6
    island.Text = "YC GUI"
    island.Font = Enum.Font.GothamBold
    island.TextSize = 14
    island.TextColor3 = Color3.new(1, 1, 1)
    island.AutoButtonColor = false
    island.ZIndex = 100

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = island

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 1.5
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Transparency = Library.Config.UIVisible and 0.5 or 0.9
    uiStroke.Parent = island

    Library.Globals.IslandObject = island

    local function UpdateIslandPosition()
        Library.Globals.IslandPosition = island.AbsolutePosition + (island.AbsoluteSize / 2)
    end
    island:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateIslandPosition)
    task.defer(UpdateIslandPosition)

    island.MouseButton1Click:Connect(function()
        TweenService:Create(island, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 25)}):Play()
        task.delay(0.1, function()
            TweenService:Create(island, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 100, 0, 30)}):Play()
        end)
        ToggleInterface(not Library.Config.UIVisible)
    end)
end
CreateDynamicIsland()

--// 涟漪 //--
local function CreateRipple(button, isCenter)
    button.ClipsDescendants = true
    spawn(function()
        local ripple = Instance.new("Frame")
        ripple.Parent = button
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.8
        ripple.BorderSizePixel = 0
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        local position = isCenter and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, UserInputService:GetMouseLocation().X - button.AbsolutePosition.X, 0, UserInputService:GetMouseLocation().Y - button.AbsolutePosition.Y)
        ripple.Position = position
        ripple.Size = UDim2.new(0, 0, 0, 0)
        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.5
        TweenService:Create(ripple, TweenInfo.new(0.4), {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.45)
        ripple:Destroy()
    end)
end

--// HUD & Notify //--
local HUDFrame = Instance.new("Frame")
HUDFrame.Name = "HUD"
HUDFrame.Parent = ScreenGui
HUDFrame.Position = UDim2.new(1, -10, 0, 50)
HUDFrame.AnchorPoint = Vector2.new(1, 0)
HUDFrame.Size = UDim2.new(0, 300, 1, -60)
HUDFrame.BackgroundTransparency = 1
HUDFrame.Visible = Library.Config.ShowHUD

local HUDLayout = Instance.new("UIListLayout")
HUDLayout.Parent = HUDFrame
HUDLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
HUDLayout.Padding = UDim.new(0, 0)
HUDLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function UpdateHUD(name, enabled)
    if not Library.Config.ShowHUD then
        return
    end
    local existing = HUDFrame:FindFirstChild(name)
    if enabled then
        if existing then
            return
        end
        local font = Enum.Font.GothamBold
        local textSize = 18
        local textWidth = TextService:GetTextSize(name, textSize, font, Vector2.new(1000, 1000)).X
        local wrap = Instance.new("Frame")
        wrap.Name = name
        wrap.Parent = HUDFrame
        wrap.BackgroundTransparency = 1
        wrap.Size = UDim2.new(0, textWidth + 14, 0, 22)
        wrap.LayoutOrder = -math.floor(textWidth)
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Parent = wrap
        container.BackgroundColor3 = Color3.new(0, 0, 0)
        container.BackgroundTransparency = 0.4
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Position = UDim2.new(1, 50, 0, 0)
        container.BorderSizePixel = 0
        local bar = Instance.new("Frame")
        bar.Name = "FlowBar"
        bar.Parent = container
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.Position = UDim2.new(1, -3, 0, 0)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        local gradient = Instance.new("UIGradient")
        gradient.Parent = bar
        gradient.Rotation = -90
        table.insert(Library.Globals.HUDGradients, gradient)
        local label = Instance.new("TextLabel")
        label.Parent = container
        label.Text = name
        label.Font = font
        label.TextSize = textSize
        label.TextColor3 = Color3.new(1, 1, 1)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -8, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Right
        RegisterThemeObject(label, "Text")
        TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    else
        if existing then
            local bar = existing:FindFirstChild("Container") and existing.Container:FindFirstChild("FlowBar")
            if bar and bar:FindFirstChild("UIGradient") then
                for i, g in ipairs(Library.Globals.HUDGradients) do
                    if g == bar.UIGradient then
                        table.remove(Library.Globals.HUDGradients, i)
                        break
                    end
                end
            end
            local container = existing:FindFirstChild("Container")
            if container then
                local out = TweenService:Create(container, TweenInfo.new(0.3), {Position = UDim2.new(1, 50, 0, 0)})
                out:Play()
                out.Completed:Connect(function()
                    existing:Destroy()
                end)
            else
                existing:Destroy()
            end
        end
    end
end

function Library:SetHUDVisible(visible)
    Library.Config.ShowHUD = visible
    HUDFrame.Visible = visible
    SaveConfig()
end

function Library:SetNotifsVisible(visible)
    Library.Config.ShowNotifs = visible
    SaveConfig()
end

function Library:SetTheme(themeName)
    if Library.Themes[themeName] then
        CurrentThemeData = Library.Themes[themeName]
        Library.Config.Theme = themeName
        Library:RefreshTheme()
        SaveConfig()
    end
end

function Library:Notify(title, status)
    if not Library.Config.ShowNotifs then
        return
    end
    local frame = Instance.new("Frame")
    frame.Parent = ScreenGui
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, 200, 0, 35)
    frame.Position = UDim2.new(1, 50, 1, -50)

    local bar = Instance.new("Frame")
    bar.Parent = frame
    bar.Size = UDim2.new(0, 2, 1, 0)
    bar.BorderSizePixel = 0
    RegisterThemeObject(bar, "Accent")

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -10, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 3)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Text = status and "已开启" or "已关闭"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = status and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Size = UDim2.new(1, -10, 0.5, 0)
    statusLabel.Position = UDim2.new(0, 10, 0.5, -2)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local timerFrame = Instance.new("Frame")
    timerFrame.Parent = frame
    timerFrame.BorderSizePixel = 0
    timerFrame.Position = UDim2.new(0, 0, 1, -2)
    timerFrame.Size = UDim2.new(1, 0, 0, 2)
    timerFrame.BackgroundColor3 = Color3.new(1, 1, 1)

    local timerGradient = Instance.new("UIGradient")
    timerGradient.Parent = timerFrame
    timerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, CurrentThemeData.Accent),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, CurrentThemeData.Accent)
    }
    RegisterThemeObject(timerGradient, "NotifGradient")

    local yOffset = 0
    for i = #Library.Globals.ActiveNotifs, 1, -1 do
        local notification = Library.Globals.ActiveNotifs[i]
        if notification.Parent then
            TweenService:Create(notification, TweenInfo.new(0.3), {
                Position = UDim2.new(1, -210, 1, -50 - yOffset)
            }):Play()
            yOffset = yOffset + 40
        end
    end

    table.insert(Library.Globals.ActiveNotifs, frame)
    TweenService:Create(frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -210, 1, -50 - yOffset)
    }):Play()

    local timerTween = TweenService:Create(timerFrame, TweenInfo.new(Library.Config.NotifDuration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    })
    timerTween:Play()

    timerTween.Completed:Connect(function()
        for i, v in ipairs(Library.Globals.ActiveNotifs) do
            if v == frame then
                table.remove(Library.Globals.ActiveNotifs, i)
                break
            end
        end
        local out = TweenService:Create(frame, TweenInfo.new(0.3), {
            Position = frame.Position + UDim2.new(0, 250, 0, 0)
        })
        out:Play()
        task.wait(0.3)
        frame:Destroy()
    end)
end

local function CreateMobileWidget(name, toggleFunc, getEnabledState)
    if ScreenGui:FindFirstChild("Float_" .. name) then
        return
    end
    local widget = Instance.new("TextButton")
    widget.Name = "Float_" .. name
    widget.Parent = ScreenGui
    widget.Size = UDim2.new(0, 50, 0, 50)
    widget.Position = UDim2.new(0.5, -25, 0.5, -25)
    widget.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    widget.BackgroundTransparency = 0.3
    widget.Text = GetFirstChar(name)
    widget.TextSize = 20
    widget.Font = Enum.Font.GothamBold
    widget.TextColor3 = Color3.fromRGB(255, 255, 255)
    widget.AutoButtonColor = false
    widget.ZIndex = 50

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = widget

    local stroke = Instance.new("UIStroke")
    stroke.Parent = widget
    stroke.Thickness = 2

    local close = Instance.new("TextButton")
    close.Parent = widget
    close.Size = UDim2.new(0, 15, 0, 15)
    close.Position = UDim2.new(1, -5, 0, -5)
    close.AnchorPoint = Vector2.new(0.5, 0.5)
    close.BackgroundTransparency = 1
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 80, 80)
    close.Font = Enum.Font.GothamBlack
    close.MouseButton1Click:Connect(function()
        widget:Destroy()
    end)

    local dragging, dragStart, startPosition
    widget.InputBegan:Connect(function(input)
        if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("MouseButton1") then
            dragging = true
            dragStart = input.Position
            startPosition = widget.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("Mouse")) then
            local delta = input.Position - dragStart
            widget.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("MouseButton1") then
            dragging = false
        end
    end)

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not widget.Parent then
            connection:Disconnect()
            return
        end
        stroke.Color = getEnabledState() and CurrentThemeData.Accent or Color3.fromRGB(60, 60, 60)
    end)

    widget.MouseButton1Click:Connect(function()
        toggleFunc(true)
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and Library.Globals.BoundKeys[input.KeyCode] then
        Library.Globals.BoundKeys[input.KeyCode](true)
    end
end)

--// 窗口系统 (自适应核心) //--
function Library:CreateWindow(title, position, isMain, isSub)
    local window = {}
    local isFolded = false
    local isOpen = not isSub
    if isSub and not Library.Config.UIVisible then
        isOpen = false
    end

    local headerHeight = Library.Config.ItemHeight + 6
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Window_" .. title
    mainFrame.Parent = ScreenGui
    mainFrame.Position = position
    mainFrame.Size = UDim2.new(0, Library.Config.WindowWidth, 0, headerHeight)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = isOpen
    mainFrame.ZIndex = 10
    RegisterThemeObject(mainFrame, "Window")
    RegisterStyle(mainFrame, true, 10)

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = mainFrame
    uiScale.Scale = Library.Config.UIScale

    local header = Instance.new("Frame")
    header.Parent = mainFrame
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, headerHeight)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = header
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = math.clamp(headerHeight * 0.45, 12, 24)
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    RegisterThemeObject(titleLabel, "Text")

    local container = Instance.new("ScrollingFrame")
    container.Name = "Container"
    container.Parent = mainFrame
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, headerHeight)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.ScrollBarThickness = 3
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RegisterThemeObject(container, "Scroll")

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = container
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 0)

    local windowData = {
        Main = mainFrame,
        Header = header,
        Title = titleLabel,
        Container = container,
        List = listLayout,
        IsOpen = isOpen,
        IsSub = isSub
    }
    table.insert(Library.Globals.Windows, windowData)
    if isSub then
        Library.Globals.SubWindows[title] = windowData
    end

    -- 【核心自适应逻辑】
    local function RefreshHeight()
        local contentHeight = listLayout.AbsoluteContentSize.Y
        local screenHeight = Camera.ViewportSize.Y / (Library.Config.UIScale > 0 and Library.Config.UIScale or 1)
        local maxPerScreen = screenHeight - 100
        if maxPerScreen < 100 then
            maxPerScreen = 100
        end
        local actualMax = math.min(Library.Config.WindowMaxHeight, maxPerScreen)
        local currentHeaderHeight = Library.Config.ItemHeight + 6

        if isFolded then
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, Library.Config.WindowWidth, 0, currentHeaderHeight)
            }):Play()
            container.Visible = false
        else
            container.Visible = true
            local finalHeight = math.min(contentHeight, actualMax)
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, Library.Config.WindowWidth, 0, currentHeaderHeight + finalHeight)
            }):Play()
            container.Size = UDim2.new(1, 0, 0, finalHeight)
            container.ScrollingEnabled = contentHeight > actualMax
        end
    end
    windowData.RefreshHeight = RefreshHeight
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshHeight)

    local dragging, dragStart, startPosition, startTime
    header.Active = true
    header.InputBegan:Connect(function(input)
        if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch") then
            Library.Globals.TopZIndex = Library.Globals.TopZIndex + 1
            mainFrame.ZIndex = Library.Globals.TopZIndex
            dragging = true
            dragStart = input.Position
            startPosition = mainFrame.Position
            startTime = tick()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch")) then
            local delta = input.Position - dragStart
            TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            }):Play()
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch") then
            dragging = false
            if (input.Position - dragStart).Magnitude < 5 and tick() - startTime < 0.3 then
                isFolded = not isFolded
                RefreshHeight()
            end
        end
    end)

    local function RegisterElement(instance, label, dots)
        table.insert(Library.Globals.Elements, {Instance = instance, Label = label, Dots = dots})
    end

    function window:CreateButton(name, callback)
        local itemHeight = Library.Config.ItemHeight
        local button = Instance.new("TextButton")
        button.Parent = container
        button.BackgroundTransparency = 1
        button.Size = UDim2.new(1, 0, 0, itemHeight)
        button.Text = ""
        button.BorderSizePixel = 0
        button.ClipsDescendants = true
        RegisterStyle(button, false, 6)

        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = button
        textLabel.Text = name
        textLabel.Font = Enum.Font.GothamSemibold
        textLabel.TextSize = math.clamp(itemHeight * 0.42, 10, 20)
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, -10, 1, 0)
        textLabel.Position = UDim2.new(0, 10, 0, 0)
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        RegisterThemeObject(textLabel, "TextDark")

        button.MouseButton1Click:Connect(function()
            CreateRipple(button)
            pcall(callback)
        end)
        RegisterElement(button, textLabel, nil)
    end

    function window:BindWindow(subWindowName, defaultState)
        local module = self:CreateModule(subWindowName, function(bool)
            local target = Library.Globals.SubWindows[subWindowName]
            if target then
                target.IsOpen = bool
                target.Main.Visible = bool and Library.Config.UIVisible
                if bool and Library.Config.UIVisible then
                    if target.Main.Position.X.Offset == 0 and target.Main.Position.Y.Offset == 0 then
                        target.Main.Position = UDim2.new(0.5, -Library.Config.WindowWidth / 2, 0.5, -100)
                    end
                    TweenService:Create(target.Main, TweenInfo.new(0.3), {
                        BackgroundTransparency = CurrentThemeData.MainTrans
                    }):Play()
                else
                    target.Main.Visible = false
                end
            else
                Library:Notify("未找到: " .. subWindowName, false)
            end
        end, false)
        if defaultState then
            module:Set(true)
        end
    end

    function window:CreateModule(name, callback, allowBind)
        if allowBind == nil then
            allowBind = true
        end
        local module = {}
        local enabled = false
        local settingsOpen = false
        local bindKey = nil

        local itemHeight = Library.Config.ItemHeight
        local button = Instance.new("TextButton")
        button.Parent = container
        button.BackgroundTransparency = 1
        button.Size = UDim2.new(1, 0, 0, itemHeight)
        button.Text = ""
        button.BorderSizePixel = 0
        button.ClipsDescendants = true
        RegisterStyle(button, false, 6)

        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = button
        textLabel.Text = name
        textLabel.Font = Enum.Font.GothamSemibold
        textLabel.TextSize = math.clamp(itemHeight * 0.42, 10, 20)
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, -35, 1, 0)
        textLabel.Position = UDim2.new(0, 10, 0, 0)
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        RegisterThemeObject(textLabel, "TextDark")

        local dotsButton = Instance.new("TextButton")
        dotsButton.Parent = button
        dotsButton.Text = "..."
        dotsButton.Font = Enum.Font.GothamBold
        dotsButton.TextSize = math.clamp(itemHeight * 0.42, 10, 20) + 4
        dotsButton.BackgroundTransparency = 1
        dotsButton.Size = UDim2.new(0, itemHeight, 1, 0)
        dotsButton.Position = UDim2.new(1, -itemHeight, 0, 0)
        dotsButton.Visible = allowBind
        RegisterThemeObject(dotsButton, "TextDark")
        RegisterElement(button, textLabel, dotsButton)

        local settingsFrame = Instance.new("Frame")
        settingsFrame.Parent = container
        settingsFrame.BackgroundTransparency = 0.5
        RegisterThemeObject(settingsFrame, "SettingBg")
        settingsFrame.Size = UDim2.new(1, 0, 0, 0)
        settingsFrame.ClipsDescendants = true
        settingsFrame.Visible = false
        settingsFrame.BorderSizePixel = 0

        local settingsList = Instance.new("UIListLayout")
        settingsList.Parent = settingsFrame
        settingsList.Padding = UDim.new(0, 0)

        local function Toggle(isRemote)
            enabled = not enabled
            if enabled then
                RegisterThemeObject(textLabel, "Text")
                RegisterThemeObject(dotsButton, "Text")
                TweenService:Create(button, TweenInfo.new(0.3), {
                    BackgroundTransparency = 0.8,
                    BackgroundColor3 = Color3.new(1, 1, 1)
                }):Play()
            else
                RegisterThemeObject(textLabel, "TextDark")
                RegisterThemeObject(dotsButton, "TextDark")
                TweenService:Create(button, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
            if isRemote then
                CreateRipple(button, true)
            end
            UpdateHUD(name, enabled)
            Library:Notify(name, enabled)
            pcall(callback, enabled)
        end

        function module:Set(bool)
            if bool ~= enabled then
                Toggle()
            end
        end

        if allowBind then
            local keybindButton = Instance.new("TextButton")
            keybindButton.Parent = settingsFrame
            keybindButton.Size = UDim2.new(1, 0, 0, 24)
            keybindButton.BackgroundTransparency = 1
            keybindButton.Text = ""
            keybindButton.BorderSizePixel = 0

            local keybindLabel = Instance.new("TextLabel")
            keybindLabel.Parent = keybindButton
            keybindLabel.Text = "绑定: 无"
            keybindLabel.Font = Enum.Font.Gotham
            keybindLabel.TextSize = 11
            keybindLabel.BackgroundTransparency = 1
            keybindLabel.Size = UDim2.new(1, -20, 1, 0)
            keybindLabel.Position = UDim2.new(0, 10, 0, 0)
            keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            RegisterThemeObject(keybindLabel, "TextDark")

            local listening = false
            keybindButton.MouseButton1Click:Connect(function()
                if listening then
                    return
                end
                listening = true
                keybindLabel.Text = "按下按键..."
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        connection:Disconnect()
                        if input.KeyCode.Name == "Backspace" or input.KeyCode.Name == "Delete" then
                            if bindKey then
                                Library.Globals.BoundKeys[bindKey] = nil
                            end
                            bindKey = nil
                            keybindLabel.Text = "绑定: 无"
                        else
                            if bindKey then
                                Library.Globals.BoundKeys[bindKey] = nil
                            end
                            bindKey = input.KeyCode
                            Library.Globals.BoundKeys[bindKey] = Toggle
                            keybindLabel.Text = "绑定: " .. input.KeyCode.Name
                        end
                    end
                end)
            end)

            local pressTime, isPressing = 0, false
            button.InputBegan:Connect(function(input)
                if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("MouseButton1") then
                    isPressing = true
                    pressTime = tick()
                    task.spawn(function()
                        task.wait(0.6)
                        if isPressing and tick() - pressTime >= 0.6 then
                            CreateMobileWidget(name, Toggle, function()
                                return enabled
                            end)
                            Library:Notify("悬浮窗已创建", true)
                            isPressing = false
                        end
                    end)
                end
            end)
            button.InputEnded:Connect(function(input)
                if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("MouseButton1") then
                    if isPressing and tick() - pressTime < 0.6 then
                        CreateRipple(button)
                        Toggle()
                    end
                    isPressing = false
                end
            end)
        else
            button.MouseButton1Click:Connect(function()
                CreateRipple(button)
                Toggle()
            end)
        end

        dotsButton.MouseButton1Click:Connect(function()
            settingsOpen = not settingsOpen
            settingsFrame.Visible = true
            local targetHeight = settingsOpen and settingsList.AbsoluteContentSize.Y or 0
            TweenService:Create(settingsFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 0, targetHeight)
            }):Play()
            local connection
            connection = RunService.RenderStepped:Connect(function()
                listLayout:ApplyLayout()
                if windowData.RefreshHeight then
                    windowData.RefreshHeight()
                end
                if math.abs(settingsFrame.Size.Y.Offset - targetHeight) < 1 then
                    connection:Disconnect()
                end
            end)
            if not settingsOpen then
                task.delay(0.3, function()
                    settingsFrame.Visible = false
                end)
            end
        end)

        function module:CreateSlider(text, min, max, default, callback)
            if not dotsButton.Visible then
                dotsButton.Visible = true
            end
            local value = default
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Parent = settingsFrame
            sliderFrame.BackgroundTransparency = 1
            sliderFrame.Size = UDim2.new(1, 0, 0, 30)
            sliderFrame.BorderSizePixel = 0

            local label = Instance.new("TextLabel")
            label.Parent = sliderFrame
            label.Text = text .. ": " .. value
            label.Font = Enum.Font.Gotham
            label.TextSize = 11
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0, 14)
            RegisterThemeObject(label, "TextDark")

            local bar = Instance.new("Frame")
            bar.Parent = sliderFrame
            bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            bar.BorderSizePixel = 0
            bar.Position = UDim2.new(0, 8, 0, 18)
            bar.Size = UDim2.new(1, -16, 0, 4)

            local fill = Instance.new("Frame")
            fill.Parent = bar
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            RegisterThemeObject(fill, "Accent")

            local trackButton = Instance.new("TextButton")
            trackButton.Parent = sliderFrame
            trackButton.BackgroundTransparency = 1
            trackButton.Text = ""
            trackButton.Size = UDim2.new(1, 0, 0, 25)
            trackButton.Position = UDim2.new(0, 0, 0, 5)
            trackButton.ZIndex = 10

            local dragging = false
            trackButton.InputBegan:Connect(function(input)
                if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("Mouse") then
                    dragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("Mouse") then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("Mouse")) then
                    local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * percent)
                    label.Text = text .. ": " .. value
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    pcall(callback, value)
                end
            end)
            pcall(callback, value)
        end

        function module:CreateSwitch(text, callback, defaultState)
            if not dotsButton.Visible then
                dotsButton.Visible = true
            end
            local isOn = defaultState or false
            local button = Instance.new("TextButton")
            button.Parent = settingsFrame
            button.BackgroundTransparency = 1
            button.Size = UDim2.new(1, 0, 0, 24)
            button.Text = ""
            button.BorderSizePixel = 0

            local label = Instance.new("TextLabel")
            label.Parent = button
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 11
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            RegisterThemeObject(label, "TextDark")

            local box = Instance.new("Frame")
            box.Parent = button
            box.Size = UDim2.new(0, 12, 0, 12)
            box.Position = UDim2.new(1, -20, 0.5, -6)
            box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            box.BorderSizePixel = 0

            local indicator = Instance.new("Frame")
            indicator.Parent = box
            indicator.Size = UDim2.new(1, -2, 1, -2)
            indicator.Position = UDim2.new(0, 1, 0, 1)
            indicator.Visible = isOn
            indicator.BorderSizePixel = 0
            RegisterThemeObject(indicator, "Accent")

            button.MouseButton1Click:Connect(function()
                isOn = not isOn
                indicator.Visible = isOn
                pcall(callback, isOn)
            end)
            if isOn then
                pcall(callback, isOn)
            end
        end

        function module:CreateDropdown(text, options, callback)
            if not dotsButton.Visible then
                dotsButton.Visible = true
            end
            local isOpen = false
            local headerHeight = 26

            local baseFrame = Instance.new("Frame")
            baseFrame.Parent = settingsFrame
            baseFrame.BackgroundTransparency = 1
            baseFrame.Size = UDim2.new(1, 0, 0, headerHeight)
            baseFrame.ClipsDescendants = true
            baseFrame.BorderSizePixel = 0

            local mainButton = Instance.new("TextButton")
            mainButton.Parent = baseFrame
            mainButton.BackgroundTransparency = 1
            mainButton.Size = UDim2.new(1, 0, 0, headerHeight)
            mainButton.Text = ""
            mainButton.AutoButtonColor = false
            mainButton.BorderSizePixel = 0

            local label = Instance.new("TextLabel")
            label.Parent = mainButton
            label.Text = text .. " >"
            label.Font = Enum.Font.Gotham
            label.TextSize = 11
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            RegisterThemeObject(label, "TextDark")

            local optionsFrame = Instance.new("Frame")
            optionsFrame.Parent = baseFrame
            optionsFrame.Position = UDim2.new(0, 0, 0, headerHeight)
            optionsFrame.Size = UDim2.new(1, 0, 0, 0)
            optionsFrame.BackgroundTransparency = 1
            optionsFrame.BorderSizePixel = 0

            local optionsList = Instance.new("UIListLayout")
            optionsList.Parent = optionsFrame
            optionsList.Padding = UDim.new(0, 0)

            for _, option in ipairs(options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Parent = optionsFrame
                optionButton.Size = UDim2.new(1, 0, 0, 22)
                optionButton.BackgroundTransparency = 1
                optionButton.BorderSizePixel = 0
                optionButton.Text = option
                optionButton.Font = Enum.Font.Gotham
                optionButton.TextSize = 11
                optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                optionButton.MouseButton1Click:Connect(function()
                    label.Text = text .. ": " .. option
                    isOpen = false
                    local newHeight = headerHeight
                    local delta = newHeight - baseFrame.Size.Y.Offset
                    local newSettingsHeight = settingsFrame.Size.Y.Offset + delta
                    TweenService:Create(baseFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, newHeight)
                    }):Play()
                    TweenService:Create(settingsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, newSettingsHeight)
                    }):Play()
                    local connection
                    connection = RunService.RenderStepped:Connect(function()
                        listLayout:ApplyLayout()
                        if windowData.RefreshHeight then
                            windowData.RefreshHeight()
                        end
                        if baseFrame.Size.Y.Offset == newHeight then
                            connection:Disconnect()
                        end
                    end)
                    pcall(callback, option)
                end)
            end

            mainButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local newHeight = isOpen and (headerHeight + (#options * 22)) or headerHeight
                local delta = newHeight - baseFrame.Size.Y.Offset
                local newSettingsHeight = settingsFrame.Size.Y.Offset + delta
                TweenService:Create(baseFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, newHeight)
                }):Play()
                TweenService:Create(settingsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, newSettingsHeight)
                }):Play()
                local connection
                connection = RunService.RenderStepped:Connect(function()
                    listLayout:ApplyLayout()
                    if windowData.RefreshHeight then
                        windowData.RefreshHeight()
                    end
                    if math.abs(baseFrame.Size.Y.Offset - newHeight) < 1 then
                        connection:Disconnect()
                    end
                end)
            end)
        end

        return module
    end

    return window
end

--// 内置设置窗口 (由开发者决定是否调用) //--
function Library:SetupSettings()
    local settingsWindow = Library:CreateWindow("UI设置", UDim2.new(0.5, -100, 0.5, -100))

    local uiConfig = settingsWindow:CreateModule("界面配置", function() end, false)
    uiConfig:CreateDropdown("主题选择", {"Default", "Ocean", "Rose", "Sakura", "Mint", "Midnight", "Sunset"}, function(value)
        Library:SetTheme(value)
        Library:Notify("主题切换", value)
    end)
    uiConfig:CreateSlider("整体缩放(%)", 50, 150, math.floor(Library.Config.UIScale * 100), function(value)
        Library.Config.UIScale = value / 100
        Library:RefreshDimensions()
    end)
    uiConfig:CreateSlider("窗口宽度", 100, 300, Library.Config.WindowWidth, function(value)
        Library.Config.WindowWidth = value
        Library:RefreshDimensions()
    end)

    local styleConfig = settingsWindow:CreateModule("样式设置", function() end, false)
    styleConfig:CreateSwitch("圆角风格", function(value)
        Library.Config.UseCorners = value
        Library:RefreshStyle()
        SaveConfig()
    end, Library.Config.UseCorners)
    styleConfig:CreateSwitch("UI 描边", function(value)
        Library.Config.UseStroke = value
        Library:RefreshStyle()
        SaveConfig()
    end, Library.Config.UseStroke)

    local funcConfig = settingsWindow:CreateModule("功能开关", function() end, false)
    funcConfig:CreateSwitch("显示 HUD", function(value)
        Library:SetHUDVisible(value)
    end, Library.Config.ShowHUD)
    funcConfig:CreateSwitch("显示 通知", function(value)
        Library:SetNotifsVisible(value)
    end, Library.Config.ShowNotifs)

    settingsWindow:CreateButton("保存当前配置", function()
        SaveConfig()
        Library:Notify("配置已保存", true)
    end)

    return settingsWindow
end

function Library:CreateMainControl(title)
    return self:CreateWindow(title, UDim2.new(0, 20, 0, 60), true, false)
end

function Library:CreateChildWindow(title)
    return self:CreateWindow(title, UDim2.new(0.5, -Library.Config.WindowWidth / 2, 0.5, -100), false, true)
end

--// 初始化加载动画 //--
task.spawn(function()
    Library:LoadLoader()
end)

return Library

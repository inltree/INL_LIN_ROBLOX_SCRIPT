-- YC GUI Library - Enhanced Version
-- 功能: 自适应分辨率、灵动岛、HUD、通知、主题系统、高级组件
-- 版本: 2.0

local YCGUI = {}
local ConfigName = "YCUI/settings_advanced.json"

-- 服务引用
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 辅助函数
local function GetFirstChar(str)
    local first = ""
    for _, code in utf8.codes(str) do first = utf8.char(code); break end
    return first ~= "" and first or string.sub(str, 1, 1)
end

local function Round(num, bracket)
    bracket = bracket or 1
    local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
    if a < 0 then a = a + bracket end
    return a
end

local function KeyCheck(x, x1)
    for _, v in next, x1 do if v == x then return true end end
end

-- 默认配置
local DefaultConfig = {
    ShowHUD = true,
    ShowNotifs = true,
    NotifDuration = 3,
    UIScale = 1.0,
    WindowWidth = 200,
    WindowMaxHeight = 400,
    ItemHeight = 36,
    Theme = "Default",
    UIVisible = true,
    UseCorners = true,
    UseStroke = true,
    RainbowEnabled = false,
    AnimationSpeed = 1.0
}

YCGUI.Config = HttpService:JSONDecode(HttpService:JSONEncode(DefaultConfig))
YCGUI.Globals = {
    Windows = {},
    Elements = {},
    ThemeObjects = {},
    StyleObjects = {},
    ActiveNotifs = {},
    BoundKeys = {},
    IslandPosition = Vector2.new(0,0),
    IslandObject = nil,
    HUDGradients = {},
    SubWindows = {},
    TopZIndex = 100,
    ActivePopup = nil,
    Dragging = false,
    DragInput = nil,
    DragStart = nil,
    StartPos = nil,
    DragObject = nil
}

-- 拖拽系统（从library.txt优化）
local function UpdateDrag(input)
    if not YCGUI.Globals.Dragging or not YCGUI.Globals.DragObject then return end
    local delta = input.Position - YCGUI.Globals.DragStart
    local yPos = (YCGUI.Globals.StartPos.Y.Offset + delta.Y) < -36 and -36 or YCGUI.Globals.StartPos.Y.Offset + delta.Y
    YCGUI.Globals.DragObject:TweenPosition(
        UDim2.new(
            YCGUI.Globals.StartPos.X.Scale, 
            YCGUI.Globals.StartPos.X.Offset + delta.X,
            YCGUI.Globals.StartPos.Y.Scale, 
            yPos
        ), 
        "Out", "Quint", 0.1, true
    )
end

-- 彩虹效果（从library.txt优化）
local ChromaColor
local RainbowTime = 5
spawn(function()
    while wait() do
        ChromaColor = Color3.fromHSV(tick() % RainbowTime / RainbowTime, 1, 1)
    end
end)

-- 主题系统
YCGUI.Themes = {
    ["Default"] = { 
        Name = "紫罗兰 (Default)",
        Main = Color3.fromRGB(20, 20, 25), MainTrans = 0.1, 
        Gradient1 = Color3.fromRGB(140, 40, 255),
        Text = Color3.fromRGB(255, 255, 255), 
        TextDark = Color3.fromRGB(160, 160, 170),
        SettingBg = Color3.fromRGB(25, 25, 30), 
        Accent = Color3.fromRGB(100, 20, 220),
        Scroll = Color3.fromRGB(80, 60, 100),
        ToggleOn = Color3.fromRGB(255, 65, 65),
        ToggleOff = Color3.fromRGB(100, 100, 100)
    },
    ["Ocean"] = { 
        Name = "深海蓝 (Ocean)",
        Main = Color3.fromRGB(15, 25, 30), MainTrans = 0.1, 
        Gradient1 = Color3.fromRGB(0, 160, 255),
        Text = Color3.fromRGB(240, 255, 255), 
        TextDark = Color3.fromRGB(140, 160, 170),
        SettingBg = Color3.fromRGB(20, 30, 35), 
        Accent = Color3.fromRGB(0, 100, 180),
        Scroll = Color3.fromRGB(50, 70, 90),
        ToggleOn = Color3.fromRGB(0, 200, 255),
        ToggleOff = Color3.fromRGB(80, 120, 140)
    },
    ["Rose"] = { 
        Name = "暗红玫瑰 (Rose)",
        Main = Color3.fromRGB(25, 15, 15), MainTrans = 0.1, 
        Gradient1 = Color3.fromRGB(220, 20, 60),
        Text = Color3.fromRGB(255, 230, 230), 
        TextDark = Color3.fromRGB(180, 120, 120),
        SettingBg = Color3.fromRGB(35, 20, 20), 
        Accent = Color3.fromRGB(150, 0, 40),
        Scroll = Color3.fromRGB(90, 50, 50),
        ToggleOn = Color3.fromRGB(220, 20, 60),
        ToggleOff = Color3.fromRGB(120, 60, 60)
    }
}

local CurrentThemeData = YCGUI.Themes["Default"]

-- 配置管理
local function CheckFolder() 
    if not isfolder("YCUI") then makefolder("YCUI") end 
end

local function SaveConfig() 
    CheckFolder()
    pcall(function() 
        writefile(ConfigName, HttpService:JSONEncode(YCGUI.Config)) 
    end)
end

local function LoadConfig()
    CheckFolder()
    if isfile(ConfigName) then
        local success, result = pcall(function() 
            return HttpService:JSONDecode(readfile(ConfigName)) 
        end)
        if success and result then 
            for k, v in pairs(result) do 
                YCGUI.Config[k] = v 
            end
            CurrentThemeData = YCGUI.Themes[YCGUI.Config.Theme] or YCGUI.Themes["Default"]
        end
    end
end
LoadConfig()

-- 创建主GUI
if game.CoreGui:FindFirstChild("YC_GUI_Enhanced") then 
    game.CoreGui.YC_GUI_Enhanced:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YC_GUI_Enhanced"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then 
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

-- 背景遮罩
local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Parent = ScreenGui
Backdrop.BackgroundColor3 = Color3.new(0,0,0)
Backdrop.BackgroundTransparency = 1
Backdrop.Size = UDim2.new(1,0,1,0)
Backdrop.ZIndex = 0
Backdrop.Visible = false

-- 实例创建函数（从library.txt优化）
function YCGUI:Create(class, properties)
    properties = typeof(properties) == "table" and properties or {}
    local inst = Instance.new(class)
    for property, value in next, properties do
        inst[property] = value
    end
    return inst
end

-- 样式系统
local function RegisterStyle(obj, hasStroke, cornerRadius)
    table.insert(YCGUI.Globals.StyleObjects, {
        Object = obj, 
        HasStroke = hasStroke, 
        Radius = cornerRadius
    })
    
    local Corner = obj:FindFirstChild("UICorner") or Instance.new("UICorner")
    Corner.Parent = obj
    Corner.CornerRadius = UDim.new(0, YCGUI.Config.UseCorners and cornerRadius or 0)
    
    if hasStroke then
        local Stroke = obj:FindFirstChild("UIStroke") or Instance.new("UIStroke")
        Stroke.Parent = obj
        Stroke.Thickness = 1.5
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = CurrentThemeData.Accent 
        Stroke.Transparency = YCGUI.Config.UseStroke and 0 or 1
    end
end

function YCGUI:RefreshStyle()
    local useCorners = YCGUI.Config.UseCorners
    local useStroke = YCGUI.Config.UseStroke
    
    for _, data in ipairs(YCGUI.Globals.StyleObjects) do
        local obj = data.Object
        if obj and obj.Parent then
            local Corner = obj:FindFirstChild("UICorner")
            if Corner then
                TweenService:Create(Corner, TweenInfo.new(0.3), {
                    CornerRadius = UDim.new(0, useCorners and data.Radius or 0)
                }):Play()
            end
            if data.HasStroke then
                local Stroke = obj:FindFirstChild("UIStroke")
                if Stroke then
                    TweenService:Create(Stroke, TweenInfo.new(0.3), {
                        Transparency = useStroke and 0 or 1,
                        Color = CurrentThemeData.Accent
                    }):Play()
                end
            end
        end
    end
end

-- 主题对象注册
local function RegisterObject(obj, type)
    table.insert(YCGUI.Globals.ThemeObjects, {Object = obj, Type = type})
    local theme = CurrentThemeData
    
    if type == "Window" then 
        obj.BackgroundColor3 = theme.Main
        obj.BackgroundTransparency = theme.MainTrans
    elseif type == "Text" then 
        obj.TextColor3 = theme.Text
    elseif type == "TextDark" then 
        obj.TextColor3 = theme.TextDark
    elseif type == "SettingBg" then 
        obj.BackgroundColor3 = theme.SettingBg
    elseif type == "Accent" then 
        obj.BackgroundColor3 = theme.Accent
    elseif type == "Scroll" then 
        obj.ScrollBarImageColor3 = theme.Scroll
    elseif type == "ToggleOn" then
        obj.BackgroundColor3 = theme.ToggleOn
    elseif type == "ToggleOff" then
        obj.BackgroundColor3 = theme.ToggleOff
    end
end

function YCGUI:RefreshTheme()
    local theme = CurrentThemeData
    for _, data in ipairs(YCGUI.Globals.ThemeObjects) do
        local obj = data.Object
        if obj and obj.Parent then
            local tweenInfo = TweenInfo.new(0.5 * YCGUI.Config.AnimationSpeed)
            if data.Type == "Window" then 
                TweenService:Create(obj, tweenInfo, {BackgroundColor3 = theme.Main}):Play()
            elseif data.Type == "Text" then 
                TweenService:Create(obj, tweenInfo, {TextColor3 = theme.Text}):Play()
            elseif data.Type == "TextDark" then 
                TweenService:Create(obj, tweenInfo, {TextColor3 = theme.TextDark}):Play()
            elseif data.Type == "Accent" then 
                TweenService:Create(obj, tweenInfo, {BackgroundColor3 = theme.Accent}):Play()
            elseif data.Type == "Scroll" then 
                TweenService:Create(obj, tweenInfo, {ScrollBarImageColor3 = theme.Scroll}):Play()
            end
        end
    end
    self:RefreshStyle()
end

-- 灵动岛
local function CreateDynamicIsland()
    local Island = YCGUI:Create("TextButton", {
        Name = "DynamicIsland",
        Parent = ScreenGui,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0.5, 0, 0, 10),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = YCGUI.Config.UIVisible and 0.1 or 0.6,
        Text = "YC GUI",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        ZIndex = 100
    })
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Island
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 1.5
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = YCGUI.Config.UIVisible and 0.5 or 0.9
    UIStroke.Parent = Island
    
    YCGUI.Globals.IslandObject = Island
    
    local function UpdatePos() 
        YCGUI.Globals.IslandPosition = Island.AbsolutePosition + (Island.AbsoluteSize / 2) 
    end
    
    Island:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePos)
    task.defer(UpdatePos)
    
    Island.MouseButton1Click:Connect(function()
        TweenService:Create(Island, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 25)}):Play()
        task.delay(0.1, function()
            TweenService:Create(Island, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {
                Size = UDim2.new(0, 100, 0, 30)
            }):Play()
        end)
        YCGUI:ToggleInterface(not YCGUI.Config.UIVisible)
    end)
end

-- 界面切换
function YCGUI:ToggleInterface(visible)
    self.Config.UIVisible = visible
    Backdrop.Visible = visible
    
    TweenService:Create(Backdrop, TweenInfo.new(0.5), {
        BackgroundTransparency = visible and 0.4 or 1
    }):Play()
    
    if self.Globals.IslandObject then
        local Island = self.Globals.IslandObject
        if visible then
            TweenService:Create(Island, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
            if not self.Config.UseStroke then
                TweenService:Create(Island.UIStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
            end
        else
            TweenService:Create(Island, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
            if not self.Config.UseStroke then
                TweenService:Create(Island.UIStroke, TweenInfo.new(0.3), {Transparency = 0.9}):Play()
            end
        end
    end
    
    -- 涟漪效果
    local Origin = self.Globals.IslandPosition
    local ScreenSize = ScreenGui.AbsoluteSize
    local MaxRadius = math.sqrt(ScreenSize.X^2 + ScreenSize.Y^2)
    
    if visible then
        local Ripple = YCGUI:Create("Frame", {
            Name = "FullRipple",
            Parent = ScreenGui,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, Origin.X, 0, Origin.Y),
            BackgroundColor3 = CurrentThemeData.Accent,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            ZIndex = 1
        })
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Ripple
        
        Ripple.Size = UDim2.new(0, 0, 0, 0)
        local tween = TweenService:Create(Ripple, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, MaxRadius * 2, 0, MaxRadius * 2),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function() Ripple:Destroy() end)

        local Duration = 0.6
        local StartTime = tick()
        
        for _, winData in ipairs(self.Globals.Windows) do 
            if winData.IsOpen then 
                winData.Main.Visible = false
                winData.Main.BackgroundTransparency = 1 
            end
        end
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - StartTime
            local progress = math.clamp(elapsed / Duration, 0, 1)
            local currentRadius = progress * MaxRadius * 1.2
            
            for _, winData in ipairs(self.Globals.Windows) do
                if winData.IsOpen then
                    local winPos = winData.Main.AbsolutePosition + (winData.Main.AbsoluteSize / 2)
                    local dist = (winPos - Origin).Magnitude
                    if currentRadius >= dist and not winData.Main.Visible then
                        winData.Main.Visible = true
                        TweenService:Create(winData.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            BackgroundTransparency = CurrentThemeData.MainTrans
                        }):Play()
                    end
                end
            end
            if progress >= 1 then connection:Disconnect() end
        end)
    else
        for _, winData in ipairs(self.Globals.Windows) do
            if winData.Main.Visible then
                TweenService:Create(winData.Main, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end
        task.delay(0.2, function()
            if not self.Config.UIVisible then 
                for _, w in ipairs(self.Globals.Windows) do 
                    w.Main.Visible = false 
                end
                Backdrop.Visible = false 
            end
        end)
    end
end

-- HUD系统
local HUDFrame = YCGUI:Create("Frame", {
    Name = "HUD",
    Parent = ScreenGui,
    Position = UDim2.new(1, -10, 0, 50),
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 300, 1, -60),
    BackgroundTransparency = 1,
    Visible = YCGUI.Config.ShowHUD
})

local HUDLayout = Instance.new("UIListLayout")
HUDLayout.Parent = HUDFrame
HUDLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
HUDLayout.Padding = UDim.new(0, 0)
HUDLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 通知系统
function YCGUI:Notify(title, status, duration)
    if not self.Config.ShowNotifs then return end
    duration = duration or self.Config.NotifDuration
    
    local Frame = YCGUI:Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 200, 0, 35),
        Position = UDim2.new(1, 50, 1, -50)
    })
    
    local Bar = YCGUI:Create("Frame", {
        Parent = Frame,
        Size = UDim2.new(0, 2, 1, 0),
        BorderSizePixel = 0
    })
    RegisterObject(Bar, "Accent")
    
    local TitleLab = YCGUI:Create("TextLabel", {
        Parent = Frame,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0.5, 0),
        Position = UDim2.new(0, 10, 0, 3),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local StateLab = YCGUI:Create("TextLabel", {
        Parent = Frame,
        Text = status and "已开启" or "已关闭",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = status and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0.5, 0),
        Position = UDim2.new(0, 10, 0.5, -2),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local yOffset = 0
    for i = #self.Globals.ActiveNotifs, 1, -1 do
        local n = self.Globals.ActiveNotifs[i]
        if n.Parent then
            TweenService:Create(n, TweenInfo.new(0.3), {
                Position = UDim2.new(1, -210, 1, -50 - yOffset)
            }):Play()
            yOffset = yOffset + 40
        end
    end
    
    table.insert(self.Globals.ActiveNotifs, Frame)
    TweenService:Create(Frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -210, 1, -50 - yOffset)
    }):Play()
    
    task.delay(duration, function()
        for i, v in ipairs(self.Globals.ActiveNotifs) do
            if v == Frame then
                table.remove(self.Globals.ActiveNotifs, i)
                break
            end
        end
        local out = TweenService:Create(Frame, TweenInfo.new(0.3), {
            Position = Frame.Position + UDim2.new(0, 250, 0, 0)
        })
        out:Play()
        task.wait(0.3)
        Frame:Destroy()
    end)
end

-- 窗口系统（核心）
function YCGUI:CreateWindow(title, position, isMain, isSub)
    local Window = {}
    local isFolded = false
    local isOpen = not isSub
    
    if isSub and not self.Config.UIVisible then
        isOpen = false
    end
    
    local HeaderH = self.Config.ItemHeight + 6
    
    -- 主窗口框架
    local Main = YCGUI:Create("Frame", {
        Name = "Window_" .. title,
        Parent = ScreenGui,
        Position = position,
        Size = UDim2.new(0, self.Config.WindowWidth, 0, HeaderH),
        BorderSizePixel = 0,
        Visible = isOpen,
        ZIndex = 10
    })
    
    RegisterObject(Main, "Window")
    RegisterStyle(Main, true, 10)
    
    local Scale = Instance.new("UIScale")
    Scale.Parent = Main
    Scale.Scale = self.Config.UIScale
    
    -- 标题栏
    local Header = YCGUI:Create("Frame", {
        Parent = Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, HeaderH)
    })
    
    local Title = YCGUI:Create("TextLabel", {
        Parent = Header,
        Text = title,
        Font = Enum.Font.GothamBlack,
        TextSize = math.clamp(HeaderH * 0.45, 12, 24),
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1
    })
    RegisterObject(Title, "Text")
    
    -- 内容容器
    local Container = YCGUI:Create("ScrollingFrame", {
        Name = "Container",
        Parent = Main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, HeaderH),
        Size = UDim2.new(1, 0, 0, 0),
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    RegisterObject(Container, "Scroll")
    
    local List = Instance.new("UIListLayout")
    List.Parent = Container
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 0)
    
    local winData = {
        Main = Main,
        Header = Header,
        Title = Title,
        Container = Container,
        List = List,
        IsOpen = isOpen,
        IsSub = isSub
    }
    
    table.insert(self.Globals.Windows, winData)
    if isSub then
        self.Globals.SubWindows[title] = winData
    end
    
    -- 自适应高度计算
    local function RefreshHeight()
        local contentH = List.AbsoluteContentSize.Y
        local screenHeight = Camera.ViewportSize.Y / (self.Config.UIScale > 0 and self.Config.UIScale or 1)
        local maxPerScreen = screenHeight - 100
        if maxPerScreen < 100 then maxPerScreen = 100 end
        
        local actualMax = math.min(self.Config.WindowMaxHeight, maxPerScreen)
        local curHeadH = self.Config.ItemHeight + 6
        
        if isFolded then
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, self.Config.WindowWidth, 0, curHeadH)
            }):Play
    Container.Visible = false
else
    Container.Visible = true
    local finalH = math.min(contentH, actualMax)
    
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, self.Config.WindowWidth, 0, curHeadH + finalH)
    }):Play()
    
    Container.Size = UDim2.new(1, 0, 0, finalH)
    Container.ScrollingEnabled = contentH > actualMax
end
end

winData.RefreshHeight = RefreshHeight
List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshHeight)

-- 拖拽功能
local drag, dStart, sPos, sTime
Header.Active = true

Header.InputBegan:Connect(function(input)
    if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch") then
        YCGUI.Globals.TopZIndex = YCGUI.Globals.TopZIndex + 1
        Main.ZIndex = YCGUI.Globals.TopZIndex
        drag = true
        dStart = input.Position
        sPos = Main.Position
        sTime = tick()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if drag and (input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch")) then
        local delta = input.Position - dStart
        TweenService:Create(Main, TweenInfo.new(0.05), {
            Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
        }):Play()
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch") then
        drag = false
        if (input.Position - dStart).Magnitude < 5 and tick() - sTime < 0.3 then
            isFolded = not isFolded
            RefreshHeight()
        end
    end
end)

-- 组件创建函数
function Window:CreateLabel(text)
    local H = self.Config.ItemHeight
    local Label = YCGUI:Create("TextLabel", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, H),
        Text = "  " .. text,
        Font = Enum.Font.GothamSemibold,
        TextSize = math.clamp(H * 0.42, 10, 20),
        TextColor3 = CurrentThemeData.TextDark,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0
    })
    RegisterObject(Label, "TextDark")
    
    return Label
end

function Window:CreateButton(text, callback)
    local H = self.Config.ItemHeight
    local Btn = YCGUI:Create("TextButton", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, H),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    
    RegisterStyle(Btn, false, 6)
    
    local Bg = YCGUI:Create("Frame", {
        Parent = Btn,
        Size = UDim2.new(1, -12, 1, -6),
        Position = UDim2.new(0, 6, 0, 3),
        BackgroundColor3 = CurrentThemeData.SettingBg,
        BorderSizePixel = 0
    })
    RegisterObject(Bg, "SettingBg")
    RegisterStyle(Bg, false, 4)
    
    local Txt = YCGUI:Create("TextLabel", {
        Parent = Bg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = math.clamp(H * 0.42, 10, 20),
        TextColor3 = CurrentThemeData.Text,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    RegisterObject(Txt, "Text")
    
    -- 涟漪效果
    local function CreateRipple()
        local ripple = YCGUI:Create("Frame", {
            Parent = Bg,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 0)
        })
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = ripple
        
        local size = math.max(Bg.AbsoluteSize.X, Bg.AbsoluteSize.Y) * 1.5
        TweenService:Create(ripple, TweenInfo.new(0.4), {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1
        }):Play()
        
        task.delay(0.45, function() ripple:Destroy() end)
    end
    
    Btn.MouseButton1Click:Connect(function()
        CreateRipple()
        pcall(callback)
    end)
    
    return Btn
end

function Window:CreateToggle(text, callback, defaultState)
    local Toggle = {}
    local enabled = defaultState or false
    local H = self.Config.ItemHeight
    
    local Btn = YCGUI:Create("TextButton", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, H),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    
    local Bg = YCGUI:Create("Frame", {
        Parent = Btn,
        Size = UDim2.new(1, -12, 1, -6),
        Position = UDim2.new(0, 6, 0, 3),
        BackgroundColor3 = CurrentThemeData.SettingBg,
        BorderSizePixel = 0
    })
    RegisterObject(Bg, "SettingBg")
    RegisterStyle(Bg, false, 4)
    
    local Txt = YCGUI:Create("TextLabel", {
        Parent = Bg,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = math.clamp(H * 0.42, 10, 20),
        TextColor3 = CurrentThemeData.TextDark,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    RegisterObject(Txt, "TextDark")
    
    local ToggleBg = YCGUI:Create("Frame", {
        Parent = Bg,
        Size = UDim2.new(0, 30, 0, 16),
        Position = UDim2.new(1, -35, 0.5, -8),
        BackgroundColor3 = CurrentThemeData.ToggleOff,
        BorderSizePixel = 0
    })
    RegisterObject(ToggleBg, "ToggleOff")
    RegisterStyle(ToggleBg, false, 8)
    
    local ToggleKnob = YCGUI:Create("Frame", {
        Parent = ToggleBg,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })
    RegisterStyle(ToggleKnob, false, 6)
    
    local function UpdateToggle()
        if enabled then
            TweenService:Create(ToggleBg, TweenInfo.new(0.2), {
                BackgroundColor3 = CurrentThemeData.ToggleOn
            }):Play()
            TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {
                Position = UDim2.new(1, -14, 0.5, -6)
            }):Play()
            RegisterObject(Txt, "Text")
        else
            TweenService:Create(ToggleBg, TweenInfo.new(0.2), {
                BackgroundColor3 = CurrentThemeData.ToggleOff
            }):Play()
            TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 2, 0.5, -6)
            }):Play()
            RegisterObject(Txt, "TextDark")
        end
    end
    
    function Toggle:Set(state)
        if enabled ~= state then
            enabled = state
            UpdateToggle()
            pcall(callback, enabled)
        end
    end
    
    function Toggle:Get()
        return enabled
    end
    
    Btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        UpdateToggle()
        pcall(callback, enabled)
        YCGUI:Notify(text, enabled)
    end)
    
    UpdateToggle()
    return Toggle
end

function Window:CreateSlider(text, min, max, defaultValue, callback)
    local Slider = {}
    local value = defaultValue or min
    local H = self.Config.ItemHeight + 10
    
    local Main = YCGUI:Create("Frame", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, H),
        BorderSizePixel = 0
    })
    
    local Title = YCGUI:Create("TextLabel", {
        Parent = Main,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text .. ": " .. value,
        Font = Enum.Font.GothamSemibold,
        TextSize = math.clamp(H * 0.35, 10, 16),
        TextColor3 = CurrentThemeData.TextDark,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    RegisterObject(Title, "TextDark")
    
    local Track = YCGUI:Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, -20, 0, 4),
        Position = UDim2.new(0, 10, 1, -14),
        BackgroundColor3 = CurrentThemeData.SettingBg,
        BorderSizePixel = 0
    })
    RegisterObject(Track, "SettingBg")
    RegisterStyle(Track, false, 2)
    
    local Fill = YCGUI:Create("Frame", {
        Parent = Track,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = CurrentThemeData.Accent,
        BorderSizePixel = 0
    })
    RegisterObject(Fill, "Accent")
    RegisterStyle(Fill, false, 2)
    
    local Knob = YCGUI:Create("Frame", {
        Parent = Track,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })
    RegisterStyle(Knob, false, 6)
    
    local dragging = false
    
    local function SetValue(newValue)
        value = math.clamp(newValue, min, max)
        Title.Text = text .. ": " .. Round(value, 1)
        Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        Knob.Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6)
        pcall(callback, value)
    end
    
    function Slider:Set(newValue)
        SetValue(newValue)
    end
    
    function Slider:Get()
        return value
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch") then
            dragging = true
            local percent = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
            SetValue(min + (max - min) * math.clamp(percent, 0, 1))
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch")) then
            local percent = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
            SetValue(min + (max - min) * math.clamp(percent, 0, 1))
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Touch") then
            dragging = false
        end
    end)
    
    return Slider
end

function Window:CreateDropdown(text, options, defaultOption, callback)
    local Dropdown = {}
    local selected = defaultOption or options[1]
    local isOpen = false
    local H = self.Config.ItemHeight
    
    local Main = YCGUI:Create("TextButton", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, H),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    
    local Bg = YCGUI:Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, -12, 1, -6),
        Position = UDim2.new(0, 6, 0, 3),
        BackgroundColor3 = CurrentThemeData.SettingBg,
        BorderSizePixel = 0
    })
    RegisterObject(Bg, "SettingBg")
    RegisterStyle(Bg, false, 4)
    
    local Title = YCGUI:Create("TextLabel", {
        Parent = Bg,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text .. ": " .. selected,
        Font = Enum.Font.GothamSemibold,
        TextSize = math.clamp(H * 0.42, 10, 20),
        TextColor3 = CurrentThemeData.TextDark,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    RegisterObject(Title, "TextDark")
    
    local Arrow = YCGUI:Create("TextLabel", {
        Parent = Bg,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -25, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        Font = Enum.Font.GothamBold,
        TextSize = math.clamp(H * 0.35, 10, 16),
        TextColor3 = CurrentThemeData.TextDark,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    RegisterObject(Arrow, "TextDark")
    
    local OptionsFrame = YCGUI:Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.new(0, 6, 1, 0),
        BackgroundColor3 = CurrentThemeData.SettingBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false
    })
    RegisterObject(OptionsFrame, "SettingBg")
    RegisterStyle(OptionsFrame, false, 4)
    
    local OptionsList = Instance.new("UIListLayout")
    OptionsList.Parent = OptionsFrame
    OptionsList.SortOrder = Enum.SortOrder.LayoutOrder
    OptionsList.Padding = UDim.new(0, 0)
    
    for _, option in ipairs(options) do
        local OptionBtn = YCGUI:Create("TextButton", {
            Parent = OptionsFrame,
            Size = UDim2.new(1, 0, 0, H - 6),
            BackgroundTransparency = 1,
            Text = option,
            Font = Enum.Font.GothamSemibold,
            TextSize = math.clamp(H * 0.42, 10, 20),
            TextColor3 = CurrentThemeData.TextDark,
            BorderSizePixel = 0,
            AutoButtonColor = false
        })
        RegisterObject(OptionBtn, "TextDark")
        
        OptionBtn.MouseButton1Click:Connect(function()
            selected = option
            Title.Text = text .. ": " .. selected
            TweenService:Create(OptionsFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.3, function() OptionsFrame.Visible = false end)
            isOpen = false
            TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
            pcall(callback, selected)
        end)
    end
    
    function Dropdown:Set(option)
        if table.find(options, option) then
            selected = option
            Title.Text = text .. ": " .. selected
            pcall(callback, selected)
        end
    end
    
    function Dropdown:Get()
        return selected
    end
    
    Main.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            OptionsFrame.Visible = true
            local height = #options * (H - 6)
            TweenService:Create(OptionsFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 0, height)
            }):Play()
            TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
        else
            TweenService:Create(OptionsFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            task.delay(0.3, function() OptionsFrame.Visible = false end)
            TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
        end
    end)
    
    return Dropdown
end

function Window:CreateColorPicker(text, defaultColor, callback)
    local ColorPicker = {}
    local color = defaultColor or Color3.new(1, 1, 1)
    local H = self.Config.ItemHeight
    
    local Main = YCGUI:Create("TextButton", {
        Parent = Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, H),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    })
    
    local Bg = YCGUI:Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, -12, 1, -6),
        Position = UDim2.new(0, 6, 0, 3),
        BackgroundColor3 = CurrentThemeData.SettingBg,
        BorderSizePixel = 0
    })
    RegisterObject(Bg, "SettingBg")
    RegisterStyle(Bg, false, 4)
    
    local Title = YCGUI:Create("TextLabel", {
        Parent = Bg,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = math.clamp(H * 0.42, 10, 20),
        TextColor3 = CurrentThemeData.TextDark,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    RegisterObject(Title, "TextDark")
    
    local ColorPreview = YCGUI:Create("Frame", {
        Parent = Bg,
        Size = UDim2.new(0, 30, 0, 20),
        Position = UDim2.new(1, -35, 0.5, -10),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    })
    RegisterStyle(ColorPreview, true, 4)
    
    function ColorPicker:Set(newColor)
        color = newColor
        ColorPreview.BackgroundColor3 = color
        pcall(callback, color)
    end
    
    function ColorPicker:Get()
        return color
    end
    
    -- 颜色选择器窗口（简化版）
    Main.MouseButton1Click:Connect(function()
        -- 创建颜色选择器弹窗
        local PickerWindow = YCGUI:Create("Frame", {
            Parent = ScreenGui,
            Size = UDim2.new(0, 200, 0, 150),
            Position = UDim2.new(0.5, -100, 0.5, -75),
            BackgroundColor3 = CurrentThemeData.Main,
            BorderSizePixel = 0,
            ZIndex = 100
        })
        RegisterObject(PickerWindow, "Window")
        RegisterStyle(PickerWindow, true, 8)
        
        -- 这里可以添加完整的颜色选择器逻辑
        -- 由于代码量限制，这里只提供基本框架
        
        local CloseBtn = YCGUI:Create("TextButton", {
            Parent = PickerWindow,
            Size = UDim2.new(0, 60, 0, 25),
            Position = UDim2.new(0.5, -30, 1, -30),
            BackgroundColor3 = CurrentThemeData.Accent,
            Text = "应用",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            BorderSizePixel = 0,
            AutoButtonColor = false
        })
        RegisterStyle(CloseBtn, false, 4)
        
        CloseBtn.MouseButton1Click:Connect(function()
            ColorPicker:Set(Color3.new(1, 0, 0)) -- 示例颜色
            PickerWindow:Destroy()
        end)
    end)
    
    return ColorPicker
end

return Window
end

-- 初始化函数
function YCGUI:Init()
    ScreenGui.Enabled = true
    CreateDynamicIsland()
    self:RefreshTheme()
    self:RefreshStyle()
    self:RefreshDimensions()
    SaveConfig()
    
    -- 防AFK
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    
    return ScreenGui
end

function YCGUI:SetHUDVisible(visible)
    self.Config.ShowHUD = visible
    HUDFrame.Visible = visible
    SaveConfig()
end

function YCGUI:SetNotifsVisible(visible)
    self.Config.ShowNotifs = visible
    SaveConfig()
end

function YCGUI:SetTheme(themeName)
    if self.Themes[themeName] then
        CurrentThemeData = self.Themes[themeName]
        self.Config.Theme = themeName
        self:RefreshTheme()
        SaveConfig()
    end
end

function YCGUI:RefreshDimensions()
    local conf = self.Config
    for _, win in ipairs(self.Globals.Windows) do
        local scale = win.Main:FindFirstChild("UIScale")
        if scale then
            TweenService:Create(scale, TweenInfo.new(0.3), {Scale = conf.UIScale}):Play()
        end
        if win.RefreshHeight then win.RefreshHeight() end
    end
end

function YCGUI:CreateMainWindow(title)
    return self:CreateWindow(title, UDim2.new(0, 20, 0, 60), true, false)
end

function YCGUI:CreateChildWindow(title)
    return self:CreateWindow(title, UDim2.new(0.5, -self.Config.WindowWidth/2, 0.5, -100), false, true)
end

-- 加载动画
function YCGUI:LoadLoader()
    local Loader = Instance.new("ScreenGui")
    Loader.Name = "YC_Loader"
    Loader.IgnoreGuiInset = true
    Loader.DisplayOrder = 10000
    Loader.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Parent = Loader
    Main.BackgroundColor3 = Color3.new(0, 0, 0)
    Main.BackgroundTransparency = 0
    Main.Size = UDim2.new(1, 0, 1, 0)
    Main.ZIndex = 1
    
    local Center = Instance.new("Frame")
    Center.Parent = Main
    Center.Size = UDim2.new(0, 400, 0, 150)
    Center.AnchorPoint = Vector2.new(0.5, 0.5)
    Center.Position = UDim2.new(0.5, 0, 0.5, 0)
    Center.BackgroundTransparency = 1
    Center.ZIndex = 2
    
    local Title = Instance.new("TextLabel")
    Title.Parent = Center
    Title.Text = "YC GUI"
    Title.Font = Enum.Font.Go
    Center.BackgroundTransparency = 1
    Title.TextTransparency = 1
    
    local TitleScale = Instance.new("UIScale")
    TitleScale.Parent = Title
    TitleScale.Scale = 1.1
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Parent = Title
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 50, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255))
    }
    
    local SubTitle = Instance.new("TextLabel")
    SubTitle.Parent = Center
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
    
    -- 开场动画
    TweenService:Create(Main, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
    task.wait(0.2)
    
    local t1 = TweenService:Create(Title, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0})
    local t2 = TweenService:Create(TitleScale, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1.0})
    t1:Play(); t2:Play()
    
    task.wait(0.4)
    
    local subPosFinal = UDim2.new(1, -20, 0.5, 15)
    local t3 = TweenService:Create(SubTitle, TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, Position = subPosFinal})
    t3:Play()
    
    -- 渐变效果
    task.spawn(function()
        local startTime = tick()
        while Loader.Parent do
            local timePassed = tick() - startTime
            Gradient.Rotation = math.sin(timePassed) * 15
            RunService.RenderStepped:Wait()
        end
    end)
    
    task.wait(1.5)
    
    -- 淡出动画
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
    TweenService:Create(TitleScale, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1.1}):Play()
    TweenService:Create(SubTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, Position = subPosFinal + UDim2.new(0,0,0,10)}):Play()
    
    task.wait(0.5)
    ScreenGui.Enabled = true
    Loader:Destroy()
end

-- 输入事件处理
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType.Name:match("Mouse") then
        if YCGUI.Globals.ActivePopup then
            if input.Position.X < YCGUI.Globals.ActivePopup.mainHolder.AbsolutePosition.X or 
               input.Position.Y < YCGUI.Globals.ActivePopup.mainHolder.AbsolutePosition.Y then
                YCGUI.Globals.ActivePopup:Close()
            end
            if input.Position.X > YCGUI.Globals.ActivePopup.mainHolder.AbsolutePosition.X + YCGUI.Globals.ActivePopup.mainHolder.AbsoluteSize.X or 
               input.Position.Y > YCGUI.Globals.ActivePopup.mainHolder.AbsolutePosition.Y + YCGUI.Globals.ActivePopup.mainHolder.AbsoluteSize.Y then
                YCGUI.Globals.ActivePopup:Close()
            end
        end
    end
    
    -- 绑定键检测
    if not UserInputService:GetFocusedTextBox() then
        for keyCode, callback in pairs(YCGUI.Globals.BoundKeys) do
            if input.KeyCode == keyCode then
                pcall(callback, true)
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == YCGUI.Globals.DragInput and YCGUI.Globals.Dragging then
        UpdateDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType.Name:match("Mouse") then
        YCGUI.Globals.Dragging = false
    end
end)

-- 屏幕尺寸自适应
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    YCGUI:RefreshDimensions()
end)

-- 设置窗口
function YCGUI:SetupSettings()
    local SettingsWindow = self:CreateWindow("UI设置", UDim2.new(0.5, -150, 0.5, -150), false, true)
    
    -- 主题设置
    local ThemeSection = SettingsWindow:CreateLabel("主题设置")
    
    local ThemeDropdown = SettingsWindow:CreateDropdown("选择主题", {"Default", "Ocean", "Rose"}, "Default", function(selected)
        self:SetTheme(selected)
        self:Notify("主题已切换: " .. selected, true)
    end)
    
    -- 界面设置
    local UISection = SettingsWindow:CreateLabel("界面设置")
    
    local UIScaleSlider = SettingsWindow:CreateSlider("界面缩放", 50, 150, math.floor(self.Config.UIScale * 100), function(value)
        self.Config.UIScale = value / 100
        self:RefreshDimensions()
        SaveConfig()
    end)
    
    local WindowWidthSlider = SettingsWindow:CreateSlider("窗口宽度", 150, 300, self.Config.WindowWidth, function(value)
        self.Config.WindowWidth = value
        self:RefreshDimensions()
        SaveConfig()
    end)
    
    local ItemHeightSlider = SettingsWindow:CreateSlider("项目高度", 24, 48, self.Config.ItemHeight, function(value)
        self.Config.ItemHeight = value
        self:RefreshDimensions()
        SaveConfig()
    end)
    
    -- 样式设置
    local StyleSection = SettingsWindow:CreateLabel("样式设置")
    
    local CornersToggle = SettingsWindow:CreateToggle("圆角风格", function(enabled)
        self.Config.UseCorners = enabled
        self:RefreshStyle()
        SaveConfig()
    end, self.Config.UseCorners)
    
    local StrokeToggle = SettingsWindow:CreateToggle("UI描边", function(enabled)
        self.Config.UseStroke = enabled
        self:RefreshStyle()
        SaveConfig()
    end, self.Config.UseStroke)
    
    -- 功能设置
    local FunctionSection = SettingsWindow:CreateLabel("功能设置")
    
    local HUDToggle = SettingsWindow:CreateToggle("显示HUD", function(enabled)
        self:SetHUDVisible(enabled)
    end, self.Config.ShowHUD)
    
    local NotifsToggle = SettingsWindow:CreateToggle("显示通知", function(enabled)
        self:SetNotifsVisible(enabled)
    end, self.Config.ShowNotifs)
    
    -- 操作按钮
    local SaveBtn = SettingsWindow:CreateButton("保存配置", function()
        SaveConfig()
        self:Notify("配置已保存", true)
    end)
    
    local ResetBtn = SettingsWindow:CreateButton("重置配置", function()
        for k, v in pairs(DefaultConfig) do
            self.Config[k] = v
        end
        self:RefreshTheme()
        self:RefreshStyle()
        self:RefreshDimensions()
        SaveConfig()
        self:Notify("配置已重置", true)
    end)
    
    return SettingsWindow
end

-- 移动端支持
function YCGUI:CreateMobileWidget(name, toggleFunc, getEnabledState)
    if ScreenGui:FindFirstChild("Float_" .. name) then return end
    
    local Widget = YCGUI:Create("TextButton", {
        Name = "Float_" .. name,
        Parent = ScreenGui,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.5, -25, 0.5, -25),
        BackgroundColor3 = Color3.fromRGB(25, 20, 35),
        BackgroundTransparency = 0.3,
        Text = GetFirstChar(name),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        ZIndex = 50
    })
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Widget
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 2
    Stroke.Parent = Widget
    
    local CloseBtn = YCGUI:Create("TextButton", {
        Parent = Widget,
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(1, -5, 0, -5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 80, 80),
        Font = Enum.Font.GothamBlack,
        TextSize = 12
    })
    
    CloseBtn.MouseButton1Click:Connect(function() Widget:Destroy() end)
    
    -- 拖拽功能
    local dragging, dragStart, startPos
    Widget.InputBegan:Connect(function(input)
        if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("MouseButton1") then
            dragging = true
            dragStart = input.Position
            startPos = Widget.Position
        end
    end)
    
    Widget.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("Mouse")) then
            local delta = input.Position - dragStart
            Widget.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    Widget.InputEnded:Connect(function(input)
        if input.UserInputType.Name:match("Touch") or input.UserInputType.Name:match("MouseButton1") then
            dragging = false
        end
    end)
    
    -- 状态指示
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not Widget.Parent then 
            connection:Disconnect() 
            return 
        end
        Stroke.Color = getEnabledState() and CurrentThemeData.Accent or Color3.fromRGB(60, 60, 60)
    end)
    
    Widget.MouseButton1Click:Connect(function() 
        toggleFunc(true) 
    end)
end

-- 初始化库
function YCGUI:Init()
    -- 加载动画
    task.spawn(function() 
        self:LoadLoader() 
    end)
    
    -- 创建灵动岛
    CreateDynamicIsland()
    
    -- 应用配置
    self:RefreshTheme()
    self:RefreshStyle()
    self:RefreshDimensions()
    
    -- 保存配置
    SaveConfig()
    
    -- 防AFK
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    
    return ScreenGui
end

-- 公共接口
function YCGUI:CreateMainControl(title)
    return self:CreateWindow(title, UDim2.new(0, 20, 0, 60), true, false)
end

function YCGUI:CreateChildWindow(title)
    return self:CreateWindow(title, UDim2.new(0.5, -self.Config.WindowWidth/2, 0.5, -100), false, true)
end

function YCGUI:BindWindow(parentWindow, childWindowName, defaultState)
    local Mod = parentWindow:CreateToggle(childWindowName, function(bool)
        local target = self.Globals.SubWindows[childWindowName]
        if target then
            target.IsOpen = bool
            target.Main.Visible = bool and self.Config.UIVisible
            if bool and self.Config.UIVisible then
                if target.Main.Position.X.Offset == 0 and target.Main.Position.Y.Offset == 0 then
                    target.Main.Position = UDim2.new(0.5, -self.Config.WindowWidth/2, 0.5, -100)
                end
                TweenService:Create(target.Main, TweenInfo.new(0.3), {
                    BackgroundTransparency = CurrentThemeData.MainTrans
                }):Play()
            else
                target.Main.Visible = false
            end
        else
            self:Notify("未找到窗口: " .. childWindowName, false)
        end
    end, false)
    
    if defaultState then Mod:Set(true) end
    return Mod
end

-- 返回库对象
return YCGUI

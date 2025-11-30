-- YC GUI - 无动画纯净版
local Library = {}; local ConfigName = "YCUI/settings_adaptive.json"

local HttpService = game:GetService("HttpService")
local CoreGui        = game:GetService("CoreGui")
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer

-- 默认配置
local DefaultConfig = {
    ShowHUD = true, ShowNotifs = true, NotifDuration = 3,
    UIScale = 1, WindowWidth = 180, WindowMaxHeight = 350,
    ItemHeight = 32, Theme = "Default", UIVisible = true,
    UseCorners = false, UseStroke = false
}
Library.Config = HttpService:JSONDecode(HttpService:JSONEncode(DefaultConfig))

-- 全局表
Library.Globals = {
    Windows = {}, Elements = {}, ThemeObjects = {}, StyleObjects = {},
    ActiveNotifs = {}, BoundKeys = {}, SubWindows = {}, TopZIndex = 100
}

-- 主题
Library.Themes = {
    ["Default"] = {
        Name = "紫罗兰", Main = Color3.fromRGB(20,20,25), MainTrans = 0.1,
        Text = Color3.white, TextDark = Color3.fromRGB(160,160,170),
        SettingBg = Color3.fromRGB(25,25,30), Accent = Color3.fromRGB(100,20,220),
        Scroll = Color3.fromRGB(80,60,100)
    }
}
local CurrentThemeData = Library.Themes["Default"]

-- 文件存取
local function CheckFolder() if not isfolder("YCUI") then makefolder("YCUI") end end
local function SaveConfig() CheckFolder(); pcall(function() writefile(ConfigName, HttpService:JSONEncode(Library.Config)) end) end
local function LoadConfig()
    CheckFolder()
    if isfile(ConfigName) then
        local ok, dat = pcall(function() return HttpService:JSONDecode(readfile(ConfigName)) end)
        if ok and dat then
            for k,v in pairs(dat) do Library.Config[k] = v end
            CurrentThemeData = Library.Themes[Library.Config.Theme] or Library.Themes["Default"]
        end
    end
end
LoadConfig()

-- 创建最外层 ScreenGui
if CoreGui:FindFirstChild("YC_GUI_Adaptive") then CoreGui.YC_GUI_Adaptive:Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YC_GUI_Adaptive"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 主题与样式注册（无动画）
local function RegisterObject(obj, typ)
    local t = CurrentThemeData
    if typ == "Window"   then obj.BackgroundColor3 = t.Main; obj.BackgroundTransparency = t.MainTrans
    elseif typ == "Text"    then obj.TextColor3 = t.Text
    elseif typ == "TextDark" then obj.TextColor3 = t.TextDark
    elseif typ == "SettingBg" then obj.BackgroundColor3 = t.SettingBg
    elseif typ == "Accent"  then obj.BackgroundColor3 = t.Accent
    elseif typ == "Scroll"  then obj.ScrollBarImageColor3 = t.Scroll
    end
end
local function RegisterStyle(obj, hasStroke, radius)
    table.insert(Library.Globals.StyleObjects, {Object = obj, HasStroke = hasStroke, Radius = radius})
    local c = obj:FindFirstChild("UICorner") or Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, Library.Config.UseCorners and radius or 0); c.Parent = obj
    if hasStroke then
        local s = obj:FindFirstChild("UIStroke") or Instance.new("UIStroke")
        s.Thickness = 1.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Color = CurrentThemeData.Accent; s.Transparency = Library.Config.UseStroke and 0 or 1; s.Parent = obj
    end
end

-- 窗口创建
function Library:CreateWindow(title, pos, isMain, isSub)
    local Window = {}; local isFolded = false; local isOpen = not isSub
    local HeaderH = Library.Config.ItemHeight + 6

    local Main = Instance.new("Frame")
    Main.Name = "Window_"..title; Main.Parent = ScreenGui; Main.Position = pos
    Main.Size = UDim2.new(0, Library.Config.WindowWidth, 0, HeaderH)
    Main.BorderSizePixel = 0; Main.Visible = isOpen and Library.Config.UIVisible; Main.ZIndex = 10
    RegisterObject(Main, "Window"); RegisterStyle(Main, true, 10)

    local Scale = Instance.new("UIScale"); Scale.Scale = Library.Config.UIScale; Scale.Parent = Main
    local Header = Instance.new("Frame"); Header.Parent = Main; Header.BackgroundTransparency = 1
    Header.Size = UDim2.new(1, 0, 0, HeaderH)

    local Title = Instance.new("TextLabel"); Title.Parent = Header; Title.Text = title
    Title.Font = Enum.Font.GothamBlack; Title.TextSize = math.clamp(HeaderH*0.45, 12, 24)
    Title.Size = UDim2.new(1, -10, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1
    RegisterObject(Title, "Text")

    local Container = Instance.new("ScrollingFrame"); Container.Name = "Container"
    Container.Parent = Main; Container.BackgroundTransparency = 1; Container.BorderSizePixel = 0
    Container.Position = UDim2.new(0, 0, 0, HeaderH); Container.Size = UDim2.new(1, 0, 0, 0)
    Container.ScrollBarThickness = 3; Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RegisterObject(Container, "Scroll")

    local List = Instance.new("UIListLayout"); List.Parent = Container; List.SortOrder = Enum.SortOrder.LayoutOrder; List.Padding = UDim.new(0, 0)
    local winData = {Main = Main, Header = Header, Title = Title, Container = Container, List = List, IsOpen = isOpen, IsSub = isSub}
    table.insert(Library.Globals.Windows, winData); if isSub then Library.Globals.SubWindows[title] = winData end

    -- 自适应高度
    local function RefreshH()
        local contentH = List.AbsoluteContentSize.Y
        local screenH = workspace.CurrentCamera.ViewportSize.Y / (Library.Config.UIScale > 0 and Library.Config.UIScale or 1)
        local maxAllowed = math.max(screenH - 100, 100)
        local finalH = math.min(contentH, Library.Config.WindowMaxHeight, maxAllowed)
        if isFolded then
            Main.Size = UDim2.new(0, Library.Config.WindowWidth, 0, HeaderH)
            Container.Visible = false
        else
            Main.Size = UDim2.new(0, Library.Config.WindowWidth, 0, HeaderH + finalH)
            Container.Size = UDim2.new(1, 0, 0, finalH); Container.Visible = true
            Container.ScrollingEnabled = contentH > finalH
        end
    end
    winData.RefreshHeight = RefreshH
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshH)

    -- 折叠
    Header.InputBegan:Connect(function(i)
        if i.UserInputType.Name:match("Mouse") or i.UserInputType.Name:match("Touch") then
            Library.Globals.TopZIndex = Library.Globals.TopZIndex + 1; Main.ZIndex = Library.Globals.TopZIndex
        end
    end)
    Header.MouseButton1Click:Connect(function()
        isFolded = not isFolded; RefreshH()
    end)

    -- 控件函数
    function Window:CreateButton(name, callback)
        local H = Library.Config.ItemHeight
        local Btn = Instance.new("TextButton"); Btn.Parent = Container; Btn.BackgroundTransparency = 1
        Btn.Size = UDim2.new(1, 0, 0, H); Btn.Text = ""; Btn.BorderSizePixel = 0
        RegisterStyle(Btn, false, 6)
        local Txt = Instance.new("TextLabel"); Txt.Parent = Btn; Txt.Text = name
        Txt.Font = Enum.Font.GothamSemibold; Txt.TextSize = math.clamp(H*0.42, 10, 20)
        Txt.BackgroundTransparency = 1; Txt.Size = UDim2.new(1, -10, 1, 0); Txt.Position = UDim2.new(0, 10, 0, 0)
        Txt.TextXAlignment = Enum.TextXAlignment.Left; RegisterObject(Txt, "TextDark")
        Btn.MouseButton1Click:Connect(function() pcall(callback) end)
    end

    function Window:CreateModule(name, callback, allowBind)
        if allowBind == nil then allowBind = true end
        local Mod = {}; local enabled = false; local bindKey = nil
        local H = Library.Config.ItemHeight
        local Btn = Instance.new("TextButton"); Btn.Parent = Container; Btn.BackgroundTransparency = 1
        Btn.Size = UDim2.new(1, 0, 0, H); Btn.Text = ""; Btn.BorderSizePixel = 0
        RegisterStyle(Btn, false, 6)
        local Txt = Instance.new("TextLabel"); Txt.Parent = Btn; Txt.Text = name
        Txt.Font = Enum.Font.GothamSemibold; Txt.TextSize = math.clamp(H*0.42, 10, 20)
        Txt.BackgroundTransparency = 1; Txt.Size = UDim2.new(1, -35, 1, 0); Txt.Position = UDim2.new(0, 10, 0, 0)
        Txt.TextXAlignment = Enum.TextXAlignment.Left; RegisterObject(Txt, "TextDark")
        local Dots = Instance.new("TextButton"); Dots.Parent = Btn; Dots.Text = "..."
        Dots.Font = Enum.Font.GothamBold; Dots.TextSize = math.clamp(H*0.42, 10, 20) + 4
        Dots.BackgroundTransparency = 1; Dots.Size = UDim2.new(0, H, 1, 0); Dots.Position = UDim2.new(1, -H, 0, 0); Dots.Visible = allowBind
        RegisterObject(Dots, "TextDark")

        local function Toggle()
            enabled = not enabled
            if enabled then RegisterObject(Txt, "Text"); Btn.BackgroundTransparency = 0.8; Btn.BackgroundColor3 = Color3.new(1,1,1)
            else RegisterObject(Txt, "TextDark"); Btn.BackgroundTransparency = 1 end
            pcall(callback, enabled)
        end
        function Mod:Set(bool) if bool ~= enabled then Toggle() end end
        Btn.MouseButton1Click:Connect(Toggle)

        -- 设置面板（无动画）
        local SetFrame = Instance.new("Frame"); SetFrame.Parent = Container; SetFrame.BackgroundTransparency = 0.5
        RegisterObject(SetFrame, "SettingBg"); SetFrame.Size = UDim2.new(1, 0, 0, 0); SetFrame.Visible = false; SetFrame.BorderSizePixel = 0; SetFrame.ClipsDescendants = true
        local SetList = Instance.new("UIListLayout"); SetList.Parent = SetFrame; SetList.Padding = UDim.new(0, 0)
        Dots.MouseButton1Click:Connect(function()
            SetFrame.Visible = not SetFrame.Visible
            SetFrame.Size = UDim.new(1, 0, 0, SetFrame.Visible and SetList.AbsoluteContentSize.Y or 0)
            RefreshH()
        end)

        -- 开关
        function Mod:CreateSwitch(txt, call, default)
            local on = default or false
            local B = Instance.new("TextButton"); B.Parent = SetFrame; B.BackgroundTransparency = 1; B.Size = UDim2.new(1, 0, 0, 24); B.Text = ""; B.BorderSizePixel = 0
            local L = Instance.new("TextLabel"); L.Parent = B; L.Text = txt; L.Font = Enum.Font.Gotham; L.TextSize = 11; L.BackgroundTransparency = 1; L.Size = UDim2.new(1, -30, 1, 0); L.Position = UDim2.new(0, 10, 0, 0); L.TextXAlignment = Enum.TextXAlignment.Left; RegisterObject(L, "TextDark")
            local Box = Instance.new("Frame"); Box.Parent = B; Box.Size = UDim2.new(0, 12, 0, 12); Box.Position = UDim2.new(1, -20, 0.5, -6); Box.BackgroundColor3 = Color3.fromRGB(60, 60, 60); Box.BorderSizePixel = 0
            local Ind = Instance.new("Frame"); Ind.Parent = Box; Ind.Size = UDim2.new(1, -2, 1, -2); Ind.Position = UDim2.new(0, 1, 0, 1); Ind.Visible = on; Ind.BorderSizePixel = 0; RegisterObject(Ind, "Accent")
            B.MouseButton1Click:Connect(function() on = not on; Ind.Visible = on; pcall(call, on) end)
            if on then pcall(call, on) end
        end

        -- 下拉
        function Mod:CreateDropdown(txt, opts, call)
            local open = false; local H = 26
            local Base = Instance.new("Frame"); Base.Parent = SetFrame; Base.BackgroundTransparency = 1; Base.Size = UDim2.new(1, 0, 0, H); Base.ClipsDescendants = true; Base.BorderSizePixel = 0
            local Main = Instance.new("TextButton"); Main.Parent = Base; Main.BackgroundTransparency = 1; Main.Size = UDim2.new(1, 0, 0, H); Main.Text = ""; Main.AutoButtonColor = false; Main.BorderSizePixel = 0
            local L = Instance.new("TextLabel"); L.Parent = Main; L.Text = txt .. " >"; L.Font = Enum.Font.Gotham; L.TextSize = 11; L.BackgroundTransparency = 1; L.Size = UDim2.new(1, -20, 1, 0); L.Position = UDim2.new(0, 10, 0, 0); L.TextXAlignment = Enum.TextXAlignment.Left; RegisterObject(L, "TextDark")
            local Opts = Instance.new("Frame"); Opts.Parent = Base; Opts.Position = UDim2.new(0, 0, 0, H); Opts.Size = UDim2.new(1, 0, 0, 0); Opts.BackgroundTransparency = 1; Opts.BorderSizePixel = 0
            local OList = Instance.new("UIListLayout"); OList.Parent = Opts; OList.Padding = UDim.new(0, 0)
            for _, o in ipairs(opts) do
                local Ob = Instance.new("TextButton"); Ob.Parent = Opts; Ob.Size = UDim2.new(1, 0, 0, 22); Ob.BackgroundTransparency = 1; Ob.BorderSizePixel = 0; Ob.Text = o; Ob.Font = Enum.Font.Gotham; Ob.TextSize = 11; Ob.TextColor3 = Color3.fromRGB(200, 200, 200)
                Ob.MouseButton1Click:Connect(function() L.Text = txt .. ": " .. o; open = false; Base.Size = UDim2.new(1, 0, 0, H); RefreshH(); pcall(call, o) end)
            end
            Main.MouseButton1Click:Connect(function() open = not open; Base.Size = UDim2.new(1, 0, 0, open and (H + #opts * 22) or H); RefreshH() end)
        end

        -- 滑条
        function Mod:CreateSlider(txt, min, max, def, call)
            local v = def
            local F = Instance.new("Frame"); F.Parent = SetFrame; F.BackgroundTransparency = 1; F.Size = UDim2.new(1, 0, 0, 30); F.BorderSizePixel = 0
            local L = Instance.new("TextLabel"); L.Parent = F; L.Text = txt .. ": " .. v; L.Font = Enum.Font.Gotham; L.TextSize = 11; L.BackgroundTransparency = 1; L.Size = UDim2.new(1, 0, 0, 14); RegisterObject(L, "TextDark")
            local B = Instance.new("Frame"); B.Parent = F; B.BackgroundColor3 = Color3.fromRGB(60, 60, 60); B.BorderSizePixel = 0; B.Position = UDim2.new(0, 8, 0, 18); B.Size = UDim2.new(1, -16, 0, 4)
            local Fil = Instance.new("Frame"); Fil.Parent = B; Fil.BorderSizePixel = 0; Fil.Size = UDim2.new((def - min) / (max - min), 0, 1, 0); RegisterObject(Fil, "Accent")
            local T = Instance.new("TextButton"); T.Parent = F; T.BackgroundTransparency = 1; T.Text = ""; T.Size = UDim2.new(1, 0, 0, 25); T.Position = UDim2.new(0, 0, 0, 5); T.ZIndex = 10
            local d = false
            T.InputBegan:Connect(function(i) if i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("Mouse") then d = true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("Mouse") then d = false end end)
            UserInputService.InputChanged:Connect(function(i)
                if d and (i.UserInputType.Name:match("Touch") or i.UserInputType.Name:match("Mouse")) then
                    local p = math.clamp((i.Position.X - B.AbsolutePosition.X) / B.AbsoluteSize.X, 0, 1)
                    v = math.floor(min + (max - min) * p)
                    L.Text = txt .. ": " .. v; Fil.Size = UDim2.new(p, 0, 1, 0); pcall(call, v)
                end
            end)
            pcall(call, v)
        end

        return Mod
    end

    return Window
end

-- 对外接口
function Library:CreateMainControl(title) return self:CreateWindow(title, UDim2.new(0, 20, 0, 60), true, false) end
function Library:CreateChildWindow(title) return self:CreateWindow(title, UDim2.new(0.5, -Library.Config.WindowWidth / 2, 0.5, -100), false, true) end
function Library:SetTheme(name) if Library.Themes[name] then CurrentThemeData = Library.Themes[name]; Library.Config.Theme = name; SaveConfig() end end
function Library:SetHUDVisible(v) Library.Config.ShowHUD = v; SaveConfig() end
function Library:SetNotifsVisible(v) Library.Config.ShowNotifs = v; SaveConfig() end

-- 可选设置页
function Library:SetupSettings()
    local Sets = Library:CreateWindow("UI设置", UDim2.new(0.5, -100, 0.5, -100))
    local UIConf = Sets:CreateModule("界面配置", function() end, false)
    UIConf:CreateDropdown("主题选择", {"Default"}, function(v) Library:SetTheme(v) end)
    UIConf:CreateSlider("整体缩放(%)", 50, 150, Library.Config.UIScale * 100, function(v) Library.Config.UIScale = v / 100; Library:RefreshDimensions() end)
    UIConf:CreateSlider("窗口宽度", 100, 300, Library.Config.WindowWidth, function(v) Library.Config.WindowWidth = v; Library:RefreshDimensions() end)
    local StyleConf = Sets:CreateModule("样式设置", function() end, false)
    StyleConf:CreateSwitch("圆角风格", function(v) Library.Config.UseCorners = v; Library:RefreshStyle(); SaveConfig() end, Library.Config.UseCorners)
    StyleConf:CreateSwitch("UI描边", function(v) Library.Config.UseStroke = v; Library:RefreshStyle(); SaveConfig() end, Library.Config.UseStroke)
    local FuncConf = Sets:CreateModule("功能开关", function() end, false)
    FuncConf:CreateSwitch("显示HUD", function(v) Library:SetHUDVisible(v) end, Library.Config.ShowHUD)
    FuncConf:CreateSwitch("显示通知", function(v) Library:SetNotifsVisible(v) end, Library.Config.ShowNotifs)
    Sets:CreateButton("保存当前配置", function() SaveConfig() end)
    return Sets
end

-- 初始化
ScreenGui.Enabled = true
return Library

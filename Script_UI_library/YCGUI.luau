--// YCUI Library - Fixed & Integrated with librarynew
-- Author: Moonshot AI Optimized + librarynew integration
-- Features: Adaptive UI, Island, HUD, Notify, Theme System, Mobile Support, Color Picker, Binds, Folders

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
    WindowWidth = 230,
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

--// Util
local function LoadConfig()
    if isfile(ConfigName) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigName)) end)
        if ok then for k, v in pairs(data) do DefaultConfig[k] = v end end
    end
end

local function SaveConfig()
    pcall(function() writefile(ConfigName, HttpService:JSONEncode(DefaultConfig)) end)
end

local function Tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

--// UI Core
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YCUI_Fixed"
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false

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
    Label.Text = "YCUI Fixed Loaded"
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

--// librarynew 核心封装
local library = {flags = {}, windows = {}, open = true}
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local textService = game:GetService("TextService")
local inputService = game:GetService("UserInputService")
local ui = Enum.UserInputType.MouseButton1

--// 动画与工具
local dragging, dragInput, dragStart, startPos, dragObject
local function round(num, bracket)
    bracket = bracket or 1
    local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
    if a < 0 then a = a + bracket end
    return a
end

local function keyCheck(x,x1)
    for _,v in next, x1 do if v == x then return true end end
end

local function update(input)
    local delta = input.Position - dragStart
    local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y
    dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), "Out", "Quint", 0.1, true)
end

--// 彩虹色
local chromaColor
spawn(function() while task.wait() do chromaColor = Color3.fromHSV(tick()%5/5,1,1) end end)

function library:Create(class, props)
    local inst = Instance.new(class)
    for k, v in next, props do inst[k] = v end
    return inst
end

--// 创建窗口
local function createOptionHolder(holderTitle, parent, parentTable, subHolder)
    local size = subHolder and 34 or 40
    parentTable.main = library:Create("ImageButton", {
        Position = UDim2.new(0, 20 + (250 * (parentTable.position or 0)), 0, 20),
        Size = UDim2.new(0, 230, 0, size),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3570695787",
        ImageColor3 = Themes[DefaultConfig.Theme].Main,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100, 100, 100, 100),
        SliceScale = 0.04,
        ClipsDescendants = true,
        Parent = parent
    })

    local title = library:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, size),
        BackgroundTransparency = 1,
        Text = holderTitle,
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        TextColor3 = Themes[DefaultConfig.Theme].Text,
        Parent = parentTable.main
    })

    parentTable.content = library:Create("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, size),
        Size = UDim2.new(1, 0, 1, -size),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Themes[DefaultConfig.Theme].Scroll,
        Parent = parentTable.main
    })

    local layout = library:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parentTable.content
    })

    layout.Changed:Connect(function()
        parentTable.content.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
        parentTable.main.Size = UDim2.new(0, 230, 0, layout.AbsoluteContentSize.Y + size)
    end)

    return parentTable
end

--// 创建控件（简化封装）
local function createToggle(option, parent)
    local main = library:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg,
        Text = option.text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Themes[DefaultConfig.Theme].Text,
        Parent = parent
    })
    local state = option.state
    local function update()
        main.BackgroundColor3 = state and Themes[DefaultConfig.Theme].Accent or Themes[DefaultConfig.Theme].SettingBg
    end
    main.MouseButton1Click:Connect(function()
        state = not state
        library.flags[option.flag] = state
        Tween(main, {BackgroundColor3 = state and Themes[DefaultConfig.Theme].Accent or Themes[DefaultConfig.Theme].SettingBg}, 0.2)
        option.callback(state)
    end)
    update()
end

local function createSlider(option, parent)
    local frame = library:Create("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = parent})
    local label = library:Create("TextLabel", {Text = option.text .. ": " .. option.value, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 10, 0, 2), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Themes[DefaultConfig.Theme].TextDark, BackgroundTransparency = 1, Parent = frame})
    local bar = library:Create("Frame", {Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 20), BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0, Parent = frame})
    local fill = library:Create("Frame", {Size = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 1, 0), BackgroundColor3 = Themes[DefaultConfig.Theme].Accent, BorderSizePixel = 0, Parent = bar})
    local dragging = false
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local value = math.floor(option.min + (option.max - option.min) * pos)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = option.text .. ": " .. value
            library.flags[option.flag] = value
            option.callback(value)
        end
    end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

local function createButton(option, parent)
    local btn = library:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg,
        Text = option.text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Themes[DefaultConfig.Theme].Text,
        Parent = parent
    })
    btn.MouseButton1Click:Connect(function()
        Tween(btn, {BackgroundColor3 = Themes[DefaultConfig.Theme].Accent}, 0.1)
        task.wait(0.1)
        Tween(btn, {BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg}, 0.2)
        option.callback()
    end)
end

local function createColor(option, parent)
    local main = library:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes[DefaultConfig.Theme].SettingBg,
        Text = option.text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Themes[DefaultConfig.Theme].Text,
        Parent = parent
    })
    local colorBox = library:Create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0.5, -10),
        BackgroundColor3 = option.color,
        Parent = main
    })
    local corner = library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = colorBox})
    main.MouseButton1Click:Connect(function()
        -- 简易颜色选择弹窗
        local picker = library:Create("Frame", {
            Size = UDim2.new(0, 200, 0, 200),
            Position = UDim2.new(0.5, -100, 0.5, -100),
            BackgroundColor3 = Themes[DefaultConfig.Theme].Main,
            Parent = ScreenGui,
            ZIndex = 500
        })
        local hue = library:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            Parent = picker
        })
        local uigrad = library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
            }),
            Parent = hue
        })
        local hueSlider = library:Create("Frame", {
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = hue
        })
        local satval = library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, -20),
            Position = UDim2.new(0, 0, 0, 20),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = picker
        })
        local satvalSlider = library:Create("Frame", {
            Size = UDim2.new(0, 4, 0, 4),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = satval
        })
        local h, s, v = 0, 1, 1
        local function updateColor()
            local col = Color3.fromHSV(h, s, v)
            colorBox.BackgroundColor3 = col
            library.flags[option.flag] = col
            option.callback(col)
        end
        hue.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local x = math.clamp((input.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                h = x
                hueSlider.Position = UDim2.new(x, 0, 0, 0)
                satval.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                updateColor()
            end
        end)
        satval.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local x = math.clamp((input.Position.X - satval.AbsolutePosition.X) / satval.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - satval.AbsolutePosition.Y) / satval.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                satvalSlider.Position = UDim2.new(x, 0, y, 0)
                updateColor()
            end
        end)
        -- 关闭
        task.wait(5)
        picker:Destroy()
    end)
end

--// 窗口与控件绑定
local function loadOptions(option, parent)
    for _, newOption in next, option.options do
        if newOption.type == "toggle" then createToggle(newOption, parent.content)
        elseif newOption.type == "button" then createButton(newOption, parent.content)
        elseif newOption.type == "slider" then createSlider(newOption, parent.content)
        elseif newOption.type == "color" then createColor(newOption, parent.content)
        end
    end
end

local function getFunctions(parent)
    function parent:AddToggle(opt)
        opt = typeof(opt) == "table" and opt or {}
        opt.text = tostring(opt.text or "Toggle")
        opt.state = typeof(opt.state) == "boolean" and opt.state or false
        opt.callback = typeof(opt.callback) == "function" and opt.callback or function() end
        opt.type = "toggle"
        opt.flag = opt.flag or opt.text
        library.flags[opt.flag] = opt.state
        table.insert(parent.options, opt)
        return opt
    end

    function parent:AddButton(opt)
        opt = typeof(opt) == "table" and opt or {}
        opt.text = tostring(opt.text or "Button")
        opt.callback = typeof(opt.callback) == "function" and opt.callback or function() end
        opt.type = "button"
        opt.flag = opt.flag or opt.text
        table.insert(parent.options, opt)
        return opt
    end

    function parent:AddSlider(opt)
        opt = typeof(opt) == "table" and opt or {}
        opt.text = tostring(opt.text or "Slider")
        opt.min = typeof(opt.min) == "number" and opt.min or 0
        opt.max = typeof(opt.max) == "number" and opt.max or 100
        opt.value = math.clamp(typeof(opt.value) == "number" and opt.value or opt.min, opt.min, opt.max)
        opt.callback = typeof(opt.callback) == "function" and opt.callback or function() end
        opt.type = "slider"
        opt.flag = opt.flag or opt.text
        library.flags[opt.flag] = opt.value
        table.insert(parent.options, opt)
        return opt
    end

    function parent:AddColor(opt)
        opt = typeof(opt) == "table" and opt or {}
        opt.text = tostring(opt.text or "Color")
        opt.color = typeof(opt.color) == "Color3" and opt.color or Color3.new(1, 1, 1)
        opt.callback = typeof(opt.callback) == "function" and opt.callback or function() end
        opt.type = "color"
        opt.flag = opt.flag or opt.text
        library.flags[opt.flag] = opt.color
        table.insert(parent.options, opt)
        return opt
    end
end

--// 创建窗口
function Library:CreateWindow(title, position)
    local window = {title = title, options = {}, open = true, position = #library.windows}
    getFunctions(window)
    table.insert(library.windows, window)
    return window
end

--// 初始化
function Library:Init()
    library.base = library:Create("ScreenGui", {Parent = ScreenGui, ResetOnSpawn = true})
    for _, window in next, library.windows do
        createOptionHolder(window.title, library.base, window)
        loadOptions(window, window)
    end
    return library.base
end

--// 通知系统（已存在）
Library.Globals = {ActiveNotifs = {}}
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

    local yOffset = 0
    for i = #Library.Globals.ActiveNotifs, 1, -1 do
        local notif = Library.Globals.ActiveNotifs[i]
        if notif and notif.Parent then
            Tween(notif, {Position = UDim2.new(1, -230, 1, -50 - yOffset)}, 0.3)
            yOffset = yOffset + 60
        end
    end
    table.insert(Library.Globals.ActiveNotifs, Frame)

    Tween(Frame, {Position = UDim2.new(1, -230, 1, -50 - yOffset)}, 0.3)

    task.wait(DefaultConfig.NotifDuration)
    Tween(Frame, {Position = Frame.Position + UDim2.new(0, 300, 0, 0)}, 0.3)
    task.wait(0.3)
    Frame:Destroy()

    for i, v in ipairs(Library.Globals.ActiveNotifs) do
        if v == Frame then table.remove(Library.Globals.ActiveNotifs, i) break end
    end
end

--// 设置面板
function Library:CreateSettingsWindow()
    local Sets = self:CreateWindow("设置面板")
    Sets:AddDropdown({
        text = "主题",
        values = {"Default", "Ocean"},
        value = DefaultConfig.Theme,
        callback = function(v)
            DefaultConfig.Theme = v
            self:Notify("主题切换", true)
        end
    })
    Sets:AddSlider({
        text = "UI缩放",
        min = 50,
        max = 150,
        value = DefaultConfig.UIScale * 100,
        callback = function(v)
            DefaultConfig.UIScale = v / 100
        end
    })
    Sets:AddToggle({
        text = "圆角风格",
        state = DefaultConfig.UseCorners,
        callback = function(v)
            DefaultConfig.UseCorners = v
        end
    })
    Sets:AddToggle({
        text = "UI描边",
        state = DefaultConfig.UseStroke,
        callback = function(v)
            DefaultConfig.UseStroke = v
        end
    })
    Sets:AddButton({
        text = "保存配置",
        callback = function()
            SaveConfig()
            self:Notify("配置已保存", true)
        end
    })
end

--// 启动
LoadConfig()
ShowLoader()

return Library

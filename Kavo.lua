local Kavo = {}

local tween = game:GetService("TweenService")
local input = game:GetService("UserInputService")
local run = game:GetService("RunService")

-- 拖拽功能
function Kavo:DraggingEnabled(frame, parent)
    parent = parent or frame
    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = parent.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    input.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            parent.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

-- 创建主库
function Kavo.CreateLib(title)
    title = title or "Library"

    -- 清理旧窗口
    for _, v in ipairs(game.CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == title then
            v:Destroy()
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 400, 0, 300)
    Main.Position = UDim2.new(0.3, 0, 0.3, 0)
    Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Header.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0.5, 0, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Text = title
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.Gotham
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local Close = Instance.new("TextButton")
    Close.Name = "Close"
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Position = UDim2.new(1, -30, 0, 0)
    Close.Text = "X"
    Close.TextColor3 = Color3.new(1, 1, 1)
    Close.BackgroundTransparency = 1
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 16
    Close.Parent = Header
    Close.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local TabHolder = Instance.new("Frame")
    TabHolder.Name = "TabHolder"
    TabHolder.Size = UDim2.new(0.3, 0, 1, -30)
    TabHolder.Position = UDim2.new(0, 0, 0, 30)
    TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TabHolder.Parent = Main

    local TabList = Instance.new("UIListLayout")
    TabList.Parent = TabHolder
    TabList.Padding = UDim.new(0, 5)

    local PageHolder = Instance.new("Frame")
    PageHolder.Name = "PageHolder"
    PageHolder.Size = UDim2.new(0.7, 0, 1, -30)
    PageHolder.Position = UDim2.new(0.3, 0, 0, 30)
    PageHolder.BackgroundTransparency = 1
    PageHolder.Parent = Main

    Kavo:DraggingEnabled(Header, Main)

    local Tabs = {}
    function Tabs:NewTab(name)
        name = name or "Tab"

        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.Position = UDim2.new(0, 5, 0, 0)
        TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TabButton.Text = name
        TabButton.TextColor3 = Color3.new(1, 1, 1)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 14
        TabButton.Parent = TabHolder

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Size = UDim2.new(1, -10, 1, -10)
        Page.Position = UDim2.new(0, 5, 0, 5)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 5
        Page.Visible = false
        Page.Parent = PageHolder

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 5)
        Layout.Parent = Page

        TabButton.MouseButton1Click:Connect(function()
            for _, v in ipairs(PageHolder:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            Page.Visible = true
        end)

        local Sections = {}
        function Sections:NewSection(name)
            name = name or "Section"

            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, 0, 0, 40)
            SectionFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            SectionFrame.Parent = Page

            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Size = UDim2.new(1, -10, 1, 0)
            SectionTitle.Position = UDim2.new(0, 10, 0, 0)
            SectionTitle.Text = name
            SectionTitle.TextColor3 = Color3.new(1, 1, 1)
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Font = Enum.Font.Gotham
            SectionTitle.TextSize = 14
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            SectionTitle.Parent = SectionFrame

            local Elements = {}

            function Elements:NewButton(text, callback)
                callback = callback or function() end
                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, -10, 0, 30)
                Btn.Position = UDim2.new(0, 5, 0, 0)
                Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Btn.Text = text
                Btn.TextColor3 = Color3.new(1, 1, 1)
                Btn.Font = Enum.Font.Gotham
                Btn.TextSize = 14
                Btn.Parent = Page
                Btn.MouseButton1Click:Connect(callback)
            end

            -- 其他控件（Toggle、Slider、TextBox、Dropdown、Keybind、Label）可仿照按钮添加
            return Elements
        end
        return Sections
    end

    return Tabs
end

return Kavo

-- MCTechGUILib.lua - MC科技风格UI库
-- 版本: 4.0
-- 提供科技感十足的Roblox UI组件

local MCTechGUILib = {}

-- 私有属性
local Private = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    Player = nil,
    PlayerGui = nil,
    ScreenGui = nil,
    SubMenus = {},
    SubMenuStates = {},
    DetailWindows = {},
    DetailStates = {},
    NotificationQueue = {},
    ActiveNotifications = {},
    ActiveFeatures = {},
    FeatureStatusContainer = nil,
    ShowFeatureStatus = true,
    ExcludedMenus = {
        ["设置"] = true,
        ["显示功能状态"] = true
    }
}

--[[
    初始化库
    @return MCTechGUILib - 库实例
]]
function MCTechGUILib.Init()
    Private.Player = Private.Players.LocalPlayer
    Private.PlayerGui = Private.Player:WaitForChild("PlayerGui")
    
    -- 创建主ScreenGui
    if not Private.ScreenGui then
        Private.ScreenGui = Instance.new("ScreenGui")
        Private.ScreenGui.Name = "MCTechGUI"
        Private.ScreenGui.ResetOnSpawn = false
        Private.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Private.ScreenGui.Parent = Private.PlayerGui
    end
    
    return MCTechGUILib
end

--[[
    创建粉蓝渐变色配置
    @param frame Frame - 要应用渐变效果的框架
    @return UIGradient - 渐变对象
]]
function MCTechGUILib.CreatePinkBlueGradientEffect(frame)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 105, 180)), -- 粉色
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 182, 193)), -- 浅粉色
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(173, 216, 230)), -- 浅蓝色
        ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 206, 250)) -- 天蓝色
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- 创建缓慢旋转动画
    local rotationTween = Private.TweenService:Create(
        gradient,
        TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 405} -- 360度 + 45度初始角度
    )
    rotationTween:Play()
    
    return gradient
end

--[[
    创建粉蓝渐变边框效果
    @param stroke UIStroke - 要应用效果的边框
    @return Connection - 渐变效果连接
]]
function MCTechGUILib.CreatePinkBlueStrokeEffect(stroke)
    local gradientSpeed = 0.5
    local time = 0
    
    local connection
    connection = Private.RunService.Heartbeat:Connect(function(dt)
        if not stroke.Parent then
            connection:Disconnect()
            return
        end
        
        time = time + dt * gradientSpeed
        
        -- 在粉色和蓝色之间插值
        local t = (math.sin(time) + 1) / 2 -- 将sin值从[-1,1]映射到[0,1]
        local pink = Color3.fromRGB(255, 105, 180)
        local blue = Color3.fromRGB(135, 206, 250)
        
        local r = pink.R + (blue.R - pink.R) * t
        local g = pink.G + (blue.G - pink.G) * t
        local b = pink.B + (blue.B - pink.B) * t
        
        stroke.Color = Color3.new(r, g, b)
        
        -- 透明度呼吸效果
        stroke.Transparency = 0.2 + 0.3 * math.abs(math.sin(time * 1.5))
    end)
    
    return connection
end

--[[
    创建功能状态显示容器
    @return Frame - 功能状态容器
]]
function MCTechGUILib.CreateFeatureStatusContainer()
    Private.FeatureStatusContainer = Instance.new("Frame")
    Private.FeatureStatusContainer.Name = "FeatureStatusContainer"
    Private.FeatureStatusContainer.Size = UDim2.new(0, 200, 0, 0)
    Private.FeatureStatusContainer.Position = UDim2.new(1, -220, 0, 20) -- 确保在右上角
    Private.FeatureStatusContainer.BackgroundTransparency = 1
    Private.FeatureStatusContainer.BorderSizePixel = 0
    Private.FeatureStatusContainer.ClipsDescendants = false
    Private.FeatureStatusContainer.Visible = Private.ShowFeatureStatus
    Private.FeatureStatusContainer.Parent = Private.ScreenGui
    
    -- 添加自动布局
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right -- 右对齐
    listLayout.Parent = Private.FeatureStatusContainer
    
    -- 监听子项变化以更新最后一个项的圆角
    local function updateFeatureStatusCorners()
        if not Private.FeatureStatusContainer then return end
        
        local children = Private.FeatureStatusContainer:GetChildren()
        local statusItems = {}
        for _, child in ipairs(children) do
            if child:IsA("TextLabel") then
                table.insert(statusItems, child)
            end
        end
        
        for _, item 在 ipairs(statusItems) do
            local corner = item:FindFirstChildOfClass("UICorner")
            if corner then
                corner:Destroy()
            end
        end
        
        if #statusItems > 0 then
            local lastItem = statusItems[#statusItems]
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = lastItem
        end
    end
    
    Private.FeatureStatusContainer.ChildAdded:Connect(updateFeatureStatusCorners)
    Private.FeatureStatusContainer.ChildRemoved:Connect(updateFeatureStatusCorners)
    
    return Private.FeatureStatusContainer
end

--[[
    创建简化的渐变文字效果
    @param textLabel TextLabel - 要应用效果的文本标签
    @param featureName string - 功能名称
    @return Connection - 渐变效果连接
]]
function MCTechGUILib.CreateSimpleGradientTextEffect(textLabel, featureName)
    local time = 0
    local gradientSpeed = 1.2
    
    local connection
    connection = Private.RunService.Heartbeat:Connect(function(dt)
        if not textLabel.Parent 键，然后
            connection:Disconnect()
            return
        end
        
        time = time + dt * gradientSpeed
        
        -- 创建彩虹渐变效果
        local hue = (time * 60 + (#featureName * 20)) % 360 -- 根据功能名称偏移色相
        local saturation = 0.8 + 0.2 * math.sin(time * 2)
        local brightness = 0.9 + 0.1 * math.sin(time * 3)
        
        -- HSV转RGB
        local function HSVtoRGB(h, s, v)
            local r, g, b
            local i = math.floor(h / 60) % 6
            local f = (h / 60) - i
            local p = v * (1 - s)
            local q = v * (1 - f * s)
            local t = v * (1 - (1 - f) * s)
            
            if i == 0 then
                r, g, b = v, t, p
            elseif i == 1 then
                r, g, b = q, v, p
            elseif i == 2 then
                r, g, b = p, v, t
            elseif i == 3 then
                r, g, b = p, q, v
            elseif i == 4 then
                r, g, b = t, p, v
            else
                r, g, b = v, p, q
            end
            
            return Color3.new(r, g, b)
        end
        
        local gradientColor = HSVtoRGB(hue, saturation, brightness)
        textLabel.TextColor3 = gradientColor
        
        -- 添加发光效果
        local glowIntensity = 0.3 + 0.7 * math.abs(math.sin(time * 1.5))
        textLabel.TextStrokeTransparency = 0.8 - (glowIntensity * 0.3)
        textLabel.TextStrokeColor3 = gradientColor
    end)
    
    return connection
end

--[[
    添加功能状态显示项
    @param featureName string - 功能名称
    @return TextLabel|nil - 状态文本标签或nil
]]
function MCTechGUILib.AddFeatureStatusItem(featureName)
    if not Private.ShowFeatureStatus or not Private.FeatureStatusContainer or Private.ExcludedMenus[featureName] then
        return nil
    end
    
    -- 创建状态项容器
    local statusContainer = Instance.new("Frame")
    statusContainer.Name = "StatusContainer_" .. featureName
    statusContainer.Size = UDim2.new(0, 150, 0, 25) -- 增加高度以容纳背景
    statusContainer.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- 浅灰色背景
    statusContainer.BackgroundTransparency = 0.7 -- 半透明
    statusContainer.BorderSizePixel = 0
    statusContainer.Parent = Private.FeatureStatusContainer
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = statusContainer
    
    -- 创建纯文本标签
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status_" .. featureName
    statusText.Size = UDim2.new(1, 0, 1, 0) -- 填充容器
    statusText.BackgroundTransparency = 1 -- 完全透明背景
    statusText.BorderSizePixel = 0
    statusText.Text = featureName -- 只显示功能名称
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextSize = 16 -- 固定文字大小
    statusText.Font = Enum.Font.GothamBold
    statusText.TextXAlignment = Enum.TextXAlignment.Right -- 右对齐
    statusText.TextStrokeTransparency = 0.5
    statusText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusText.Parent = statusContainer
    
    -- 启动渐变文字效果
    local gradientConnection = MCTechGUILib.CreateSimpleGradientTextEffect(statusText, featureName)
    
    -- 滑入动画
    statusContainer.Position = UDim2.new(0, 200, 0, 0)
    local slideInTween = Private.TweenService:Create(
        statusContainer,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    slideInTween:Play()
    
    -- 存储连接以便清理
    statusContainer:SetAttribute("GradientConnection", gradientConnection)
    
    -- 更新容器大小
    MCTechGUILib.UpdateFeatureStatusContainerSize()
    
    return statusContainer
end

--[[
    移除功能状态显示项
    @param featureName string - 功能名称
]]
function MCTechGUILib.RemoveFeatureStatusItem(featureName)
    if not Private.FeatureStatusContainer then
        return
    end
    
    local statusContainer = Private.FeatureStatusContainer:FindFirstChild("StatusContainer_" .. featureName)
    if statusContainer then
        -- 清理渐变效果连接
        local gradientConnection = statusContainer:GetAttribute("GradientConnection")
        if gradientConnection then
            gradientConnection:Disconnect()
        end
        
        -- 滑出动画
        local slideOutTween = Private.TweenService:Create(
            statusContainer,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0, 200, 0, 0),
                BackgroundTransparency = 1
            }
        )
        
        slideOutTween:Play()
        slideOutTween.Completed:Connect(function()
            statusContainer:Destroy()
            MCTechGUILib.UpdateFeatureStatusContainerSize()
        end)
    end
end

--[[
    更新功能状态容器大小
]]
function MCTechGUILib.UpdateFeatureStatusContainerSize()
    if not Private.FeatureStatusContainer then
        return
    end
    
    local childCount = 0
    for _, child in ipairs(Private.FeatureStatusContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("StatusContainer_") then
            childCount = childCount + 1
        end
    end
    
    local newHeight = math.max(0, childCount * 30 - 5) -- 25像素高度 + 5像素间距，最后一项不需要间距
    
    local sizeTween = Private.TweenService:Create(
        Private.FeatureStatusContainer,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 200, 0, newHeight)}
    )
    sizeTween:Play()
end

--[[
    切换功能状态显示
    @param enabled boolean - 是否启用
]]
function MCTechGUILib.ToggleFeatureStatusDisplay(enabled)
    Private.ShowFeatureStatus = enabled
    
    if Private.FeatureStatusContainer then
        Private.FeatureStatusContainer.Visible = enabled
        
        if enabled then
            -- 重新显示所有激活的功能
            for featureName, _ 在 pairs(Private.ActiveFeatures) do
                if not Private.FeatureStatusContainer:FindFirstChild("StatusContainer_" .. featureName) and not Private.ExcludedMenus[featureName] then
                    MCTechGUILib.AddFeatureStatusItem(featureName)
                end
            end
        end
        MCTechGUILib.UpdateFeatureStatusContainerSize()
    elseif enabled 键，然后
        -- 如果容器不存在但需要显示，创建它
        MCTechGUILib.CreateFeatureStatusContainer()
        for featureName, _ in pairs(Private.ActiveFeatures) do
            if not Private.ExcludedMenus[featureName] then
                MCTechGUILib.AddFeatureStatusItem(featureName)
            end
        end
        MCTechGUILib.UpdateFeatureStatusContainerSize()
    end
end

--[[
    更新功能状态
    @param featureName string - 功能名称
    @param isActive boolean - 是否激活
]]
function MCTechGUILib.UpdateFeatureStatus(featureName, isActive)
    if isActive then
        Private.ActiveFeatures[featureName] = true
        if Private.ShowFeatureStatus 和 not Private.ExcludedMenus[featureName] then
            MCTechGUILib.AddFeatureStatusItem(featureName)
            MCTechGUILib.UpdateFeatureStatusContainerSize()
        end
    else
        Private.ActiveFeatures[featureName] = nil
        MCTechGUILib.RemoveFeatureStatusItem(featureName)
        MCTechGUILib.UpdateFeatureStatusContainerSize()
    end
end

--[[
    显示通知
    @param title string - 通知标题
    @param message string - 通知消息
    @param isEnabled boolean - 是否启用状态
]]
function MCTechGUILib.ShowNotification(title, message, isEnabled)
    -- 创建通知容器
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 180, 0, 45) -- 更小的通知
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.ClipsDescendants = false
    notification.ZIndex = 10 -- 高层级，确保通知在其他UI上方
    notification.Parent = Private.ScreenGui
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notification
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.CreatePinkBlueGradientEffect(notification)
    
    -- 添加粉蓝渐变边框
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = notification
    
    -- 启动粉蓝渐变边框效果
    local strokeConnection = MCTechGUILib.CreatePinkBlueStrokeEffect(stroke)
    
    -- 标题文本
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -15, 0, 16)
    titleLabel.Position = UDim2.new(0, 8, 0, 3)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 11
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextStrokeTransparency = 0.7
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = notification
    
    -- 消息文本
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -15, 0, 13)
    messageLabel.Position = UDim2.new(0, 8, 0, 20)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = isEnabled and Color3.fromRGB(173, 216, 230) or Color3.fromRGB(255, 182, 193)
    messageLabel.TextSize = 9
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextStrokeTransparency = 0.8
    messageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    messageLabel.Parent = notification
    
    -- 状态指示器
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 6, 0, 6)
    statusIndicator.Position = UDim2.new(1, -12, 0, 6)
    statusIndicator.BackgroundColor3 = isEnabled and Color3.fromRGB(135, 206, 250) or Color3.fromRGB(255, 105, 180)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = notification
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 3)
    indicatorCorner.Parent = statusIndicator
    
    -- 设置初始位置（在屏幕右侧外）
    local screenSize = workspace.CurrentCamera.ViewportSize
    notification.Position = UDim2.new(0, screenSize.X, 1, -60 - (#Private.ActiveNotifications * 50))
    
    -- 添加到活跃通知列表
    table.insert(Private.ActiveNotifications, notification)
    
    -- 计算出现时间（每个通知延迟0.2秒出现，避免重叠）
    local appearDelay = #Private.ActiveNotifications * 0.2
    
    task.wait(appearDelay)
    
    -- 滑入动画
    local slideInTween = Private.TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -190, 1, -60 - ((#Private.ActiveNotifications - 1) * 50))}
    )
    
    slideInTween:Play()
    
    -- 2秒后滑出（每个通知独立计时）
    task.wait(2)
    
    -- 滑出动画
    local slideOutTween = Private.TweenService:Create(
        notification,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 50, 1, -60 - ((#Private.ActiveNotifications - 1) * 50))}
    )
    
    slideOutTween:Play()
    
    slideOutTween.Completed:Connect(function()
        -- 停止渐变效果
        if strokeConnection then
            strokeConnection:Disconnect()
        end
        
        -- 从活跃通知列表中移除
        for i, notif in ipairs(Private.ActiveNotifications) do
            if notif == notification then
                table.remove(Private.ActiveNotifications, i)
                break
            end
        end
        
        notification:Destroy()
        
        -- 重新排列剩余通知
        for i, notif 在 ipairs(Private.ActiveNotifications) do
            local repositionTween = Private.TweenService:Create(
                notif,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, -190， 1, -60 - ((i - 1) * 50))}
            )
            repositionTween:Play()
        end
    end)
end

--[[
    创建细节调整窗口
    @param title string - 窗口标题
    @param parentButton TextButton - 父按钮
    @param onValueChange function - 值变化回调
    @return Frame - 细节窗口
]]
function MCTechGUILib.CreateDetailWindow(title, parentButton, onValueChange)
    -- 创建窗口容器
    local detailFrame = Instance.new("Frame")
    detailFrame.Name = title .. "Detail"
    detailFrame.Size = UDim2.new(0, 250, 0, 150) -- 增加宽度以扩大拉条范围
    detailFrame.BackgroundColor3 = Color3.fromRGB(30， 30, 40)
    detailFrame.BackgroundTransparency = 0.1
    detailFrame.BorderSizePixel = 0
    detailFrame.ClipsDescendants = true
    detailFrame.ZIndex = 7 -- 高于菜单层级
    detailFrame.Parent = Private.ScreenGui
    
    -- 添加圆角
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 6)
    detailCorner.Parent = detailFrame
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.CreatePinkBlueGradientEffect(detailFrame)
    
    -- 添加粉蓝渐变边框
    local detailStroke = Instance.new("UIStroke")
    detailStroke.Thickness = 2
    detailStroke.Transparency = 0.3
    detailStroke.Parent = detailFrame
    
    -- 启动粉蓝渐变边框效果
    MCTechGUILib.CreatePinkBlueStrokeEffect(detailStroke)
    
    -- 标题栏（可拖动区域）
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.Position = UDim2.new(0， 0, 0, 0)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Text = title .. " 设置"
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 16
    header.Font = Enum.Font.GothamBold
    header.TextStrokeTransparency = 0.7
    header.TextStrokeColor3 = Color3.fromRGB(0， 0, 0)
    header.Parent = detailFrame
    
    -- 内容容器
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1， 0， 1, -30)
    contentFrame.Position = UDim2.new(0， 0， 0， 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = detailFrame
    
    -- 速度滑块
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 20)
    sliderLabel.Position = UDim2.new(0, 0, 0, 0)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "速度调整"
    sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderLabel.TextSize = 12
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.Parent = contentFrame
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.Position = UDim2.new(0, 10, 0, 25)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sliderTrack.BorderSizePixel = 0
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderTrack
    sliderTrack.Parent = contentFrame
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0， 12， 0, 12)
    sliderKnob.Position = UDim2.new(0, 0， 0.5, -3)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0， 6)
    knobCorner.Parent = sliderKnob
    sliderKnob.Parent = sliderTrack
    
    local sliderValue = Instance.new("TextLabel")
    sliderValue.Size = UDim2.new(0， 30， 0, 15)
    sliderValue.Position = UDim2.new(0.5, -15, -1, -5)
    sliderValue.BackgroundTransparency = 1
    sliderValue.Text = "1.0"
    sliderValue.TextColor3 = Color3.fromRGB(255， 255, 255)
    sliderValue.TextSize = 10
    sliderValue.Parent = sliderKnob
    
    -- 滑块交互（只在滑块区域内）
    local minValue = 1.0
    local maxValue = 10.0
    local currentValue = 1.0
    local dragging = false
    
    local function updateSlider(value)
        currentValue = value
        sliderValue.Text = string.format("%.1f", currentValue)
        if onValueChange then
            onValueChange(currentValue)
        end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 或 input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local trackAbsPos = sliderTrack.AbsolutePosition.X
            local trackAbsSize = sliderTrack.AbsoluteSize.X
            local mouseX = input.Position.X
            local relativePos = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            sliderKnob.Position = UDim2.new(relativePos, 0, 0.5, -3)
            updateSlider(minValue + (maxValue - minValue) * relativePos)
        end
    end)
    
    Private.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    Private.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackAbsPos = sliderTrack.AbsolutePosition.X
            local trackAbsSize = sliderTrack.AbsoluteSize.X
            local mouseX = input.Position.X
            
            local relativePos = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0， 1)
            sliderKnob.Position = UDim2.new(relativePos, 0， 0.5, -3)
            
            updateSlider(minValue + (maxValue - minValue) * relativePos)
        end
    end)
    
    -- 自动跳跃开关（经典开关样式）
    local switchLabel = Instance.new("TextLabel")
    switchLabel.Size = UDim2.new(1, 0, 0, 20)
    switchLabel.Position = UDim2.new(0， 0, 0, 40)
    switchLabel.BackgroundTransparency = 1
    switchLabel.Text = "自动跳跃"
    switchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    switchLabel.TextSize = 12
    switchLabel.Font = Enum.Font.Gotham
    switchLabel.Parent = contentFrame
    
    local switchFrame = Instance.new("Frame")
    switchFrame.Size = UDim2.new(0, 40, 0, 20)
    switchFrame.Position = UDim2.new(1, -50, 0, 40)
    switchFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    switchFrame.BorderSizePixel = 0
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 10)
    switchCorner.Parent = switchFrame
    switchFrame.Parent = contentFrame
    
    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 20, 1, 0)
    switchKnob.Position = UDim2.new(0, 0, 0, 0)
    switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    switchKnob.BorderSizePixel = 0
    local switchKnobCorner = Instance.new("UICorner")
    switchKnobCorner.CornerRadius = UDim.new(0, 10)
    switchKnobCorner.Parent = switchKnob
    switchKnob.Parent = switchFrame
    
    local autoJumpEnabled = false
    switchFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            autoJumpEnabled = not autoJumpEnabled
            local targetPos = autoJumpEnabled and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
            local tween = Private.TweenService:Create(switchKnob, TweenInfo.new(0.2), {Position = targetPos})
            tween:Play()
            switchFrame.BackgroundColor3 = autoJumpEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 100)
            if onValueChange then
                onValueChange("autoJump", autoJumpEnabled)
            end
        end
    end)
    
    -- 拖动功能
    local dragInput, dragStart, startPos
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        detailFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = detailFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragInput = nil
                end
            end)
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    Private.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput then
            updateInput(input)
        end
    end)
    
    -- 设置位置在父按钮旁边
    local parentButtonPos = parentButton.AbsolutePosition
    local parentButtonSize = parentButton.AbsoluteSize
    detailFrame.Position = UDim2.new(
        0, parentButtonPos.X + parentButtonSize.X + 5,
        0, parentButtonPos.Y
    )
    
    -- 初始透明度为1，准备浮现动画
    detailFrame.BackgroundTransparency = 1
    header.TextTransparency = 1
    
    local fadeIn = Private.TweenService:Create(
        detailFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.1}
    )
    
    local textFadeIn = Private.TweenService:Create(
        header,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    detailFrame.Visible = true
    Private.DetailStates[title] = true
    
    return detailFrame
end

--[[
    创建浮动菜单
    @param title string - 菜单标题
    @param options table - 菜单选项
    @param isSubMenu boolean - 是否为子菜单
    @param parentMenuButton TextButton - 父菜单按钮
    @return Frame - 菜单框架
]]
function MCTechGUILib.CreateFloatingMenu(title, options, isSubMenu, parentMenuButton)
    -- 如果是子菜单且已存在，则切换显示状态
    if isSubMenu and Private.SubMenus[title] then
        local menu = Private.SubMenus[title]
        local isCurrentlyVisible = menu.Visible
        
        -- 添加浮现动画
        if not isCurrentlyVisible then
            menu.Visible = true
            menu.BackgroundTransparency = 1
            menu.Header.TextTransparency = 1
            
            -- 浮现动画
            local fadeIn = Private.TweenService:Create(
                menu,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0.1}
            )
            
            local textFadeIn = Private.TweenService:Create(
                menu.Header,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 0}
            )
            
            fadeIn:Play()
            textFadeIn:Play()
        else
            -- 淡出动画
            local fadeOut = Private.TweenService:Create(
                menu,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            
            local textFadeOut = Private.TweenService:Create(
                menu.Header,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 1}
            )
            
            fadeOut:Play()
            textFadeOut:Play()
            
            fadeOut.Completed:Connect(function()
                menu.Visible = false
            end)
        end
        
        Private.SubMenuStates[title] = not isCurrentlyVisible
        return menu
    end
    
    -- 创建菜单容器
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = title .. "Menu"
    menuFrame.Size = UDim2.new(0, 200, 0, 40 + (#options * 40))
    menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    menuFrame.BackgroundTransparency = 0.1
    menuFrame.BorderSizePixel = 0
    menuFrame.ClipsDescendants = true
    menuFrame.ZIndex = isSubMenu and 5 or 3
    menuFrame.Visible = true
    menuFrame.Parent = Private.ScreenGui
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = menuFrame
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.CreatePinkBlueGradientEffect(menuFrame)
    
    -- 添加粉蓝渐变边框
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = menuFrame
    
    -- 启动粉蓝渐变边框效果
    MCTechGUILib.CreatePinkBlueStrokeEffect(stroke)
    
    -- 标题栏（可拖动区域）
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Text = title
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 16
    header.Font = Enum.Font.GothamBold
    header.TextStrokeTransparency = 0.7
    header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    header.ZIndex = menuFrame.ZIndex + 1
    header.Parent = menuFrame
    
    -- 内容容器
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -30)
    contentFrame.Position = UDim2.new(0, 0, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ZIndex = menuFrame.ZIndex + 1
    contentFrame.Parent = menuFrame
    
    -- 添加选项按钮
    for i, option in ipairs(options) do
        local button = Instance.new("TextButton")
        button.Name = option.Name
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, (i - 1) * 40 + 5)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        button.BackgroundTransparency = 0.5
        button.BorderSizePixel = 0
        button.Text = option.Name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.Gotham
        button.ZIndex = menuFrame.ZIndex + 2
        button.Parent = contentFrame
        
        -- 添加圆角
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        -- 添加悬停效果
        button.MouseEnter:Connect(function()
            button.BackgroundTransparency = 0.3
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundTransparency = 0.5
        end)
        
        -- 点击事件
        button.MouseButton1Click:Connect(function()
            if option.Callback then
                option.Callback()
            end
            
            -- 显示通知
            if option.Name ~= "设置" and option.Name ~= "显示功能状态" then
                MCTechGUILib.ShowNotification(title, option.Name .. " 已激活", true)
                MCTechGUILib.UpdateFeatureStatus(option.Name, true)
            end
        end)
    end
    
    -- 拖动功能
    local dragInput, dragStart, startPos
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        menuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = menuFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragInput = nil
                end
            end)
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    Private.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput then
            updateInput(input)
        end
    end)
    
    -- 设置位置
    if isSubMenu and parentMenuButton then
        -- 子菜单位置在父按钮旁边
        local parentButtonPos = parentMenuButton.AbsolutePosition
        local parentButtonSize = parentMenuButton.AbsoluteSize
        menuFrame.Position = UDim2.new(
            0, parentButtonPos.X + parentButtonSize.X + 5,
            0, parentButtonPos.Y
        )
    else
        -- 主菜单位置在屏幕中央
        local screenSize = workspace.CurrentCamera.ViewportSize
        menuFrame.Position = UDim2.new(
            0.5, -100,
            0.5, -menuFrame.Size.Y.Offset / 2
        )
    end
    
    -- 初始透明度为1，准备浮现动画
    menuFrame.BackgroundTransparency = 1
    header.TextTransparency = 1
    
    local fadeIn = Private.TweenService:Create(
        menuFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.1}
    )
    
    local textFadeIn = Private.TweenService:Create(
        header,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    -- 存储菜单引用
    if isSubMenu then
        Private.SubMenus[title] = menuFrame
        Private.SubMenuStates[title] = true
    end
    
    return menuFrame
end

--[[
    重置UI（关闭所有已打开的功能并销毁UI面板）
]]
function MCTechGUILib.ResetUI()
    -- 关闭所有已打开的功能
    for featureName, _ in pairs(Private.ActiveFeatures) do
        MCTechGUILib.UpdateFeatureStatus(featureName, false)
    end
    
    -- 清空活跃功能表
    Private.ActiveFeatures = {}
    
    -- 销毁所有子菜单
    for _, menu in pairs(Private.SubMenus) do
        if menu and menu.Parent then
            menu:Destroy()
        end
    end
    Private.SubMenus = {}
    Private.SubMenuStates = {}
    
    -- 销毁所有细节窗口
    for _, window in pairs(Private.DetailWindows) do
        if window and window.Parent then
            window:Destroy()
        end
    end
    Private.DetailWindows = {}
    Private.DetailStates = {}
    
    -- 销毁功能状态容器
    if Private.FeatureStatusContainer and Private.FeatureStatusContainer.Parent then
        Private.FeatureStatusContainer:Destroy()
        Private.FeatureStatusContainer = nil
    end
    
    -- 销毁主UI
    if Private.ScreenGui and Private.ScreenGui.Parent then
        Private.ScreenGui:Destroy()
        Private.ScreenGui = nil
    end
    
    -- 重新初始化
    MCTechGUILib.Init()
    
    -- 重新创建功能状态容器
    MCTechGUILib.CreateFeatureStatusContainer()
end

--[[
    创建主菜单
    @return Frame - 主菜单框架
]]
function MCTechGUILib.CreateMainMenu()
    local mainMenuOptions = {
        {
            Name = "飞行",
            Callback = function()
                -- 飞行功能实现
                MCTechGUILib.ShowNotification("飞行", "飞行功能已激活", true)
                MCTechGUILib.UpdateFeatureStatus("飞行", true)
            end
        },
        {
            Name = "穿墙",
            Callback = function()
                -- 穿墙功能实现
                MCTechGUILib.ShowNotification("穿墙", "穿墙功能已激活", true)
                MCTechGUILib.UpdateFeatureStatus("穿墙", true)
            end
        },
        {
            Name = "速度",
            Callback = function()
                -- 速度功能实现
                MCTechGUILib.ShowNotification("速度", "速度功能已激活", true)
                MCTechGUILib.UpdateFeatureStatus("速度", true)
            end
        },
        {
            Name = "夜视",
            Callback = function()
                -- 夜视功能实现
                MCTechGUILib.ShowNotification("夜视", "夜视功能已激活", true)
                MCTechGUILib.UpdateFeatureStatus("夜视", true)
            end
        },
        {
            Name = "设置",
            Callback = function()
                -- 设置子菜单
                local settingsMenu = MCTechGUILib.CreateFloatingMenu("设置", {
                    {
                        Name = "显示功能状态",
                        Callback = function()
                            Private.ShowFeatureStatus = not Private.ShowFeatureStatus
                            MCTechGUILib.ToggleFeatureStatusDisplay(Private.ShowFeatureStatus)
                            MCTechGUILib.ShowNotification("设置", "功能状态显示: " .. (Private.ShowFeatureStatus and "开启" or "关闭"), Private.ShowFeatureStatus)
                        end
                    },
                    {
                        Name = "重置UI",
                        Callback = function()
                            MCTechGUILib.ResetUI()
                            MCTechGUILib.ShowNotification("设置", "UI已重置", true)
                        end
                    }
                }, true)
            end
        }
    }
    
    -- 创建功能状态容器
    MCTechGUILib.CreateFeatureStatusContainer()
    
    return MCTechGUILib.CreateFloatingMenu("MC科技菜单", mainMenuOptions, false)
end

-- 自动初始化
MCTechGUILib.Init()

return MCTechGUILib

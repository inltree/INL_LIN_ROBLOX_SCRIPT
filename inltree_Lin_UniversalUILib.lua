-- MCTechGUILib.lua - MC科技风格UI库
-- 版本: 4.0
-- 提供科技感十足的Roblox UI组件

local MCTechGUILib = {}

-- 私有属性表
local private = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game::GetService("TweenService"),
    RunService = game:GetService("RunService"),
    player = nil,
    playerGui = nil,
    screenGui = nil,
    subMenus = {},
    subMenuStates = {},
    detailWindows = {},
    detailStates = {},
    notificationQueue = {},
    activeNotifications = {},
    activeFeatures = {},
    featureStatusContainer = nil,
    showFeatureStatus = true,
    excludedMenus = {
        ["设置"] = true,
        ["显示功能状态"] = true
    }
}

-- 初始化库
function MCTechGUILib.init()
    private.player = private.Players.LocalPlayer
    private.playerGui = private.player:WaitForChild("PlayerGui")
    
    -- 创建主ScreenGui
    if not private.screenGui then
        private.screenGui = Instance.new("ScreenGui")
        private.screenGui.Name = "MCTechGUI"
        private.screenGui.ResetOnSpawn = false
        private.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        private.screenGui.Parent = private.playerGui
    end
    
    return MCTechGUILib
end

-- 粉蓝渐变色配置
function MCTechGUILib.createPinkBlueGradientEffect(frame)
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
    local rotationTween = private.TweenService:Create(
        gradient,
        TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 405} -- 360度 + 45度初始角度
    )
    rotationTween:Play()
    
    return gradient
end

-- 创建粉蓝渐变边框效果
function MCTechGUILib.createPinkBlueStrokeEffect(stroke)
    local gradientSpeed = 0.5
    local time = 0
    
    local connection
    connection = private.RunService.Heartbeat:Connect(function(dt)
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

-- 创建功能状态显示容器
function MCTechGUILib.createFeatureStatusContainer()
    private.featureStatusContainer = Instance.new("Frame")
    private.featureStatusContainer.Name = "FeatureStatusContainer"
    private.featureStatusContainer.Size = UDim2.new(0, 200, 0, 0)
    private.featureStatusContainer.Position = UDim2.new(1, -220, 0, 20) -- 确保在右上角
    private.featureStatusContainer.BackgroundTransparency = 1
    private.featureStatusContainer.BorderSizePixel = 0
    private.featureStatusContainer.ClipsDescendants = false
    private.featureStatusContainer.Visible = private.showFeatureStatus
    private.featureStatusContainer.Parent = private.screenGui
    
    -- 添加自动布局
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right -- 右对齐
    listLayout.Parent = private.featureStatusContainer
    
    -- 监听子项变化以更新最后一个项的圆角
    local function updateFeatureStatusCorners()
        if not private.featureStatusContainer then return end
        
        local children = private.featureStatusContainer:GetChildren()
        local statusItems = {}
        for _, child in ipairs(children) do
            if child:IsA("TextLabel") then
                table.insert(statusItems, child)
            end
        end
        
        for _, item in ipairs(statusItems) do
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
    
    private.featureStatusContainer.ChildAdded:Connect(updateFeatureStatusCorners)
    private.featureStatusContainer.ChildRemoved:Connect(updateFeatureStatusCorners)
    
    return private.featureStatusContainer
end

-- 创建简化的渐变文字效果
function MCTechGUILib.createSimpleGradientTextEffect(textLabel, featureName)
    local time = 0
    local gradientSpeed = 1.2
    
    local connection
    connection = private.RunService.Heartbeat:Connect(function(dt)
        if not textLabel.Parent then
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

-- 添加功能状态显示项
function MCTechGUILib.addFeatureStatusItem(featureName)
    if not private.showFeatureStatus or not private.featureStatusContainer or private.excludedMenus[featureName] then
        return nil
    end
    
    -- 创建纯文本标签
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status_" .. featureName
    statusText.Size = UDim2.new(0, 150, 0, 18) -- 固定大小
    statusText.BackgroundTransparency = 1 -- 完全透明背景
    statusText.BorderSizePixel = 0
    statusText.Text = featureName -- 只显示功能名称
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextSize = 16 -- 固定文字大小
    statusText.Font = Enum.Font.GothamBold
    statusText.TextXAlignment = Enum.TextXAlignment.Right -- 右对齐
    statusText.TextStrokeTransparency = 0.5
    statusText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusText.Parent = private.featureStatusContainer
    
    -- 启动渐变文字效果
    local gradientConnection = MCTechGUILib.createSimpleGradientTextEffect(statusText, featureName)
    
    -- 滑入动画
    statusText.Position = UDim2.new(0, 200, 0, 0)
    local slideInTween = private.TweenService:Create(
        statusText,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    slideInTween:Play()
    
    -- 存储连接以便清理
    statusText:SetAttribute("GradientConnection", gradientConnection)
    
    -- 更新容器大小
    MCTechGUILib.updateFeatureStatusContainerSize()
    
    return statusText
end

-- 移除功能状态显示项
function MCTechGUILib.removeFeatureStatusItem(featureName)
    if not private.featureStatusContainer then
        return
    end
    
    local statusText = private.featureStatusContainer:FindFirstChild("Status_" .. featureName)
    if statusText then
        -- 清理渐变效果连接
        local gradientConnection = statusText:GetAttribute("GradientConnection")
        if gradientConnection then
            gradientConnection:Disconnect()
        end
        
        -- 滑出动画
        local slideOutTween = private.TweenService:Create(
            statusText,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0, 200, 0, 0),
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }
        )
        
        slideOutTween:Play()
        slideOutTween.Completed:Connect(function()
            statusText:Destroy()
            MCTechGUILib.updateFeatureStatusContainerSize()
        end)
    end
end

-- 更新功能状态容器大小
function MCTechGUILib.updateFeatureStatusContainerSize()
    if not private.featureStatusContainer then
        return
    end
    
    local childCount = #private.featureStatusContainer:GetChildren() - 1 -- 减去UIListLayout
    local newHeight = math.max(0, childCount * 23 - 5) -- 18像素高度 + 5像素间距，最后一项不需要间距
    
    local sizeTween = private.TweenService:Create(
        private.featureStatusContainer,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 200, 0, newHeight)}
    )
    sizeTween:Play()
end

-- 切换功能状态显示
function MCTechGUILib.toggleFeatureStatusDisplay(enabled)
    private.showFeatureStatus = enabled
    
    if private.featureStatusContainer then
        private.featureStatusContainer.Visible = enabled
        
        if enabled then
            -- 重新显示所有激活的功能
            for featureName, _ in pairs(private.activeFeatures) do
                if not private.featureStatusContainer:FindFirstChild("Status_" .. featureName) and not private.excludedMenus[featureName] then
                    MCTechGUILib.addFeatureStatusItem(featureName)
                end
            end
        end
        MCTechGUILib.updateFeatureStatusContainerSize()
    elseif enabled then
        -- 如果容器不存在但需要显示，创建它
        MCTechGUILib.createFeatureStatusContainer()
        for featureName, _ in pairs(private.activeFeatures) do
            if not private.excludedMenus[featureName] then
                MCTechGUILib.addFeatureStatusItem(featureName)
            end
        end
        MCTechGUILib.updateFeatureStatusContainerSize()
    end
end

-- 更新功能状态
function MCTechGUILib.updateFeatureStatus(featureName, isActive)
    if isActive then
        private.activeFeatures[featureName] = true
        if private.showFeatureStatus and not private.excludedMenus[featureName] then
            MCTechGUILib.addFeatureStatusItem(featureName)
            MCTechGUILib.updateFeatureStatusContainerSize()
        end
    else
        private.activeFeatures[featureName] = nil
        MCTechGUILib.removeFeatureStatusItem(featureName)
        MCTechGUILib.updateFeatureStatusContainerSize()
    end
end

-- 显示通知
function MCTechGUILib.showNotification(title, message, isEnabled)
    -- 创建通知容器
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 180, 0, 45) -- 更小的通知
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.ClipsDescendants = false
    notification.ZIndex = 10 -- 高层级，确保通知在其他UI上方
    notification.Parent = private.screenGui
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notification
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.createPinkBlueGradientEffect(notification)
    
    -- 添加粉蓝渐变边框
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = notification
    
    -- 启动粉蓝渐变边框效果
    local strokeConnection = MCTechGUILib.createPinkBlueStrokeEffect(stroke)
    
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
    notification.Position = UDim2.new(0, screenSize.X, 1, -60 - (#private.activeNotifications * 50))
    
    -- 添加到活跃通知列表
    table.insert(private.activeNotifications, notification)
    
    -- 计算出现时间（每个通知延迟0.2秒出现，避免重叠）
    local appearDelay = #private.activeNotifications * 0.2
    
    task.wait(appearDelay)
    
    -- 滑入动画
    local slideInTween = private.TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -190, 1, -60 - ((#private.activeNotifications - 1) * 50))}
    )
    
    slideInTween:Play()
    
    -- 2秒后滑出（每个通知独立计时）
    task.wait(2)
    
    -- 滑出动画
    local slideOutTween = private.TweenService:Create(
        notification,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 50, 1, -60 - ((#private.activeNotifications - 1) * 50))}
    )
    
    slideOutTween:Play()
    
    slideOutTween.Completed:Connect(function()
        -- 停止渐变效果
        if strokeConnection then
            strokeConnection:Disconnect()
        end
        
        -- 从活跃通知列表中移除
        for i, notif in ipairs(private.activeNotifications) do
            if notif == notification then
                table.remove(private.activeNotifications, i)
                break
            end
        end
        
        notification:Destroy()
        
        -- 重新排列剩余通知
        for i, notif in ipairs(private.activeNotifications) do
            local repositionTween = private.TweenService:Create(
                notif,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, -190, 1, -60 - ((i - 1) * 50))}
            )
            repositionTween:Play()
        end
    end)
end

-- 创建细节调整窗口
function MCTechGUILib.createDetailWindow(title, parentButton, onValueChange)
    -- 创建窗口容器
    local detailFrame = Instance.new("Frame")
    detailFrame.Name = title .. "Detail"
    detailFrame.Size = UDim2.new(0, 250, 0, 150) -- 增加宽度以扩大拉条范围
    detailFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    detailFrame.BackgroundTransparency = 0.1
    detailFrame.BorderSizePixel = 0
    detailFrame.ClipsDescendants = true
    detailFrame.ZIndex = 7 -- 高于菜单层级
    detailFrame.Parent = private.screenGui
    
    -- 添加圆角
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 6)
    detailCorner.Parent = detailFrame
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.createPinkBlueGradientEffect(detailFrame)
    
    -- 添加粉蓝渐变边框
    local detailStroke = Instance.new("UIStroke")
    detailStroke.Thickness = 2
    detailStroke.Transparency = 0.3
    detailStroke.Parent = detailFrame
    
    -- 启动粉蓝渐变边框效果
    MCTechGUILib.createPinkBlueStrokeEffect(detailStroke)
    
    -- 标题栏（可拖动区域）
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Text = title .. " 设置"
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 16
    header.Font = Enum.Font.GothamBold
    header.TextStrokeTransparency = 0.7
    header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    header.Parent = detailFrame
    
    -- 内容容器
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -30)
    contentFrame.Position = UDim2.new(0, 0, 0, 30)
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
    sliderKnob.Size = UDim2.new(0, 12, 0, 12)
    sliderKnob.Position = UDim2.new(0, 0, 0.5, -3)
    sliderKnob.BackgroundColor极 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 6)
    knobCorner.Parent = sliderKnob
    sliderKnob.Parent = sliderTrack
    
    local sliderValue = Instance.new("TextLabel")
    slider极.Size = UDim2.new(0, 30, 0, 15)
    sliderValue.Position = UDim2.new(0.5, -15, -1, -5)
    sliderValue.BackgroundTransparency = 1
    sliderValue.Text = "1.0"
    sliderValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderValue.TextSize = 10
    sliderValue.Parent = sliderKnob
    
    -- 滑块交互（只在滑块区域内）
    local minValue = 1.0
    local maxValue = 10.0
    local currentValue = 1.0
    local dragging = false
    
    local function updateSlider(value)
        current极 = value
        sliderValue.Text = string.format("%.1f", currentValue)
        if onValueChange then
            onValueChange(currentValue)
        end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.User极Type.Touch then
            dragging = true
            local trackAbsPos = sliderTrack.AbsolutePosition.X
            local trackAbsSize = sliderTrack.AbsoluteSize.X
            local mouseX = input.Position.X
            local relativePos = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            sliderKnob.Position = UDim2.new(relativePos, 0, 0.5, -3)
            updateSlider(minValue + (maxValue - minValue) * relativePos)
        end
    end)
    
    private.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    private.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackAbsPos = sliderTrack.AbsolutePosition.X
            local trackAbsSize = sliderTrack.Absolute极.X
            local mouseX = input.Position.X
            
            local relativePos = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            sliderKnob.Position = UDim2.new(relativePos, 极, 0.5, -3)
            
            updateSlider(minValue + (maxValue - minValue) * relativePos)
        end
    end)
    
    -- 自动跳跃开关（经典开关样式）
    local switchLabel = Instance.new("TextLabel")
    switchLabel.Size = UDim2.new(1, 0, 0, 20)
    switchLabel.Position = UDim2.new(0, 0, 0, 40)
    switchLabel.BackgroundTransparency = 1
    switchLabel.Text = "自动跳跃"
    switchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    switchLabel.TextSize = 12
    switchLabel.Font = Enum.Font.Gotham
    switchLabel.Parent = contentFrame
    
    local switchFrame = Instance.new("Frame")
    switchFrame.Size = UDim2.new(0, 40, 0, 20)
    switchFrame.Position = UDim2.new(1, -50, 0, 极)
    switchFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    switchFrame.BorderSizePixel = 0
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 10)
    switchCorner.Parent极 switchFrame
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
            local tween = private.TweenService:Create(switchKnob, TweenInfo.new(0.2), {Position = targetPos})
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
            
            input.Changed:极(function()
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
    
    private.UserInputService.InputChanged:Connect(function(input)
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
    
    local fadeIn = private.TweenService:Create(
        detailFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.1}
    )
    
    local text极 = private.TweenService:Create(
        header,
        Tween极.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    -- 存储窗口引用
    private.detailWindows[title] = detailFrame
    private.detailStates[title] = true
    
    return detailFrame
end

-- 关闭细节窗口
function MCTechGUILib.closeDetailWindow(title)
    if private.detailWindows[title] then
        local detailFrame = private.detailWindows[title]
        private.detailStates[title] = false
        
        -- 淡出动画
        local fadeOut = private.TweenService:Create(
            detailFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        
        local textFadeOut = private.TweenService:Create(
            detailFrame.Header,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 1}
        )
        
        fadeOut:Play()
        textFadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            detailFrame:Destroy()
            private.detailWindows[title] = nil
        end)
    end
end

-- 切换细节窗口
function MCTechGUILib.toggleDetailWindow(title, parentButton, onValueChange)
    if private.detailStates[title] then
        MCTechGUILib.closeDetailWindow(title)
    else
        -- 关闭其他所有细节窗口
        for otherTitle, _ in pairs(private.detailWindows) do
            if otherTitle ~= title then
                MCTechGUILib.closeDetailWindow(otherTitle)
            end
        end
        
        -- 创建新窗口
        MCTechGUILib.createDetailWindow(title, parentButton, onValueChange)
    end
end

-- 创建子菜单
function MCTechGUILib.createSubMenu(title, parentButton)
    -- 创建子菜单容器
    local subMenu = Instance.new("Frame")
    subMenu.Name = title .. "SubMenu"
    subMenu.Size = UDim2.new(0, 180, 0, 0) -- 高度初始为0
    subMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
   极.BackgroundTransparency = 0.1
    subMenu.BorderSizePixel = 0
    subMenu.ClipsDescendants = true
    subMenu.ZIndex = 5 -- 高于主菜单层级
    subMenu.Parent = private.screenGui
    
    -- 添加圆角
    local subMenuCorner = Instance.new("UICorner")
    subMenuCorner.CornerRadius = UDim.new(0, 6)
    subMenuCorner.Parent = subMenu
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.createPinkBlueGradientEffect(subMenu)
    
    -- 添加粉蓝渐变边框
    local subMenuStroke = Instance.new("UIStroke")
    subMenuStroke.Thickness = 2
    subMenuStroke.Transparency = 0.3
    subMenuStroke.Parent = subMenu
    
    -- 启动粉蓝渐变边框效果
    MCTechGUILib.createPinkBlueStrokeEffect(subMenu极)
    
    -- 添加自动布局
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = subMenu
    
    -- 设置位置在父按钮下方
    local parentButtonPos = parentButton.AbsolutePosition
    local parentButtonSize = parentButton.AbsoluteSize
    subMenu.Position = UDim2.new(
        0, parentButtonPos.X,
        0, parentButtonPos.Y + parentButtonSize.Y + 5
    )
    
    -- 存储子菜单引用
    private.subMenus[title] = subMenu
    private.subMenuStates[title] = false
    
    return subMenu
end

-- 打开子菜单
function MCTechGUILib.openSubMenu(title)
    if private.subMen极[title] then
        local subMenu = private.subMenus[title]
        private.subMenuStates[title] = true
        
        -- 计算子菜单高度
        local itemCount = #subMenu:GetChildren() - 1 -- 减去UIListLayout
        local targetHeight = math.max(30, itemCount * 35 + 10) -- 每个按钮35像素高度 + 10像素内边距
        
        -- 展开动画
        local expandTween = private.TweenService:Create(
            subMenu,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 180, 0, targetHeight)}
        )
        
        expandTween:Play()
        
        -- 淡入动画
        subMenu.BackgroundTransparency = 1
        local fadeIn = private.TweenService:Create(
            subMenu,
            TweenInfo.new(0.3, Enum.Easing极.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.1}
        )
        
        fadeIn:Play()
    end
end

-- 关闭子菜单
function MCTechGUILib.closeSubMenu(title)
    if private.subMenus[title] then
        local subMenu = private.subMenus[title]
        private.subMenuStates[title] = false
        
        -- 收缩动画
        local collapseTween = private.TweenService:Create(
            subMenu,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 180, 0, 0)}
        )
        
        collapseTween:Play()
        
        -- 淡出动画
        local fadeOut = private.TweenService:Create(
            subMenu,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        
        fadeOut:Play()
    end
end

-- 切换子菜单
function MCTechGUIL极.toggleSubMenu(title, parentButton)
    if private.subMenuStates[title] then
        MCTechGUILib.closeSubMenu(title)
    else
        -- 关闭其他所有子菜单
        for otherTitle, _ in pairs(private.subMenus) do
            if otherTitle ~= title then
                MCTechGUILib.closeSubMenu(otherTitle)
            end
        end
        
        -- 打开当前子菜单
        MCTechGUILib.openSubMenu(title)
    end
end

-- 创建主菜单
function MCTechGUILib.createMainMenu(menuItems)
    -- 创建主菜单容器
    local mainMenu = Instance.new("Frame")
    mainMenu.Name = "MainMenu"
    mainMenu.Size = UDim2.new(0, 180, 0, 40) -- 初始高度为40像素
    mainMenu.Position = UDim2.new(0, 20, 0, 20)
    mainMenu.BackgroundColor3 = Color3.fromRGB(30, 极, 40)
    mainMenu.BackgroundTransparency = 0.1
    mainMenu.BorderSizePixel = 0
    mainMenu.ClipsDescendants = true
    mainMenu.Z极 = 3
    mainMenu.Parent = private.screenGui
    
    -- 添加圆角
    local mainMenuCorner = Instance.new("UICorner")
    mainMenuCorner.CornerRadius = UDim.new(0, 6)
    mainMenuCorner.Parent = mainMenu
    
    -- 添加粉蓝渐变背景
    MCTechGUILib.createPinkBlueGradientEffect(mainMenu)
    
    -- 添加粉蓝渐变边框
    local mainMenuStroke = Instance.new("UIStroke")
    mainMenuStroke.Thickness = 2
    mainMenuStroke.Transparency = 0.3
    mainMenuStroke.Parent = mainMenu
    
    -- 启动粉蓝渐变边框效果
    MCTechGUILib.createPinkBlueStrokeEffect(mainMenuStroke)
    
    -- 标题栏（可拖动区域）
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Text = "MC科技风格4.0"
    header.TextColor3 = Color3.from极(255, 255, 255)
    header.TextSize = 16
    header.Font = Enum.Font.GothamBold
    header.TextStrokeTransparency = 0.7
    header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    header.Parent = mainMenu
    
    -- 内容容器
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.Position = UDim2.new(0, 0, 0, 40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Visible = false
    contentFrame.Parent = main极
    
    -- 添加自动布局
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = contentFrame
    
    -- 菜单项按钮
    for i, item in ipairs(menuItems) do
        local button = Instance.new("TextButton")
        button.Name = item.Name
        button.Size = UDim2.new(1, -10, 0, 35)
        button.Position = UDim2.new(0, 5, 0, (i - 1) * 40)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        button.BackgroundTransparency = 0.5
        button.BorderSizePixel = 0
        button.Text = item.Name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 极
        button.Font = Enum.Font.Gotham
        button.Parent = contentFrame
        
        -- 添加圆角
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        -- 添加悬停效果
        local originalSize = button.Size
        local hoverSize = UDim2.new(1, -5, 0, 35)
        
        button.MouseEnter:Connect(function()
            local tween = private.TweenService:Create(button, TweenInfo.new(0.2), {Size = hoverSize})
            tween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            local tween = private.TweenService:Create(button, TweenInfo.new(0.2), {Size = originalSize})
            tween:Play()
        end)
        
        -- 点击事件
        button.MouseButton1Click:Connect(function()
            if item.OnClick then
                item.OnClick(button)
            end
            
            if item.SubMenu then
                -- 如果有子菜单，创建或切换子菜单
                if not private.subMenus[item.Name] then
                    local subMenu = MCTechGUILib.createSubMenu(item.Name, button)
                    for _, subItem in ipairs(item.SubMenu) do
                        local subButton = Instance.new("TextButton")
                        subButton.Name = subItem.Name
                        subButton.Size = UDim2.new(1, -10, 0, 30)
                        subButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                        subButton.BackgroundTransparency = 0.3
                        subButton.BorderSizePixel = 0
                        subButton.Text = subItem.Name
                        subButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                        subButton.TextSize = 12
                        subButton.Font = Enum.Font.Gotham
                        subButton.LayoutOrder = #subMenu:GetChildren()
                        subButton.Parent = subMenu
                        
                        -- 添加圆角
                        local subButtonCorner = Instance.new("UICorner")
                        subButtonCorner.CornerRadius = UDim.new(0, 4)
                        subButtonCorner.Parent = subButton
                        
                        -- 悬停效果
                        local subOriginalSize = subButton.Size
                        local subHover极 = UDim2.new(1, -5, 0, 30)
                        
                        subButton.MouseEnter:Connect(function()
                            local tween = private.TweenService:Create(subButton, TweenInfo.new(0.2), {Size = subHoverSize})
                            tween:Play()
                        end)
                        
                        subButton.MouseLeave:Connect(function()
                            local tween = private.TweenService:Create(subButton, TweenInfo.new(0.2), {Size = subOriginalSize})
                            tween:Play()
                        end)
                        
                        -- 子菜单点击事件
                        subButton.MouseButton1Click:Connect(function()
                            if subItem.OnClick then
                                subItem.OnClick(subButton)
                            end
                        end)
                    end
                end
                
                MCTechGUILib.toggleSubMenu(item.Name, button)
            end
            
            if item.DetailWindow then
                -- 如果有细节窗口，创建或切换细节窗口
                MCTechGUILib.toggleDetailWindow(item.Name, button, item.OnValueChange)
            end
        end)
    end
    
    -- 拖动功能
    local dragInput, dragStart, startPos
    
    local function updateInput(input)
        local delta = input.Position - drag极
        mainMenu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
   极
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = mainMenu.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragInput = nil
                end
            end)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            -- 右键点击切换菜单展开/收缩
            if contentFrame.Visible then
                -- 收缩菜单
                local collapseTween = private.TweenService:Create(
                    mainMenu,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(0, 180, 0, 40)}
                )
                
                collapseTween:Play()
                contentFrame.Visible = false
                
                -- 关闭所有子菜单
                for title, _ in pairs(private.subMenus) do
                    MCTechGUILib.closeSubMenu(title)
                end
                
                -- 关闭所有细节窗口
                for title, _ in pairs(private.detailWindows) do
                    MCTechGUILib.closeDetailWindow(title)
                end
            else
                -- 展开菜单
                local itemCount = #menuItems
                local targetHeight = 40 + (itemCount * 40) + 5 -- 标题高度 + 按钮总高度 + 内边距
                
                local expandTween = private.TweenService:Create(
                    mainMenu,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                   极 Size = UDim2.new(0, 180, 0, targetHeight)}
                )
                
                expandTween:Play()
                contentFrame.Visible = true
            end
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    private.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput then
            updateInput(input)
        end
    end)
    
    -- 创建功能状态显示容器
    MCTechGUILib.createFeatureStatusContainer()
    
    return mainMenu
end

-- 重置UI：关闭所有活跃功能然后销毁UI面板
function MCTechGUILib.resetUI()
    -- 关闭所有活跃功能
    for featureName, _ in pairs(private.activeFeatures) do
        -- 这里应该调用每个功能的关闭函数
        -- 实际实现会根据具体功能而定
        MCTechGUILib.updateFeatureStatus(featureName, false)
    end
    
    -- 清空活跃功能表
    private.activeFeatures = {}
    
    -- 关闭所有细节窗口
    for title, _ in pairs(private.detailWindows) do
        MCTechGUILib.closeDetailWindow(title)
    end
    
    -- 关闭所有子菜单
极 for title, _ in pairs(private.subMenus) do
        MCTechGUILib.closeSubMenu(title)
    end
    
    -- 销毁UI面板
    if private.screenGui then
        private.screenGui:Destroy()
        private.screenGui = nil
    end
    
    -- 重置所有状态
    private.subMenus = {}
    private.subMenuStates = {}
    private.detailWindows = {}
    private.detailStates = {}
    private.activeNotifications = {}
    private.featureStatusContainer = nil
end

return MCTechGUILib

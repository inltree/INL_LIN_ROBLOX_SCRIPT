-- APbeGUI.lua - 改进版Roblox UI库
-- 版本: 5.0
-- 提供科技感十足的Roblox UI组件，优化了拖动功能，支持长按拖动和无限制范围拖动
-- 同时优化了自定义性和调用复杂性

local APbeGUI = {}

-- 私有属性
local _private = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
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
    playerInfoEnabled = false,
    playerInfoFrame = nil,
    excludedMenus = {
        ["设置"] = true,
        ["显示功能状态"] = true,
        ["显示玩家信息"] = true
    },
    -- 默认自定义配置（用户可在init时覆盖）
    customConfig = {
        primaryColor = Color3.fromRGB(255, 105, 180),  -- 粉色
        secondaryColor = Color3.fromRGB(135, 206, 250),  -- 天蓝色
        backgroundColor = Color3.fromRGB(30, 30, 40),
        textFont = Enum.Font.GothamBold,
        textSizeBase = 16,
        menuWidth = 120,
        buttonHeight = 28,
        notificationDuration = 2,
        longPressThreshold = 0.5,  -- 长按阈值，可自定义
        enableShadows = true,  -- 是否启用UI阴影
        gradientSpeed = 0.5,  -- 渐变动画速度
        sliderMin = 0,  -- 默认滑条最小值
        sliderMax = 100,  -- 默认滑条最大值
        sliderStep = 1,  -- 默认滑条步长
        -- 新增拖动配置
        dragMode = "longPress", -- "longPress" 或 "immediate"
        dragThreshold = 10, -- 开始拖动的像素阈值
    },
    -- 拖动状态管理
    dragStates = {},
}

-- 生成唯一ID
local function generateUID()
    return _private.HttpService:GenerateGUID(false):gsub("-", "")
end

-- 初始化库，支持自定义配置
function APbeGUI.init(customOptions)
    _private.player = _private.Players.LocalPlayer
    _private.playerGui = _private.player:WaitForChild("PlayerGui")
    
    -- 创建主ScreenGui
    if not _private.screenGui then
        _private.screenGui = Instance.new("ScreenGui")
        _private.screenGui.Name = "APbeGUI"
        _private.screenGui.ResetOnSpawn = false
        _private.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        _private.screenGui.Parent = _private.playerGui
    end
    
    -- 应用自定义配置
    if customOptions then
        for key, value in pairs(customOptions) do
            _private.customConfig[key] = value
        end
    end
    
    return APbeGUI
end

-- 粉蓝渐变色配置（支持自定义颜色）
function APbeGUI.createPinkBlueGradientEffect(frame)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, _private.customConfig.primaryColor),
        ColorSequenceKeypoint.new(0.3, _private.customConfig.primaryColor:lerp(Color3.fromRGB(255, 255, 255), 0.3)),
        ColorSequenceKeypoint.new(0.7, _private.customConfig.secondaryColor:lerp(Color3.fromRGB(255, 255, 255), 0.3)),
        ColorSequenceKeypoint.new(1, _private.customConfig.secondaryColor)
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- 创建缓慢旋转动画
    local rotationTween = _private.TweenService:Create(
        gradient,
        TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 405}
    )
    rotationTween:Play()
    
    return gradient
end

-- 创建粉蓝渐变边框效果（优化性能，使用Tween代替Heartbeat）
function APbeGUI.createPinkBlueStrokeEffect(stroke)
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local colorTween = _private.TweenService:Create(stroke, tweenInfo, {
        Color = _private.customConfig.secondaryColor
    })
    colorTween:Play()
    
    local transparencyTween = _private.TweenService:Create(stroke, tweenInfo, {
        Transparency = 0.5
    })
    transparencyTween:Play()
    
    return {colorTween, transparencyTween}
end

-- 创建玩家信息显示（添加自定义字体和颜色）
function APbeGUI.createPlayerInfoDisplay()
    if _private.playerInfoFrame then
        _private.playerInfoFrame:Destroy()
        _private.playerInfoFrame = nil
    end
    
    if not _private.playerInfoEnabled then
        return
    end
    
    _private.playerInfoFrame = Instance.new("Frame")
    _private.playerInfoFrame.Name = "PlayerInfoDisplay"
    _private.playerInfoFrame.Size = UDim2.new(0, 300, 0, 100)
    _private.playerInfoFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    _private.playerInfoFrame.BackgroundTransparency = 1
    _private.playerInfoFrame.BorderSizePixel = 0
    _private.playerInfoFrame.ZIndex = 1
    _private.playerInfoFrame.Parent = _private.screenGui
    
    -- 脚本名称文本
    local scriptNameLabel = Instance.new("TextLabel")
    scriptNameLabel.Name = "ScriptName"
    scriptNameLabel.Size = UDim2.new(1, 0, 0, 40)
    scriptNameLabel.Position = UDim2.new(0, 0, 0, 0)
    scriptNameLabel.BackgroundTransparency = 1
    scriptNameLabel.Text = "脚本用户"
    scriptNameLabel.TextColor3 = _private.customConfig.primaryColor
    scriptNameLabel.TextTransparency = 0.7
    scriptNameLabel.TextSize = 35
    scriptNameLabel.Font = _private.customConfig.textFont
    scriptNameLabel.TextStrokeTransparency = 0.8
    scriptNameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    scriptNameLabel.Parent = _private.playerInfoFrame
    
    -- 玩家名称文本
    local playerNameLabel = Instance.new("TextLabel")
    playerNameLabel.Name = "PlayerName"
    playerNameLabel.Size = UDim2.new(1, 0, 0, 40)
    playerNameLabel.Position = UDim2.new(0, 0, 0, 45)
    playerNameLabel.BackgroundTransparency = 1
    playerNameLabel.Text = _private.player.Name
    playerNameLabel.TextColor3 = _private.customConfig.primaryColor
    playerNameLabel.TextTransparency = 0.7
    playerNameLabel.TextSize = 35
    playerNameLabel.Font = _private.customConfig.textFont
    playerNameLabel.TextStrokeTransparency = 0.8
    playerNameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    playerNameLabel.Parent = _private.playerInfoFrame
    
    -- 淡入动画
    scriptNameLabel.TextTransparency = 1
    playerNameLabel.TextTransparency = 1
    
    local scriptFadeIn = _private.TweenService:Create(
        scriptNameLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0.7}
    )
    
    local playerFadeIn = _private.TweenService:Create(
        playerNameLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0.7}
    )
    
    scriptFadeIn:Play()
    playerFadeIn:Play()
end

-- 切换玩家信息显示
function APbeGUI.togglePlayerInfoDisplay(enabled)
    _private.playerInfoEnabled = enabled
    APbeGUI.createPlayerInfoDisplay()
end

-- 创建功能状态显示容器
function APbeGUI.createFeatureStatusContainer()
    _private.featureStatusContainer = Instance.new("Frame")
    _private.featureStatusContainer.Name = "FeatureStatusContainer"
    _private.featureStatusContainer.Size = UDim2.new(0, 200, 0, 0)
    _private.featureStatusContainer.Position = UDim2.new(1, -220, 0, 20)
    _private.featureStatusContainer.BackgroundTransparency = 1
    _private.featureStatusContainer.BorderSizePixel = 0
    _private.featureStatusContainer.ClipsDescendants = false
    _private.featureStatusContainer.Visible = _private.showFeatureStatus
    _private.featureStatusContainer.Parent = _private.screenGui
    
    -- 添加自动布局
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.Parent = _private.featureStatusContainer
    
    -- 监听子项变化以更新最后一个项的圆角
    local function updateFeatureStatusCorners()
        if not _private.featureStatusContainer then return end
        
        local children = _private.featureStatusContainer:GetChildren()
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
    
    _private.featureStatusContainer.ChildAdded:Connect(updateFeatureStatusCorners)
    _private.featureStatusContainer.ChildRemoved:Connect(updateFeatureStatusCorners)
    
    return _private.featureStatusContainer
end

-- 创建简化的渐变文字效果（优化为Tween动画，减少Heartbeat使用）
function APbeGUI.createSimpleGradientTextEffect(textLabel, featureName)
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    local hueShift = _private.TweenService:Create(textLabel, tweenInfo, {TextColor3 = _private.customConfig.secondaryColor})
    hueShift:Play()
    
    return hueShift
end

-- 添加功能状态显示项
function APbeGUI.addFeatureStatusItem(featureName)
    if not _private.showFeatureStatus or not _private.featureStatusContainer or _private.excludedMenus[featureName] then
        return nil
    end
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status_" .. featureName
    statusText.Size = UDim2.new(0, 150, 0, 18)
    statusText.BackgroundTransparency = 1
    statusText.BorderSizePixel = 0
    statusText.Text = featureName
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextSize = 16
    statusText.Font = _private.customConfig.textFont
    statusText.TextXAlignment = Enum.TextXAlignment.Right
    statusText.TextStrokeTransparency = 0.5
    statusText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusText.Parent = _private.featureStatusContainer
    
    -- 启动渐变文字效果
    local gradientConnection = APbeGUI.createSimpleGradientTextEffect(statusText, featureName)
    
    -- 滑入动画
    statusText.Position = UDim2.new(0, 200, 0, 0)
    local slideInTween = _private.TweenService:Create(
        statusText,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    slideInTween:Play()
    
    -- 存储连接
    statusText:SetAttribute("GradientConnection", gradientConnection)
    
    APbeGUI.updateFeatureStatusContainerSize()
    
    return statusText
end

-- 移除功能状态显示项
function APbeGUI.removeFeatureStatusItem(featureName)
    if not _private.featureStatusContainer then
        return
    end
    
    local statusText = _private.featureStatusContainer:FindFirstChild("Status_" .. featureName)
    if statusText then
        local gradientConnection = statusText:GetAttribute("GradientConnection")
        if gradientConnection then
            gradientConnection:Cancel()
        end
        
        local slideOutTween = _private.TweenService:Create(
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
            APbeGUI.updateFeatureStatusContainerSize()
        end)
    end
end

-- 更新功能状态容器大小
function APbeGUI.updateFeatureStatusContainerSize()
    if not _private.featureStatusContainer then
        return
    end
    
    local childCount = #_private.featureStatusContainer:GetChildren() - 1
    local newHeight = math.max(0, childCount * 23 - 5)
    
    local sizeTween = _private.TweenService:Create(
        _private.featureStatusContainer,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 200, 0, newHeight)}
    )
    sizeTween:Play()
end

-- 切换功能状态显示
function APbeGUI.toggleFeatureStatusDisplay(enabled)
    _private.showFeatureStatus = enabled
    
    if _private.featureStatusContainer then
        _private.featureStatusContainer.Visible = enabled
        
        if enabled then
            for featureName, _ in pairs(_private.activeFeatures) do
                if not _private.featureStatusContainer:FindFirstChild("Status_" .. featureName) and not _private.excludedMenus[featureName] then
                    APbeGUI.addFeatureStatusItem(featureName)
                end
            end
        end
        APbeGUI.updateFeatureStatusContainerSize()
    elseif enabled then
        APbeGUI.createFeatureStatusContainer()
        for featureName, _ in pairs(_private.activeFeatures) do
            if not _private.excludedMenus[featureName] then
                APbeGUI.addFeatureStatusItem(featureName)
            end
        end
        APbeGUI.updateFeatureStatusContainerSize()
    end
end

-- 更新功能状态
function APbeGUI.updateFeatureStatus(featureName, isActive)
    if isActive then
        _private.activeFeatures[featureName] = true
        if _private.showFeatureStatus and not _private.excludedMenus[featureName] then
            APbeGUI.addFeatureStatusItem(featureName)
            APbeGUI.updateFeatureStatusContainerSize()
        end
    else
        _private.activeFeatures[featureName] = nil
        APbeGUI.removeFeatureStatusItem(featureName)
        APbeGUI.updateFeatureStatusContainerSize()
    end
end

-- 显示通知（使用队列处理，避免重叠，支持自定义持续时间）
function APbeGUI.showNotification(title, message, isEnabled)
    table.insert(_private.notificationQueue, {title = title, message = message, isEnabled = isEnabled})
    
    if #_private.notificationQueue == 1 then
        APbeGUI.processNotificationQueue()
    end
end

function APbeGUI.processNotificationQueue()
    while #_private.notificationQueue > 0 do
        local notifData = _private.notificationQueue[1]
        local title, message, isEnabled = notifData.title, notifData.message, notifData.isEnabled
        
        local notification = Instance.new("Frame")
        notification.Name = "Notification"
        notification.Size = UDim2.new(0, 180, 0, 45)
        notification.BackgroundColor3 = _private.customConfig.backgroundColor
        notification.BackgroundTransparency = 0.1
        notification.BorderSizePixel = 0
        notification.ClipsDescendants = false
        notification.ZIndex = 10
        notification.Parent = _private.screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = notification
        
        APbeGUI.createPinkBlueGradientEffect(notification)
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Transparency = 0.2
        stroke.Parent = notification
        
        local strokeConnections = APbeGUI.createPinkBlueStrokeEffect(stroke)
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -15, 0, 16)
        titleLabel.Position = UDim2.new(0, 8, 0, 3)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 11
        titleLabel.Font = _private.customConfig.textFont
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextStrokeTransparency = 0.7
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.Parent = notification
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "Message"
        messageLabel.Size = UDim2.new(1, -15, 0, 13)
        messageLabel.Position = UDim2.new(0, 8, 0, 20)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = isEnabled and _private.customConfig.secondaryColor or _private.customConfig.primaryColor
        messageLabel.TextSize = 9
        messageLabel.Font = _private.customConfig.textFont
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextStrokeTransparency = 0.8
        messageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        messageLabel.Parent = notification
        
        local statusIndicator = Instance.new("Frame")
        statusIndicator.Name = "StatusIndicator"
        statusIndicator.Size = UDim2.new(0, 6, 0, 6)
        statusIndicator.Position = UDim2.new(1, -12, 0, 6)
        statusIndicator.BackgroundColor3 = isEnabled and _private.customConfig.secondaryColor or _private.customConfig.primaryColor
        statusIndicator.BorderSizePixel = 0
        statusIndicator.Parent = notification
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 3)
        indicatorCorner.Parent = statusIndicator
        
        local screenSize = workspace.CurrentCamera.ViewportSize
        notification.Position = UDim2.new(0, screenSize.X, 1, -60 - (#_private.activeNotifications * 50))
        
        table.insert(_private.activeNotifications, notification)
        
        local appearDelay = #_private.activeNotifications * 0.2
        task.wait(appearDelay)
        
        local slideInTween = _private.TweenService:Create(
            notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -190, 1, -60 - ((#_private.activeNotifications - 1) * 50))}
        )
        
        slideInTween:Play()
        
        task.wait(_private.customConfig.notificationDuration)
        
        local slideOutTween = _private.TweenService:Create(
            notification,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 50, 1, -60 - ((#_private.activeNotifications - 1) * 50))}
        )
        
        slideOutTween:Play()
        
        slideOutTween.Completed:Connect(function()
            for _, conn in ipairs(strokeConnections) do
                conn:Cancel()
            end
            
            for i, notif in ipairs(_private.activeNotifications) do
                if notif == notification then
                    table.remove(_private.activeNotifications, i)
                    break
                end
            end
            
            notification:Destroy()
            
            for i, notif in ipairs(_private.activeNotifications) do
                local repositionTween = _private.TweenService:Create(
                    notif,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = UDim2.new(1, -190, 1, -60 - ((i - 1) * 50))}
                )
                repositionTween:Play()
            end
        end)
        
        table.remove(_private.notificationQueue, 1)
    end
end

-- 新增：创建通用滑条组件
function APbeGUI.createSlider(parent, labelText, minValue, maxValue, step, defaultValue, callback)
    minValue = minValue or _private.customConfig.sliderMin
    maxValue = maxValue or _private.customConfig.sliderMax
    step = step or _private.customConfig.sliderStep
    defaultValue = defaultValue or minValue
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 20)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = labelText
    sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderLabel.TextSize = 12
    sliderLabel.Font = _private.customConfig.textFont
    sliderLabel.Parent = parent
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.Position = UDim2.new(0, 10, 0, 25)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sliderTrack.BorderSizePixel = 0
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderTrack
    sliderTrack.Parent = parent
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 12, 0, 12)
    sliderKnob.Position = UDim2.new(0, 0, 0.5, -3)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 6)
    knobCorner.Parent = sliderKnob
    sliderKnob.Parent = sliderTrack
    
    local sliderValue = Instance.new("TextLabel")
    sliderValue.Size = UDim2.new(0, 30, 0, 15)
    sliderValue.Position = UDim2.new(0.5, -15, -1, -5)
    sliderValue.BackgroundTransparency = 1
    sliderValue.Text = tostring(defaultValue)
    sliderValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderValue.TextSize = 10
    sliderValue.Parent = sliderKnob
    
    local currentValue = defaultValue
    local dragging = false
    
    local function updateSlider(relativePos)
        local value = math.floor((minValue + (maxValue - minValue) * relativePos) / step) * step
        value = math.clamp(value, minValue, maxValue)
        currentValue = value
        sliderValue.Text = tostring(currentValue)
        if callback then
            callback(currentValue)
        end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local trackAbsPos = sliderTrack.AbsolutePosition.X
            local trackAbsSize = sliderTrack.AbsoluteSize.X
            local mouseX = input.Position.X
            local relativePos = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            sliderKnob.Position = UDim2.new(relativePos, 0, 0.5, -3)
            updateSlider(relativePos)
        end
    end)
    
    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    _private.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackAbsPos = sliderTrack.AbsolutePosition.X
            local trackAbsSize = sliderTrack.AbsoluteSize.X
            local mouseX = input.Position.X
            local relativePos = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            sliderKnob.Position = UDim2.new(relativePos, 0, 0.5, -3)
            updateSlider(relativePos)
        end
    end)
    
    -- 设置默认位置
    local defaultPos = (defaultValue - minValue) / (maxValue - minValue)
    sliderKnob.Position = UDim2.new(defaultPos, 0, 0.5, -3)
    
    return sliderTrack
end

-- 新增：创建通用文本输入组件
function APbeGUI.createTextBox(parent, labelText, defaultText, isNumeric, callback)
    defaultText = defaultText or ""
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 20)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = labelText
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 12
    textLabel.Font = _private.customConfig.textFont
    textLabel.Parent = parent
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, 25)
    textBox.Position = UDim2.new(0, 10, 0, 25)
    textBox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    textBox.BorderSizePixel = 0
    textBox.Text = defaultText
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 14
    textBox.Font = _private.customConfig.textFont
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = textBox
    textBox.Parent = parent
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local input = textBox.Text
            if isNumeric then
                local num = tonumber(input)
                if num then
                    if callback then
                        callback(num)
                    end
                else
                    textBox.Text = defaultText  -- 无效输入恢复默认
                end
            else
                if callback then
                    callback(input)
                end
            end
        end
    end)
    
    return textBox
end

-- 改进版拖动系统
local function setupDragSystem(uiElement, dragHeader)
    local dragId = generateUID()
    local dragState = {
        isDragging = false,
        dragStart = Vector2.new(0, 0),
        startPos = UDim2.new(0, 0, 0, 0),
        element = uiElement,
        header = dragHeader
    }
    
    _private.dragStates[dragId] = dragState
    
    local function startDrag(input)
        dragState.isDragging = true
        dragState.dragStart = input.Position
        dragState.startPos = uiElement.Position
        
        -- 将元素置于最前
        uiElement.ZIndex = 100
    end
    
    local function updateDrag(input)
        if not dragState.isDragging then return end
        
        local delta = input.Position - dragState.dragStart
        uiElement.Position = UDim2.new(
            dragState.startPos.X.Scale, 
            dragState.startPos.X.Offset + delta.X, 
            dragState.startPos.Y.Scale, 
            dragState.startPos.Y.Offset + delta.Y
        )
    end
    
    local function stopDrag()
        dragState.isDragging = false
        -- 恢复原来的ZIndex
        uiElement.ZIndex = 5
    end
    
    -- 根据配置选择拖动模式
    if _private.customConfig.dragMode == "longPress" then
        -- 长按拖动模式
        local pressStartTime
        local longPressConnection
        
        dragHeader.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                pressStartTime = tick()
                longPressConnection = _private.RunService.Heartbeat:Connect(function()
                    if tick() - pressStartTime >= _private.customConfig.longPressThreshold then
                        if longPressConnection then
                            longPressConnection:Disconnect()
                        end
                        startDrag(input)
                    end
                end)
            end
        end)
        
        dragHeader.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if longPressConnection then
                    longPressConnection:Disconnect()
                end
                local pressDuration = tick() - pressStartTime
                if pressDuration < _private.customConfig.longPressThreshold then
                    -- 短按处理（如果有其他功能）
                else
                    -- 长按后松开，停止拖动
                    stopDrag()
                end
            end
        end)
        
        _private.UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                updateDrag(input)
            end
        end)
    else
        -- 立即拖动模式
        dragHeader.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                startDrag(input)
            end
        end)
        
        dragHeader.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                stopDrag()
            end
        end)
        
        _private.UserInputService.InputChanged:Connect(function(input)
            if dragState.isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateDrag(input)
            end
        end)
    end
    
    -- 全局鼠标释放监听（防止鼠标移出UI后无法释放）
    local globalReleaseConnection
    globalReleaseConnection = _private.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragState.isDragging then
                stopDrag()
            end
        end
    end)
    
    -- 存储连接以便清理
    uiElement:SetAttribute("DragId", dragId)
    uiElement:SetAttribute("ReleaseConnection", globalReleaseConnection)
    
    return dragId
end

-- 创建细节调整窗口（集成通用滑条和文本输入）
function APbeGUI.createDetailWindow(title, parentButton, onValueChange)
    local detailFrame = Instance.new("Frame")
    detailFrame.Name = title .. "Detail"
    detailFrame.Size = UDim2.new(0, 250, 0, 200)  -- 增加高度以容纳更多组件
    detailFrame.BackgroundColor3 = _private.customConfig.backgroundColor
    detailFrame.BackgroundTransparency = 0.1
    detailFrame.BorderSizePixel = 0
    detailFrame.ClipsDescendants = true
    detailFrame.ZIndex = 7
    detailFrame.Parent = _private.screenGui
    
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 6)
    detailCorner.Parent = detailFrame
    
    APbeGUI.createPinkBlueGradientEffect(detailFrame)
    
    local detailStroke = Instance.new("UIStroke")
    detailStroke.Thickness = 2
    detailStroke.Transparency = 0.3
    detailStroke.Parent = detailFrame
    
    APbeGUI.createPinkBlueStrokeEffect(detailStroke)
    
    if _private.customConfig.enableShadows then
        local shadow = Instance.new("UIStroke")
        shadow.Thickness = 3
        shadow.Color = Color3.fromRGB(0, 0, 0)
        shadow.Transparency = 0.5
        shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        shadow.Parent = detailFrame
    end
    
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Text = title .. " 设置"
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = _private.customConfig.textSizeBase
    header.Font = _private.customConfig.textFont
    header.TextStrokeTransparency = 0.7
    header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    header.Parent = detailFrame
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -30)
    contentFrame.Position = UDim2.new(0, 0, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = detailFrame
    
    -- 使用通用滑条
    APbeGUI.createSlider(contentFrame, "速度调整", 1, 10, 0.1, 1, function(value)
        if onValueChange then
            onValueChange("speed", value)
        end
    end)
    
    -- 使用通用文本输入（数值型）
    APbeGUI.createTextBox(contentFrame, "自定义数值", "0", true, function(value)
        if onValueChange then
            onValueChange("customValue", value)
        end
    end)
    
    -- 使用通用文本输入（文本型）
    APbeGUI.createTextBox(contentFrame, "自定义文本", "输入文本", false, function(text)
        if onValueChange then
            onValueChange("customText", text)
        end
    end)
    
    -- 自动跳跃开关（经典开关样式）
    local switchLabel = Instance.new("TextLabel")
    switchLabel.Size = UDim2.new(1, 0, 0, 20)
    switchLabel.Position = UDim2.new(0, 0, 0, 130)  -- 调整位置
    switchLabel.BackgroundTransparency = 1
    switchLabel.Text = "自动跳跃"
    switchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    switchLabel.TextSize = 12
    switchLabel.Font = _private.customConfig.textFont
    switchLabel.Parent = contentFrame
    
    local switchFrame = Instance.new("Frame")
    switchFrame.Size = UDim2.new(0, 40, 0, 20)
    switchFrame.Position = UDim2.new(1, -50, 0, 130)
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
            local tween = _private.TweenService:Create(switchKnob, TweenInfo.new(0.2), {Position = targetPos})
            tween:Play()
            switchFrame.BackgroundColor3 = autoJumpEnabled and _private.customConfig.secondaryColor or Color3.fromRGB(100, 100, 100)
            if onValueChange then
                onValueChange("autoJump", autoJumpEnabled)
            end
        end
    end)
    
    -- 使用改进的拖动系统
    setupDragSystem(detailFrame, header)
    
    local parentButtonPos = parentButton.AbsolutePosition
    local parentButtonSize = parentButton.AbsoluteSize
    detailFrame.Position = UDim2.new(
        0, parentButtonPos.X + parentButtonSize.X + 5,
        0, parentButtonPos.Y
    )
    
    detailFrame.BackgroundTransparency = 1
    header.TextTransparency = 1
    
    local fadeIn = _private.TweenService:Create(
        detailFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.1}
    )
    
    local textFadeIn = _private.TweenService:Create(
        header,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    detailFrame.Visible = true
    _private.detailStates[title] = true
    
    return detailFrame
end

-- 创建浮动菜单（使用改进的拖动系统）
function APbeGUI.createFloatingMenu(title, options, isSubMenu, parentMenuButton)
    if isSubMenu and _private.subMenus[title] then
        local menu = _private.subMenus[title]
        local isCurrentlyVisible = menu.Visible
        
        if not isCurrentlyVisible then
            menu.Visible = true
            menu.BackgroundTransparency = 1
            menu.Header.TextTransparency = 1
            
            local fadeIn = _private.TweenService:Create(
                menu,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0.1}
            )
            
            local textFadeIn = _private.TweenService:Create(
                menu.Header,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextTransparency = 0}
            )
            
            fadeIn:Play()
            textFadeIn:Play()
        else
            local fadeOut = _private.TweenService:Create(
                menu,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            
            local textFadeOut = _private.TweenService:Create(
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
        
        _private.subMenuStates[title] = not isCurrentlyVisible
        
        if parentMenuButton then
            if not isCurrentlyVisible then
                parentMenuButton.BackgroundColor3 = _private.customConfig.secondaryColor
                parentMenuButton.BackgroundTransparency = 0.2
            else
                parentMenuButton.BackgroundColor3 = _private.customConfig.backgroundColor:lerp(Color3.fromRGB(0, 0, 0), 0.2)
                parentMenuButton.BackgroundTransparency = 0.3
            end
        end
        
        return menu
    end
    
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = title .. "Menu"
    menuFrame.Size = UDim2.new(0, _private.customConfig.menuWidth, 0, 30)
    menuFrame.BackgroundColor3 = _private.customConfig.backgroundColor
    menuFrame.BackgroundTransparency = 0.1
    menuFrame.BorderSizePixel = 0
    menuFrame.ClipsDescendants = true
    menuFrame.ZIndex = 5
    menuFrame.Parent = _private.screenGui
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = menuFrame
    
    APbeGUI.createPinkBlueGradientEffect(menuFrame)
    
    local menuStroke = Instance.new("UIStroke")
    menuStroke.Thickness = 2
    menuStroke.Transparency = 0.3
    menuStroke.Parent = menuFrame
    
    APbeGUI.createPinkBlueStrokeEffect(menuStroke)
    
    if _private.customConfig.enableShadows then
        local shadow = Instance.new("UIStroke")
        shadow.Thickness = 3
        shadow.Color = Color3.fromRGB(0, 0, 0)
        shadow.Transparency = 0.5
        shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        shadow.Parent = menuFrame
    end
    
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Text = title
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = _private.customConfig.textSizeBase
    header.Font = _private.customConfig.textFont
    header.TextStrokeTransparency = 0.7
    header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    header.Parent = menuFrame
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.Position = UDim2.new(0, 0, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = menuFrame
    
    local optionButtons = {}
    local isExpanded = false
    
    for i, option in ipairs(options) do
        local button = Instance.new("TextButton")
        button.Name = option.Name
        button.Size = UDim2.new(1, 0, 0, _private.customConfig.buttonHeight)
        button.Position = UDim2.new(0, 0, 0, (i-1)*_private.customConfig.buttonHeight)
        button.BackgroundColor3 = _private.customConfig.backgroundColor:lerp(Color3.fromRGB(0, 0, 0), 0.2)
        button.BackgroundTransparency = 0.3
        button.BorderSizePixel = 0
        button.Text = option.HasDetails and option.Name .. " •" or option.Name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = _private.customConfig.textSizeBase - 2
        button.Font = _private.customConfig.textFont
        button.TextStrokeTransparency = 0.8
        button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        button.TextXAlignment = Enum.TextXAlignment.Center
        button.ZIndex = 6
        button.Parent = contentFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 0)
        buttonCorner.Parent = button
        
        if option.Type == "submenu" then
            if _private.subMenuStates[option.Name] == nil then
                _private.subMenuStates[option.Name] = false
            end
            if _private.subMenuStates[option.Name] then
                button.BackgroundColor3 = _private.customConfig.secondaryColor
                button.BackgroundTransparency = 0.2
            end
        end
        
        button.MouseEnter:Connect(function()
            if option.Type == "toggle" then
                if not option.Active then
                    button.BackgroundColor3 = _private.customConfig.primaryColor:lerp(Color3.fromRGB(255, 255, 255), 0.5)
                    button.BackgroundTransparency = 0.3
                end
            elseif option.Type == "submenu" then
                if not _private.subMenuStates[option.Name] then
                    button.BackgroundColor3 = _private.customConfig.secondaryColor:lerp(Color3.fromRGB(255, 255, 255), 0.5)
                    button.BackgroundTransparency = 0.3
                end
            end
        end)
        
        button.MouseLeave:Connect(function()
            if option.Type == "toggle" then
                if not option.Active then
                    button.BackgroundColor3 = _private.customConfig.backgroundColor:lerp(Color3.fromRGB(0, 0, 0), 0.2)
                    button.BackgroundTransparency = 0.3
                end
            elseif option.Type == "submenu" then
                if not _private.subMenuStates[option.Name] then
                    button.BackgroundColor3 = _private.customConfig.backgroundColor:lerp(Color3.fromRGB(0, 0, 0), 0.2)
                    button.BackgroundTransparency = 0.3
                end
            end
        end)
        
        -- 长按检测（使用RunService确保准确计时）
        local pressStartTime
        local longPressConnection
        
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                pressStartTime = tick()
                if option.HasDetails then
                    longPressConnection = _private.RunService.Heartbeat:Connect(function()
                        if tick() - pressStartTime >= _private.customConfig.longPressThreshold then
                            if longPressConnection then
                                longPressConnection:Disconnect()
                            end
                            local detailTitle = option.Name
                            if _private.detailWindows[detailTitle] then
                                local window = _private.detailWindows[detailTitle]
                                local isCurrentlyVisible = window.Visible
                                
                                if not isCurrentlyVisible then
                                    window.Visible = true
                                    window.BackgroundTransparency = 1
                                    window.Header.TextTransparency = 1
                                    
                                    local fadeIn = _private.TweenService:Create(
                                        window,
                                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                        {BackgroundTransparency = 0.1}
                                    )
                                    
                                    local textFadeIn = _private.TweenService:Create(
                                        window.Header,
                                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                        {TextTransparency = 0}
                                    )
                                    
                                    fadeIn:Play()
                                    textFadeIn:Play()
                                else
                                    local fadeOut = _private.TweenService:Create(
                                        window,
                                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                        {BackgroundTransparency = 1}
                                    )
                                    
                                    local textFadeOut = _private.TweenService:Create(
                                        window.Header,
                                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                        {TextTransparency = 1}
                                    )
                                    
                                    fadeOut:Play()
                                    textFadeOut:Play()
                                    
                                    fadeOut.Completed:Connect(function()
                                        window.Visible = false
                                    end)
                                end
                                
                                _private.detailStates[detailTitle] = not isCurrentlyVisible
                            else
                                local newWindow = APbeGUI.createDetailWindow(detailTitle, button, option.DetailCallback)
                                _private.detailWindows[detailTitle] = newWindow
                            end
                        end
                    end)
                end
            end
        end)
        
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if longPressConnection then
                    longPressConnection:Disconnect()
                end
                local pressDuration = tick() - pressStartTime
                if pressDuration < _private.customConfig.longPressThreshold then
                    if option.Type == "toggle" then
                        option.Active = not option.Active
                        
                        if option.Active then
                            button.BackgroundColor3 = _private.customConfig.secondaryColor
                            button.BackgroundTransparency = 0.2
                        else
                            button.BackgroundColor3 = _private.customConfig.backgroundColor:lerp(Color3.fromRGB(0, 0, 0), 0.2)
                            button.BackgroundTransparency = 0.3
                        end
                        
                        task.spawn(function()
                            APbeGUI.showNotification(
                                option.Name,
                                option.Active and "功能已开启" or "功能已关闭",
                                option.Active
                            )
                        end)
                        
                        if isSubMenu then
                            APbeGUI.updateFeatureStatus(option.Name, option.Active)
                        end
                        
                        if option.Callback then
                            option.Callback(option.Active)
                        end
                    elseif option.Type == "submenu" then
                        if _private.subMenus[option.Name] then
                            local menu = _private.subMenus[option.Name]
                            local isCurrentlyVisible = menu.Visible
                            
                            if not isCurrentlyVisible then
                                menu.Visible = true
                                menu.BackgroundTransparency = 1
                                menu.Header.TextTransparency = 1
                                
                                local fadeIn = _private.TweenService:Create(
                                    menu,
                                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    {BackgroundTransparency = 0.1}
                                )
                                
                                local textFadeIn = _private.TweenService:Create(
                                    menu.Header,
                                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    {TextTransparency = 0}
                                )
                                
                                fadeIn:Play()
                                textFadeIn:Play()
                            else
                                local fadeOut = _private.TweenService:Create(
                                    menu,
                                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    {BackgroundTransparency = 1}
                                )
                                
                                local textFadeOut = _private.TweenService:Create(
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
                            
                            _private.subMenuStates[option.Name] = not isCurrentlyVisible
                            
                            if not isCurrentlyVisible then
                                button.BackgroundColor3 = _private.customConfig.secondaryColor
                                button.BackgroundTransparency = 0.2
                            else
                                button.BackgroundColor3 = _private.customConfig.backgroundColor:lerp(Color3.fromRGB(0, 0, 0), 0.2)
                                button.BackgroundTransparency = 0.3
                            end
                        else
                            if option.SubMenu then
                                local parentButtonPos = button.AbsolutePosition
                                local parentButtonSize = button.AbsoluteSize
                                
                                local subMenu = APbeGUI.createFloatingMenu(option.Name, option.SubMenu, true, button)
                                
                                subMenu.Position = UDim2.new(
                                    0, parentButtonPos.X + parentButtonSize.X + 5,
                                    0, parentButtonPos.Y
                                )
                                
                                subMenu.BackgroundTransparency = 1
                                subMenu.Header.TextTransparency = 1
                                
                                local fadeIn = _private.TweenService:Create(
                                    subMenu,
                                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    {BackgroundTransparency = 0.1}
                                )
                                
                                local textFadeIn = _private.TweenService:Create(
                                    subMenu.Header,
                                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                    {TextTransparency = 0}
                                )
                                
                                fadeIn:Play()
                                textFadeIn:Play()
                                
                                subMenu.Visible = true
                                _private.subMenuStates[option.Name] = true
                            end
                        end
                        
                        task.spawn(function()
                            APbeGUI.showNotification(
                                option.Name .. " 菜单",
                                _private.subMenuStates[option.Name] and "已打开" or "已关闭",
                                _private.subMenuStates[option.Name]
                            )
                        end)
                    end
                end
            end
        end)
        
        table.insert(optionButtons, button)
    end
    
    local function toggleMenu()
        isExpanded = not isExpanded
        
        local targetSize, targetContentSize
        if isExpanded then
            targetSize = UDim2.new(0, _private.customConfig.menuWidth, 0, 30 + #options * _private.customConfig.buttonHeight)
            targetContentSize = UDim2.new(1, 0, 0, #options * _private.customConfig.buttonHeight)
        else
            targetSize = UDim2.new(0, _private.customConfig.menuWidth, 0, 30)
            targetContentSize = UDim2.new(1, 0, 0, 0)
        end
        
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local sizeTween = _private.TweenService:Create(menuFrame, tweenInfo, {Size = targetSize})
        local contentTween = _private.TweenService:Create(contentFrame, tweenInfo, {Size = targetContentSize})
        
        sizeTween:Play()
        contentTween:Play()
    end
    
    header.MouseButton1Click:Connect(toggleMenu)
    
    -- 使用改进的拖动系统
    setupDragSystem(menuFrame, header)
    
    if isSubMenu then
        local centerX = (_private.screenGui.AbsoluteSize.X / 2) - (menuFrame.AbsoluteSize.X / 2)
        local centerY = (_private.screenGui.AbsoluteSize.Y / 2) - (menuFrame.AbsoluteSize.Y / 2)
        menuFrame.Position = UDim2.new(0, centerX, 0, centerY)
        _private.subMenus[title] = menuFrame
        
        menuFrame.BackgroundTransparency = 1
        menuFrame.Header.TextTransparency = 1
        
        local fadeIn = _private.TweenService:Create(
            menuFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.1}
        )
        
        local textFadeIn = _private.TweenService:Create(
            menuFrame.Header,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        
        fadeIn:Play()
        textFadeIn:Play()
        
        menuFrame.Visible = true
        _private.subMenuStates[title] = true
    else
        menuFrame.Position = UDim2.new(0, 15, 0, 15)
    end
    
    -- 适配移动设备
    if _private.UserInputService.TouchEnabled then
        menuFrame.Size = UDim2.new(0, _private.customConfig.menuWidth + 20, 0, 35)
        header.Size = UDim2.new(1, 0, 0, 35)
        header.TextSize = _private.customConfig.textSizeBase + 2
        
        for _, button in ipairs(optionButtons) do
            button.Size = UDim2.new(1, 0, 0, _private.customConfig.buttonHeight + 4)
            button.TextSize = _private.customConfig.textSizeBase
        end
    end
    
    return menuFrame
end

-- 重置库状态
function APbeGUI.reset()
    if _private.screenGui then
        _private.screenGui:Destroy()
        _private.screenGui = nil
    end
    
    -- 清理拖动状态
    for _, state in pairs(_private.dragStates) do
        if state.element and state.element:GetAttribute("ReleaseConnection") then
            local connection = state.element:GetAttribute("ReleaseConnection")
            if connection then
                connection:Disconnect()
            end
        end
    end
    
    _private.dragStates = {}
    _private.subMenus = {}
    _private.subMenuStates = {}
    _private.detailWindows = {}
    _private.detailStates = {}
    _private.notificationQueue = {}
    _private.activeNotifications = {}
    _private.activeFeatures = {}
    _private.featureStatusContainer = nil
    _private.showFeatureStatus = true
    _private.playerInfoEnabled = false
    _private.playerInfoFrame = nil
    
    return APbeGUI.init()
end

-- 获取当前状态
function APbeGUI.getState()
    return {
        activeFeatures = _private.activeFeatures,
        subMenuStates = _private.subMenuStates,
        detailStates = _private.detailStates,
        showFeatureStatus = _private.showFeatureStatus,
        playerInfoEnabled = _private.playerInfoEnabled
    }
end

return APbeGUI

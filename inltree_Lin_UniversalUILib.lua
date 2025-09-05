-- inltree_Lin_UniversalUILib.lua - inltree｜Lin×DeepSeek 通用UI库
-- 版本: 1.0.0
-- 提供简洁实用的Roblox UI组件

local inltree_Lin_UniversalUILib = {}

-- 私有属性
local _private = {
    Players = game:GetService("Players"),
    MarketplaceService = game:GetService("MarketplaceService"),
    StarterGui = game:GetService("StarterGui"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    player = nil,
    playerGui = nil,
    screenGui = nil,
    buttons = {},
    buttonStates = {},
    isHidden = false,
    dragging = false,
    dragInput = nil,
    dragStart = nil,
    startPositions = {},
    gameName = "",
    activeFunctions = {}, -- 存储活跃功能的回调函数
    onToggleChangeCallbacks = {} -- 存储状态改变回调
}

-- 初始化库
function inltree_Lin_UniversalUILib.init()
    _private.player = _private.Players.LocalPlayer
    _private.playerGui = _private.player:WaitForChild("PlayerGui")
    _private.gameName = _private.MarketplaceService:GetProductInfo(game.PlaceId).Name
    
    -- 创建主ScreenGui
    if not _private.screenGui then
        _private.screenGui = Instance.new("ScreenGui")
        _private.screenGui.Name = "inltree_Lin_UniversalUI"
        _private.screenGui.ResetOnSpawn = false
        _private.screenGui.Parent = _private.playerGui
    end
    
    -- 显示加载通知
    _private.StarterGui:SetCore("SendNotification", {
        Title = _private.gameName,
        Text = "inltree｜".._private.gameName.." Script Loading...｜加载中...",
        Duration = 3
    })
    
    return inltree_Lin_UniversalUILib
end

-- 按钮样式配置
function inltree_Lin_UniversalUILib.getButtonStyle()
    return {
        Size = UDim2.new(0, 120, 0, 30),
        BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
        BackgroundTransparency = 0.5,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BorderSizePixel = 1,
        BorderColor3 = Color3.new(0.8, 0.8, 0.8)
    }
end

-- 注册功能回调
function inltree_Lin_UniversalUILib.registerFunction(buttonName, enableCallback, disableCallback)
    _private.activeFunctions[buttonName] = {
        enable = enableCallback,
        disable = disableCallback
    }
    
    -- 如果按钮已经存在且状态为true，立即执行启用回调
    if _private.buttonStates[buttonName] == true and enableCallback then
        enableCallback()
    end
end

-- 添加状态改变回调
function inltree_Lin_UniversalUILib.onToggleChange(callback)
    table.insert(_private.onToggleChangeCallbacks, callback)
end

-- 触发所有状态改变回调
local function triggerToggleCallbacks(buttonName, state)
    for _, callback in ipairs(_private.onToggleChangeCallbacks) do
        pcall(callback, buttonName, state)
    end
end

-- 关闭所有活跃功能
function inltree_Lin_UniversalUILib.disableAllFunctions()
    print("🟡 正在关闭所有功能...")
    
    for buttonName, state in pairs(_private.buttonStates) do
        if state == true then
            -- 设置按钮状态为false
            _private.buttonStates[buttonName] = false
            if _private.buttons[buttonName] then
                _private.buttons[buttonName].Text = buttonName..": "..tostring(false)
                local defaultColor = Color3.new(0.8, 0.5, 1) -- 默认颜色，可以根据需要调整
                _private.buttons[buttonName].TextColor3 = defaultColor
            end
            
            -- 执行禁用回调
            if _private.activeFunctions[buttonName] and _private.activeFunctions[buttonName].disable then
                pcall(_private.activeFunctions[buttonName].disable)
                print("🔴 已关闭功能: "..buttonName)
            else
                print("🔴 已设置状态为关闭: "..buttonName)
            end
            
            -- 触发状态改变回调
            triggerToggleCallbacks(buttonName, false)
        end
    end
    
    print("🟢 所有功能已关闭")
end

-- 创建按钮
function inltree_Lin_UniversalUILib.createButton(name, position, color, callback)
    local buttonStyle = inltree_Lin_UniversalUILib.getButtonStyle()
    
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = buttonStyle.Size
    button.Position = position
    button.Text = name
    button.TextColor3 = color
    button.BackgroundColor3 = buttonStyle.BackgroundColor3
    button.BackgroundTransparency = buttonStyle.BackgroundTransparency
    button.Font = buttonStyle.Font
    button.TextSize = buttonStyle.TextSize
    button.BorderSizePixel = buttonStyle.BorderSizePixel
    button.BorderColor3 = buttonStyle.BorderColor3
    button.Parent = _private.screenGui
    
    if callback then
        button.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end
    
    -- 存储按钮引用
    _private.buttons[name] = button
    _private.startPositions[button] = position
    
    return button
end

-- 创建模板按钮
function inltree_Lin_UniversalUILib.createToggleButton(name, position, defaultColor, initialState)
    local button = inltree_Lin_UniversalUILib.createButton(name..": "..tostring(initialState or false), position, defaultColor)
    
    _private.buttonStates[name] = initialState or false
    
    button.MouseButton1Click:Connect(function()
        _private.buttonStates[name] = not _private.buttonStates[name]
        button.Text = name..": "..tostring(_private.buttonStates[name])
        button.TextColor3 = _private.buttonStates[name] and Color3.new(0, 1, 0) or defaultColor
        
        print("🟢 "..name..": "..tostring(_private.buttonStates[name]))
        
        -- 触发状态改变回调
        triggerToggleCallbacks(name, _private.buttonStates[name])
        
        -- 执行注册的功能回调
        if _private.activeFunctions[name] then
            if _private.buttonStates[name] and _private.activeFunctions[name].enable then
                pcall(_private.activeFunctions[name].enable)
            elseif not _private.buttonStates[name] and _private.activeFunctions[name].disable then
                pcall(_private.activeFunctions[name].disable)
            end
        end
    end)
    
    return button
end

-- 设置按钮状态
function inltree_Lin_UniversalUILib.setButtonState(name, state)
    if _private.buttons[name] and _private.buttonStates[name] ~= nil then
        _private.buttonStates[name] = state
        _private.buttons[name].Text = name..": "..tostring(state)
        _private.buttons[name].TextColor3 = state and Color3.new(0, 1, 0) or inltree_Lin_UniversalUILib.getButtonStyle().TextColor3
        
        -- 触发状态改变回调
        triggerToggleCallbacks(name, state)
        
        -- 执行注册的功能回调
        if _private.activeFunctions[name] then
            if state and _private.activeFunctions[name].enable then
                pcall(_private.activeFunctions[name].enable)
            elseif not state and _private.activeFunctions[name].disable then
                pcall(_private.activeFunctions[name].disable)
            end
        end
    end
end

-- 获取按钮状态
function inltree_Lin_UniversalUILib.getButtonState(name)
    return _private.buttonStates[name]
end

-- 初始化UI拖动功能
function inltree_Lin_UniversalUILib.initDrag()
    local function updatePos(input) 
        if not _private.dragStart then return end
        
        local delta = input.Position - _private.dragStart
        
        for button, startPos in pairs(_private.startPositions) do
            button.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end
    
    -- 设置拖动按钮（通常是隐藏/显示UI的按钮）
    if _private.buttons["隐藏UI"] then
        _private.buttons["隐藏UI"].InputBegan:Connect(function(input) 
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                _private.dragging = true 
                _private.dragStart = input.Position
                
                for name, button in pairs(_private.buttons) do
                    _private.startPositions[button] = button.Position
                end
                
                input.Changed:Connect(function() 
                    if input.UserInputState == Enum.UserInputState.End then 
                        _private.dragging = false 
                    end 
                end) 
            end 
        end)
        
        _private.buttons["隐藏UI"].InputChanged:Connect(function(input) 
            if _private.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                _private.dragInput = input 
            end 
        end)
    end
    
    _private.UserInputService.InputChanged:Connect(function(input) 
        if _private.dragging and input == _private.dragInput then 
            updatePos(input) 
        end 
    end)
end

-- 隐藏/显示UI
function inltree_Lin_UniversalUILib.toggleUI()
    _private.isHidden = not _private.isHidden
    for name, button in pairs(_private.buttons) do
        if name ~= "隐藏UI" then
            button.Visible = not _private.isHidden
        end
    end
    _private.buttons["隐藏UI"].Text = _private.isHidden and "显示UI" or "隐藏UI"
    print("🟢 isHidden: "..tostring(_private.isHidden))
end

-- 关闭UI
function inltree_Lin_UniversalUILib.closeUI()
    -- 先关闭所有功能
    inltree_Lin_UniversalUILib.disableAllFunctions()
    
    -- 等待一下确保所有功能都已关闭
    task.wait(0.1)
    
    -- 然后关闭UI面板
    if _private.screenGui then
        _private.screenGui:Destroy()
        _private.screenGui = nil
    end
    print("🔴 ".._private.gameName.." - screenGui: "..tostring(_private.screenGui == nil))
end

-- 打开控制台
function inltree_Lin_UniversalUILib.openConsole()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F9, false, game)
    print("🟢 Console opened: true")
end

-- 创建默认UI布局
function inltree_Lin_UniversalUILib.createDefaultUI()
    -- 创建隐藏UI按钮
    inltree_Lin_UniversalUILib.createButton("隐藏UI", UDim2.new(0, 10, 0, 10), Color3.new(1, 0.5, 0), function()
        inltree_Lin_UniversalUILib.toggleUI()
    end)
    
    -- 创建关闭UI按钮
    inltree_Lin_UniversalUILib.createButton("关闭UI", UDim2.new(0, 10, 0, 50), Color3.new(1, 0, 0), function()
        inltree_Lin_UniversalUILib.closeUI()
    end)
    
    -- 创建控制台按钮
    inltree_Lin_UniversalUILib.createButton("控制台", UDim2.new(0, 10, 0, 90), Color3.new(1, 1, 0.5), function()
        inltree_Lin_UniversalUILib.openConsole()
    end)
    
    -- 创建模板按钮
    inltree_Lin_UniversalUILib.createToggleButton("模板按钮一", UDim2.new(0, 140, 0, 10), Color3.new(0.8, 0.5, 1), false)
    inltree_Lin_UniversalUILib.createToggleButton("模板按钮二", UDim2.new(0, 140, 0, 50), Color3.new(1, 0.84, 0), false)
    inltree_Lin_UniversalUILib.createToggleButton("模板按钮三", UDim2.new(0, 140, 0, 90), Color3.new(1, 0.5, 0), false)
    inltree_Lin_UniversalUILib.createToggleButton("模板按钮四", UDim2.new(0, 140, 0, 130), Color3.new(0.5, 0.8, 1), false)
    
    -- 初始化拖动功能
    inltree_Lin_UniversalUILib.initDrag()
    
    -- 显示加载完成通知
    task.wait(0.5)
    _private.StarterGui:SetCore("SendNotification", {
        Title = _private.gameName,
        Text = _private.gameName.."｜地图名称(中文)｜加载完成",
        Duration = 3
    })
    
    warn("\n"..(("="):rep(40).."\n- 脚本名称: ".._private.gameName.."\n- 描述: 面板模板\n- 版本: 1.0.0\n- 作者: inltree｜Lin×DeepSeek\n"..("="):rep(40)))
end

-- 重置库状态
function inltree_Lin_UniversalUILib.reset()
    -- 先关闭所有功能
    inltree_Lin_UniversalUILib.disableAllFunctions()
    
    -- 清理所有UI元素
    if _private.screenGui then
        _private.screenGui:Destroy()
        _private.screenGui = nil
    end
    
    -- 重置所有状态
    _private.buttons = {}
    _private.buttonStates = {}
    _private.activeFunctions = {}
    _private.onToggleChangeCallbacks = {}
    _private.isHidden = false
    _private.dragging = false
    _private.dragInput = nil
    _private.dragStart = nil
    _private.startPositions = {}
    
    -- 重新初始化
    return inltree_Lin_UniversalUILib.init()
end

-- 获取当前状态
function inltree_Lin_UniversalUILib.getState()
    return {
        buttonStates = _private.buttonStates,
        isHidden = _private.isHidden,
        gameName = _private.gameName
    }
end

-- 导出库
return inltree_Lin_UniversalUILib

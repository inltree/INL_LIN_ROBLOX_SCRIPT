local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 创建窗口
local Window = Rayfield:CreateWindow({
    Name = "M.E.G.EndlessReality",
    Icon = 0,
    LoadingTitle = "M.E.G. Endless Reality",
    LoadingSubtitle = "Loading...",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "M.E.G.EndlessRealityScript"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "未命名",
        Subtitle = "密钥系统",
        Note = "未提供获取密钥的方法",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- 创建选项卡
local UniversalTab = Window:CreateTab("通用功能", "settings")
local HierarchyTab = Window:CreateTab("层级功能", "layers")
local OtherTab = Window:CreateTab("其它功能", "more-horizontal")

-- 通用功能
local nightVisionEnabled = false
local walkSpeedValue = 16
local disableHoldPrompt = false
local defaultLighting = {
    Ambient = game.Lighting.Ambient,
    Brightness = game.Lighting.Brightness
}
local trackedObjects = {} -- 用于记录已处理的ESP对象

-- 夜视功能
UniversalTab:CreateToggle({
    Name = "夜视功能",
    CurrentValue = false,
    Callback = function(Value)
        nightVisionEnabled = Value
        if not Value then
            game.Lighting.Ambient = defaultLighting.Ambient
            game.Lighting.Brightness = defaultLighting.Brightness
        end
    end
})

-- 移动速度
UniversalTab:CreateSlider({
    Name = "移动速度",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        walkSpeedValue = Value
    end
})

-- 长按取消功能
UniversalTab:CreateToggle({
    Name = "禁用长按交互",
    CurrentValue = false,
    Callback = function(Value)
        disableHoldPrompt = Value
    end
})

-- 循环保持设置
spawn(function()
    while wait(0.5) do
        -- 保持夜视效果
        if nightVisionEnabled then
            game.Lighting.Ambient = Color3.new(1,1,1)
            game.Lighting.Brightness = 1
        end
        
        -- 保持移动速度
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = walkSpeedValue
        end
        
        -- 处理长按取消
        if disableHoldPrompt then
            for _, prompt in ipairs(game:GetService("ProximityPromptService"):GetPrompts()) do
                prompt.HoldDuration = 0
            end
        end
    end
end)

-- 长按取消事件监听
game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
    if disableHoldPrompt then
        prompt.HoldDuration = 0
    end
end)

-- 层级功能
HierarchyTab:CreateButton({
    Name = "传送电梯",
    Callback = function()
        local eIconPart = game.Workspace:FindFirstChild("Icons"):FindFirstChild("EIconPart")
        if eIconPart then
            game.Players.LocalPlayer.Character:MoveTo(eIconPart.Position + Vector3.new(0,3,0))
        end
    end
})

-- 带距离显示的ESP通用函数
local function CreateESPWithDistance(model, color, labelText)
    if not model or not model:IsA("Model") or trackedObjects[model] then return end
    
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    
    -- 创建高亮效果
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight:SetAttribute("IsESP", true)
    highlight.Parent = primaryPart
    
    -- 创建距离显示
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard:SetAttribute("IsESP", true)
    billboard.Parent = primaryPart
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 1, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = color  -- 文字颜色与高亮颜色一致
    distanceLabel.TextStrokeColor3 = Color3.new(0,0,0)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.TextSize = 18
    distanceLabel.Text = labelText
    distanceLabel.Parent = billboard
    
    -- 更新距离显示
    spawn(function()
        trackedObjects[model] = true
        while model.Parent and primaryPart.Parent and trackedObjects[model] do
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - primaryPart.Position).Magnitude
                distanceLabel.Text = string.format("%s\n%.1f米", labelText, distance)
            end
            wait(0.1)
        end
        -- 清理
        if highlight then highlight:Destroy() end
        if billboard then billboard:Destroy() end
        trackedObjects[model] = nil
    end)
end

-- 清除所有ESP效果
local function ClearAllESP()
    -- 清除已跟踪的对象
    for model in pairs(trackedObjects) do
        if model:IsA("Model") then
            local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local highlight = primaryPart:FindFirstChild("Highlight")
                local billboard = primaryPart:FindFirstChild("BillboardGui")
                if highlight then highlight:Destroy() end
                if billboard then billboard:Destroy() end
            end
        end
    end
    trackedObjects = {}
    
    -- 额外清理工作区中可能遗留的ESP效果
    for _, part in ipairs(game.Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local highlight = part:FindFirstChild("Highlight")
            local billboard = part:FindFirstChild("BillboardGui")
            if highlight and highlight:GetAttribute("IsESP") then
                highlight:Destroy()
            end
            if billboard and billboard:GetAttribute("IsESP") then
                billboard:Destroy()
            end
        end
    end
end

-- 实体高亮显示[红色]
local entityESPEnabled = false
HierarchyTab:CreateToggle({
    Name = "实体高亮显示[红色]",
    CurrentValue = false,
    Callback = function(Value)
        entityESPEnabled = Value
        if not Value then
            ClearAllESP()
        else
            spawn(function()
                while entityESPEnabled do
                    local npcsFolder = game.Workspace:FindFirstChild("NPCS")
                    if npcsFolder then
                        for _, model in ipairs(npcsFolder:GetChildren()) do
                            if model:IsA("Model") and not trackedObjects[model] then
                                CreateESPWithDistance(model, Color3.new(1,0,0), "实体")
                            end
                        end
                    end
                    wait(1)
                end
            end)
        end
    end
})

-- 任务物品高亮显示[绿色]
local itemESPEnabled = false
HierarchyTab:CreateToggle({
    Name = "任务物品高亮显示[绿色]",
    CurrentValue = false,
    Callback = function(Value)
        itemESPEnabled = Value
        if not Value then
            ClearAllESP()
        else
            spawn(function()
                while itemESPEnabled do
                    local puzzlesFolder = game.Workspace:FindFirstChild("Puzzle")
                    if puzzlesFolder then
                        puzzlesFolder = puzzlesFolder:FindFirstChild("Puzzles")
                        if puzzlesFolder then
                            for _, model in ipairs(puzzlesFolder:GetChildren()) do
                                if model:IsA("Model") and not trackedObjects[model] then
                                    CreateESPWithDistance(model, Color3.new(0,1,0), "任务物品")
                                end
                            end
                        end
                    end
                    wait(1)
                end
            end)
        end
    end
})

-- 其它功能
OtherTab:CreateLabel("M.E.G.系统模块待激活")

-- 初始化完成
print("M.E.G.EndlessRealityScript 加载完成")
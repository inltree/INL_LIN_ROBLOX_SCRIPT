-- M.E.G. Endless Reality 脚本 - 基于 Rayfield UI 库
-- 核心功能：通用控制、层级传送、距离显示

-- 1. 加载 Rayfield UI 库并初始化窗口
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local MainWindow = Rayfield:CreateWindow({
    Name = "inltree｜M.E.G. Endless Reality",
    Icon = 0,
    LoadingTitle = "inltree｜M.E.G. Endless Reality｜M.E.G.无尽现实",
    LoadingSubtitle = "Loading...",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "inltree｜M.E.G.EndlessReality",
        FileName = "inltree｜M.E.G.EndlessReality"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "M.E.G.EndlessRealityScript",
        Subtitle = "密钥系统",
        Note = "默认密匙：inltree",
        FileName = "inltree｜M.E.G.EndlessReality_ScriptKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"inltree"}
    }
})

-- 2. 创建功能选项卡
local Tab_Universal = MainWindow:CreateTab("通用功能", "settings")  -- 通用控制
local Tab_Hierarchy = MainWindow:CreateTab("层级功能", "layers")   -- 层级交互
local Tab_Other = MainWindow:CreateTab("其它功能", "more-horizontal") -- 待开发功能

-- 3. 全局变量定义（按功能分类）
-- 3.1 通用功能变量
local IsNightVisionOn = false          -- 夜视开关
local WalkSpeed = 16                    -- 移动速度（默认16）
local IsHoldPromptDisabled = false      -- 取消长按交互开关
local DefaultLighting = {               -- 初始光照备份
    Ambient = game.Lighting.Ambient,
    Brightness = game.Lighting.Brightness
}

-- 3.2 距离显示变量
local TrackedObjects = {}               -- 已跟踪的显示对象
local IsEntityDisplayOn = false         -- 实体距离显示开关
local IsItemDisplayOn = false           -- 任务目标显示开关
local Thread_EntityDisplay = nil        -- 实体显示线程
local Thread_ItemDisplay = nil          -- 任务目标显示线程

-- 4. 通用功能实现
-- 4.1 夜视功能切换
Tab_Universal:CreateToggle({
    Name = "夜视功能",
    CurrentValue = false,
    Callback = function(IsEnabled)
        IsNightVisionOn = IsEnabled
        -- 关闭时恢复初始光照
        if not IsEnabled then
            game.Lighting.Ambient = DefaultLighting.Ambient
            game.Lighting.Brightness = DefaultLighting.Brightness
        end
    end
})

-- 4.2 移动速度调节
Tab_Universal:CreateSlider({
    Name = "移动速度",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        WalkSpeed = Value
    end
})

-- 4.3 取消长按交互
Tab_Universal:CreateToggle({
    Name = "取消按钮长按交互",
    CurrentValue = false,
    Callback = function(IsEnabled)
        IsHoldPromptDisabled = IsEnabled
    end
})

-- 4.4 循环维持功能状态（核心逻辑）
local function MaintainSettingsLoop()
    while task.wait(0.1) do
        -- 维持夜视效果
        if IsNightVisionOn then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
            game.Lighting.Brightness = 1
        end

        -- 维持移动速度（防游戏重置）
        local LocalPlayer = game.Players.LocalPlayer
        local Character = LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChild("Humanoid")
            if Humanoid then
                pcall(function() Humanoid.WalkSpeed = WalkSpeed end)
            end
        end

        -- 维持长按交互取消（实时刷新）
        if IsHoldPromptDisabled then
            pcall(function()
                for _, Prompt in ipairs(game:GetService("ProximityPromptService"):GetChildren()) do
                    if Prompt:IsA("ProximityPrompt") then
                        Prompt.HoldDuration = 0
                    end
                end
            end)
        end
    end
end
spawn(MaintainSettingsLoop)

-- 4.5 监听新生成的长按提示（补充逻辑）
game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(Prompt)
    if IsHoldPromptDisabled then
        Prompt.HoldDuration = 0
    end
end)

-- 5. 层级功能实现
-- 5.1 传送至随机电梯位置
Tab_Hierarchy:CreateButton({
    Name = "传送电梯",
    Callback = function()
        local locations = {
            workspace.SpawnLocation,
            workspace.Elevators.Level0Elevator.SpawnPart,
            workspace.Elevators.Level0Elevator.SpawnLocation
        }
        
        local target = locations[math.random(1, 3)]
        game.Players.LocalPlayer.Character:MoveTo(target.Position + Vector3.new(0, 2, 0))
    end
})

-- 5.2 距离显示核心工具函数
local function CreateDistanceDisplay(TargetModel, TextColor, DisplayText)
    if not TargetModel or not TargetModel:IsA("Model") or TrackedObjects[TargetModel] then
        return
    end

    local BasePart = TargetModel.PrimaryPart or TargetModel:FindFirstChildWhichIsA("BasePart")
    if not BasePart then return end
    if BasePart:FindFirstChild("Distance_Billboard") then return end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "Distance_Billboard"
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 2, 0)
    Billboard.AlwaysOnTop = true
    Billboard:SetAttribute("IsDistanceDisplay", true)
    Billboard.Parent = BasePart

    local DistanceLabel = Instance.new("TextLabel")
    DistanceLabel.Size = UDim2.new(1, 0, 1, 0)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.TextColor3 = TextColor
    DistanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    DistanceLabel.TextStrokeTransparency = 0
    DistanceLabel.Font = Enum.Font.SourceSansBold
    DistanceLabel.TextSize = 18
    DistanceLabel.Text = DisplayText
    DistanceLabel.Parent = Billboard

    spawn(function()
        TrackedObjects[TargetModel] = true
        while TargetModel.Parent and BasePart.Parent and TrackedObjects[TargetModel] do
            local LocalPlayer = game.Players.LocalPlayer
            local HumanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                local Distance = (HumanoidRootPart.Position - BasePart.Position).Magnitude
                DistanceLabel.Text = string.format("%s\n%.1f米", DisplayText, Distance)
            end
            task.wait(0.1)
        end
        if Billboard and Billboard.Parent then Billboard:Destroy() end
        TrackedObjects[TargetModel] = nil
    end)
end

-- 清除所有距离显示
local function ClearAllDistanceDisplays()
    for Model in pairs(TrackedObjects) do
        if Model:IsA("Model") then
            local BasePart = Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart")
            if BasePart then
                local Billboard = BasePart:FindFirstChild("Distance_Billboard")
                if Billboard then Billboard:Destroy() end
            end
        end
    end
    TrackedObjects = {}

    for _, Part in ipairs(game.Workspace:GetDescendants()) do
        if Part:IsA("BasePart") then
            local Billboard = Part:FindFirstChild("Distance_Billboard")
            if Billboard then Billboard:Destroy() end
        end
    end
end

local function FindAllModelsInFolder(TargetFolder)
    local Models = {}
    for _, Child in ipairs(TargetFolder:GetDescendants()) do
        if Child:IsA("Model") then
            table.insert(Models, Child)
        end
    end
    return Models
end

-- 获取实体的昵称显示
local function GetEntityDisplayName(model)
    local nameMappings = {
        ["Animation"] = "动画",
        ["AraneaMembri"] = "蜘蛛腿",
        ["Clump"] = "肢团",
        ["Duller"] = "钝人",
        ["Hound"] = "猎犬",
        ["Howler"] = "嚎叫",
        ["MemoryWorm"] = "记忆蠕虫",
        ["PlayerSkinStealer"] = "玩家切皮者",
        ["Partygoet"] = "派对客",
        ["Partygoer_Invasion"] = "派对客_入侵",
        ["SkinStealer"] = "窃皮者",
        ["Strider"] = "视觉之神",
        ["Smiler"] = "笑魇",
        ["RunSmilers"] = "奔跑笑魇",
        ["Strangler"] = "绞杀者",
        ["ThePhone"] = "电话实体",
        ["Twin"] = "双胞胎",
        ["TheVirus"] = "病毒",
        ["Window"] = "窗户",
    }
    
    return nameMappings[model.Name] or model.Name
end

-- 获取任务目标的昵称显示
local function GetItemDisplayName(model)
    local nameMappings = {
        ["PowerBox"] = "电源箱",
        ["Piece"] = "派对客宣传",
        ["Item"] = "目标",
        ["Item2"] = "目标2",
        ["ItemL"] = "目标L",
    }
    
    return nameMappings[model.Name] or model.Name
end

-- 5.3 实体距离显示（红色）
Tab_Hierarchy:CreateToggle({
    Name = "实体显示",
    CurrentValue = false,
    Callback = function(IsEnabled)
        IsEntityDisplayOn = IsEnabled

        if not IsEnabled then
            if Thread_EntityDisplay then Thread_Display = nil end
            ClearAllDistanceDisplays()
            return
        end

        Thread_EntityDisplay = spawn(function()
            while IsEntityDisplayOn do
                local NPCsFolder = game.Workspace:FindFirstChild("NPCS")
                if NPCsFolder then
                    local AllNPCModels = FindAllModelsInFolder(NPCsFolder)
                    for _, Model in ipairs(AllNPCModels) do
                        if not TrackedObjects[Model] then
                            local displayName = GetEntityDisplayName(Model)
                            CreateDistanceDisplay(Model, Color3.new(1, 0, 0), displayName)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
})

-- 5.4 目标显示（绿色）
Tab_Hierarchy:CreateToggle({
    Name = "目标显示",
    CurrentValue = false,
    Callback = function(IsEnabled)
        IsItemDisplayOn = IsEnabled

        if not IsEnabled then
            if Thread_ItemDisplay then Thread_ItemDisplay = nil end
            ClearAllDistanceDisplays()
            return
        end

        Thread_ItemDisplay = spawn(function()
            while IsItemDisplayOn do
                local PuzzleFolder = game.Workspace:FindFirstChild("Puzzle")
                if PuzzleFolder then
                    local AllPuzzleModels = FindAllModelsInFolder(PuzzleFolder)
                    for _, Model in ipairs(AllPuzzleModels) do
                        if not TrackedObjects[Model] then
                            local displayName = GetItemDisplayName(Model)
                            CreateDistanceDisplay(Model, Color3.new(0, 1, 0), displayName)
                        end
                    end
                end

                local PowerBoxFolder = game.Workspace:FindFirstChild("PowerBox")
                if PowerBoxFolder then
                    local AllPowerBoxModels = FindAllModelsInFolder(PowerBoxFolder)
                    for _, Model in ipairs(AllPowerBoxModels) do
                        if not TrackedObjects[Model] then
                            local displayName = GetItemDisplayName(Model)
                            CreateDistanceDisplay(Model, Color3.new(0, 1, 0), displayName)
                        end
                    end
                end

                local PartyFolder = game.Workspace:FindFirstChild("Party")
                if PartyFolder then
                    local AllPartyModels = FindAllModelsInFolder(PartyFolder)
                    for _, Model in ipairs(AllPartyModels) do
                        if not TrackedObjects[Model] then
                            local displayName = GetItemDisplayName(Model)
                            CreateDistanceDisplay(Model, Color3.new(0, 1, 0), displayName)
                        end
                    end
                end

                task.wait(0.5)
            end
        end)
    end
})

-- 5.5 层级传送功能
Tab_Hierarchy:CreateSection("层级传送")

local Targets = {
    ["!-ExitTeleport"] = "ExitTeleport"
    ["零食-BoothTables"] = "BoothTables",
    ["零食-Booths"] = "Booths", 
    ["矩阵-TV"] = "tv",
    ["矩阵-KeyGrabber"] = "KeyGrabber",
    ["记忆-DinosaurPlush"] = "DinosaurPlush"
}

for name, targetName in pairs(Targets) do
    Tab_Hierarchy:CreateButton({
        Name = "传送-" .. name,
        Callback = function()
            local foundObjects = {}
            
            for _, room in ipairs(workspace.Rooms:GetDescendants()) do
                if room.Name == "NewRoom" then
                    for _, targetObj in ipairs(room:GetDescendants()) do
                        if targetObj.Name == targetName then
                            table.insert(foundObjects, {
                                Object = targetObj,
                                Path = targetObj:GetFullName()
                            })
                        end
                    end
                end
            end
            
            if #foundObjects > 0 then
                local randomTarget = foundObjects[math.random(1, #foundObjects)]
                game.Players.LocalPlayer.Character:MoveTo(randomTarget.Object.Position + Vector3.new(0, 3, 0))
                print("已传送至对应层级目标: " .. randomTarget.Path)
            else
                warn("未寻找到对应层级目标: " .. targetName)
            end
        end
    })
end

-- 6. 其它功能（待开发）
Tab_Other:CreateLabel("Waiting for production｜等待制作")

-- 7. 初始化完成提示
print("M.E.G.EndlessReality_Script 加载完成")

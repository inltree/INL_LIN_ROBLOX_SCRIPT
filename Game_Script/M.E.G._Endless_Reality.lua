--[[
    M.E.G. Endless Reality 脚本 - 基于 Tora UI 库
    优化版本：去除卡密系统，优化结构逻辑
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("GradeStuff"):FireServer() -- 提交任务
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("LevelPickEvent"):FireServer() -- 层级选择
    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("LevelOpt1Picked"):FireServer() -- 选择楼层 LevelOpt1Picked,LevelOpt2Picked,LevelOpt3Picked
    game:GetService("Players").LocalPlayer.Character:WaitForChild("DeathEvent"):FireServer() -- 死亡卡服额
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Tora_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Tora_Library/Tora_Library.lua", true))()
local Window_1 = Tora_Library:CreateWindow("M.E.G. Endless Reality")
local Window_2 = Tora_Library:CreateWindow("层级功能")
local Window_3 = Tora_Library:CreateWindow("其它功能")

local Tab_Universal = Window_1:AddFolder("通用功能")
local Tab_Hierarchy = Window_2:AddFolder("主要功能")
local Tab_Select = Window_2:AddFolder("选择功能")
local Tab_Other = Window_3:AddFolder("固定传送(大概无法使用)")

local IsNightVisionOn = false
local WalkSpeed = 16
local IsHoldPromptDisabled = false
local DefaultLighting = {
    Ambient = game.Lighting.Ambient,
    Brightness = game.Lighting.Brightness
}

local TrackedObjects = {}
local IsEntityDisplayOn = false
local IsItemDisplayOn = false
local Thread_EntityDisplay = nil
local Thread_ItemDisplay = nil

Tab_Universal:AddToggle({
    text = "夜视功能",
    default = false,
    callback = function(State)
        IsNightVisionOn = State
        if State then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
            game.Lighting.Brightness = 1
        else
            game.Lighting.Ambient = DefaultLighting.Ambient
            game.Lighting.Brightness = DefaultLighting.Brightness
        end
    end
})

Tab_Universal:AddSlider({
    text = "移动速度",
    min = 0,
    max = 1000,
    default = 16,
    callback = function(Value)
        WalkSpeed = Value
    end
})

Tab_Universal:AddToggle({
    text = "取消按钮长按交互",
    default = false,
    callback = function(State)
        IsHoldPromptDisabled = State
    end
})

local function MaintainSettingsLoop()
    while task.wait(0.1) do
        -- 夜视效果
        if IsNightVisionOn then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
            game.Lighting.Brightness = 1
        end
        
        local Character = LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChild("Humanoid")
            if Humanoid then
                pcall(function() Humanoid.WalkSpeed = WalkSpeed end)
            end
        end

        if IsHoldPromptDisabled then
            pcall(function()
                for _, Prompt in ipairs(ProximityPromptService:GetChildren()) do
                    if Prompt:IsA("ProximityPrompt") then
                        Prompt.HoldDuration = 0
                    end
                end
            end)
        end
    end
end
spawn(MaintainSettingsLoop)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(Prompt)
    if IsHoldPromptDisabled then
        Prompt.HoldDuration = 0
    end
end)

Tab_Hierarchy:AddButton({
    text = "传送电梯",
    callback = function()
        local locations = {
            workspace.SpawnLocation,
            workspace.Elevators.Level0Elevator.SpawnPart,
            workspace.Elevators.Level0Elevator.SpawnLocation
        }
        
        local target = locations[math.random(1, #locations)]
        LocalPlayer.Character:MoveTo(target.Position + Vector3.new(0, 2, 0))
    end
})

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

local Data_Cache = nil
task.spawn(function()
    local success, result = pcall(function()
        local response = game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Game_Data/M.E.G._Endless_Reality/Data.json", true)
        return HttpService:JSONDecode(response)
    end)

    if success and result then
        Data_Cache = result
        print("映射表加载成功")
    else
        warn("映射表加载失败：", result or "未知错误")
        Data_Cache = {entityMappings={}, itemMappings={}}
    end
end)

local function GetEntityDisplayName(model)
    if not Data_Cache then return model.Name end
    return Data_Cache.entityMappings[model.Name] or model.Name
end

local function GetItemDisplayName(model)
    if not Data_Cache then return model.Name end
    return Data_Cache.itemMappings[model.Name] or model.Name
end

Tab_Hierarchy:AddToggle({
    text = "实体显示",
    default = false,
    callback = function(State)
        IsEntityDisplayOn = State

        if not State then
            if Thread_EntityDisplay then Thread_EntityDisplay = nil end
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

Tab_Hierarchy:AddToggle({
    text = "目标显示",
    default = false,
    callback = function(State)
        IsItemDisplayOn = State

        if not State then
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

Tab_Select:AddButton({
    text = "一键选择地图和任务提交",
    flag = "button",
    callback = function()
        ReplicatedStorage.Events.GradeStuff:FireServer()
        ReplicatedStorage.Events.LevelPickEvent:FireServer()
        
        local levelOpts = {"LevelOpt1Picked", "LevelOpt2Picked", "LevelOpt3Picked"}
        local randomEvent = levelOpts[math.random(1, #levelOpts)]
        ReplicatedStorage.Events[randomEvent]:FireServer()
        print("选择成功！\nTips: 请不要在电梯运行中点击此按钮\n否则出现无限地图生成循环\n请在生成完毕后电梯门打开后进行再次点击进行刷新任务可以多次！")
    end
})

Tab_Select:AddLabel({
    text = "点击上方按钮一次后，打开控制台查看提示信息"
})

Tab_Select:AddButton({
    text = "直接死亡(测试)",
    flag = "button",
    callback = function()
    LocalPlayer.Character.DeathEvent:FireServer()
    end
})

local Targets = {
    ["!-ExitTeleport"] = "ExitTeleport",
    ["零食-BoothTables"] = "BoothTables",
    ["零食-Booths"] = "Booths", 
    ["矩阵-TV"] = "tv",
    ["矩阵-KeyGrabber"] = "KeyGrabber",
    ["记忆-DinosaurPlush"] = "DinosaurPlush",
}

for name, targetName in pairs(Targets) do
    Tab_Other:AddButton({
        text = "传送-" .. name,
        callback = function()
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
                LocalPlayer.Character:MoveTo(randomTarget.Object.Position + Vector3.new(0, 1, 0))
                print("已传送至对应层级目标: " .. randomTarget.Path)
            else
                warn("未寻找到对应层级目标: " .. targetName)
            end
        end
    })
end

Tab_Other:AddLabel({
    text = "Waiting for production｜等待制作"
})

print("M.E.G. Endless Reality_Script 加载完成")

Tora_Library:Init()

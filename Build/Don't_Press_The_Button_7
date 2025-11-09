--[[
   自动触碰 coin + 自动移除伤害 + 自动胜利（有限胜利触碰）
   作者: INL × GPT-5
]]

local LightingService = game:GetService("Lighting")
local WorkspaceService = game:GetService("Workspace")
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local DisasterFolder = LightingService:WaitForChild("Disasters")

local Config = {
    MainLoopInterval = 0.5,    -- 主循环扫描间隔
    CoinTouchInterval = 0.1,    -- 硬币触碰间隔
    WinTouchInterval = 0.1,     -- 胜利触碰间隔
    MaxWinTriggers = 3,         -- 每张地图胜利触碰最大次数
    DebugMode = true            -- 调试模式
}

local ActiveConnections = {}
local CurrentMapName = nil
local CurrentMapWinCount = 0
local HazardKeywords = {"cactus","die","death","explode","kill","hurt","poison","lava","laser","quicksand","spike","trap","thorn","tsunami"}
local WinKeywords = {"win","winner","victory","finish","end","complete","teleportout","escaped"}

-- 获取玩家 HumanoidRootPart
local function GetPlayerHRP()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 检测 coin 控件，返回 Part 与完整路径
local function GetCoinPart(object)
    if object:IsA("TouchTransmitter") or object.Name == "TouchInterest" then
        local parentPart = object.Parent
        if parentPart and parentPart:IsA("BasePart") then
            return parentPart, parentPart:GetFullName()
        end
    end
end

-- 安全触碰 Part
local function TriggerTouch(part, fullPath, typeLabel)
    local hrp = GetPlayerHRP()
    if not hrp or not part then return end
    pcall(function()
        firetouchinterest(part, hrp, 0)
        task.wait(0.05)
        firetouchinterest(part, hrp, 1)
    end)
    if Config.DebugMode then
        if typeLabel == "coin" then
            print("🪙 Coin触碰路径: " .. fullPath)
        elseif typeLabel == "win" then
            print("🏆 胜利触碰路径: " .. fullPath)
        end
    end
end

-- 移除伤害方块（名字中包含关键词即删除）
local function RemoveHazardBlocks(rootObject)
    for _, child in ipairs(rootObject:GetChildren()) do
        local nameLower = string.lower(child.Name)
        local isHazard = false
        for _, keyword in ipairs(HazardKeywords) do
            if string.find(nameLower, string.lower(keyword)) then
                isHazard = true
                break
            end
        end
        if isHazard then
            local path = child:GetFullName()
            child:Destroy()
            if Config.DebugMode then print("🗑️ 伤害移除路径: " .. path) end
        else
            RemoveHazardBlocks(child)
        end
    end
end

-- 扫描并触发胜利对象（有限次数）
local function ScanAndTriggerWin(mapModel)
    if CurrentMapWinCount >= Config.MaxWinTriggers then return end
    local hrp = GetPlayerHRP()
    if not hrp then return end
    local triggered = 0
    for _, obj in ipairs(mapModel:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        for _, keyword in ipairs(WinKeywords) do
            if string.find(nameLower, string.lower(keyword)) then
                local targetPart = obj:IsA("BasePart") and obj or (obj:FindFirstChildOfClass("BasePart") or obj)
                TriggerTouch(targetPart, obj:GetFullName(), "win")
                triggered += 1
                task.wait(Config.WinTouchInterval)
                break
            end
        end
        if triggered + CurrentMapWinCount >= Config.MaxWinTriggers then break end
    end
    CurrentMapWinCount += triggered
end

-- 扫描并触碰 coin
local function ScanAndTouchCoins(mapModel)
    local hrp = GetPlayerHRP()
    if not hrp then return end
    for _, obj in ipairs(mapModel:GetDescendants()) do
        local part, path = GetCoinPart(obj)
        if part then
            TriggerTouch(part, path, "coin")
            task.wait(Config.CoinTouchInterval)
        end
    end
end

-- 扫描整张地图
local function ScanMap(mapModel)
    RemoveHazardBlocks(mapModel)
    ScanAndTriggerWin(mapModel)
    ScanAndTouchCoins(mapModel)
    table.insert(ActiveConnections, mapModel.DescendantAdded:Connect(function(obj)
        local part, path = GetCoinPart(obj)
        if part then TriggerTouch(part, path, "coin") end
    end))
end

-- 清理旧监听
local function ClearActiveConnections()
    for _, conn in ipairs(ActiveConnections) do conn:Disconnect() end
    table.clear(ActiveConnections)
end

-- 扫描 Disaster 对应的地图
local function RescanMaps()
    ClearActiveConnections()
    for _, disaster in ipairs(DisasterFolder:GetChildren()) do
        local mapModel = WorkspaceService:FindFirstChild(disaster.Name)
        if mapModel then
            if CurrentMapName ~= mapModel.Name then
                CurrentMapName = mapModel.Name
                CurrentMapWinCount = 0
                if Config.DebugMode then
                    print("\n🌍 地图切换: " .. CurrentMapName)
                end
            end
            ScanMap(mapModel)
        end
    end
end

-- 新地图生成监听
WorkspaceService.ChildAdded:Connect(function(obj)
    if DisasterFolder:FindFirstChild(obj.Name) then
        if Config.DebugMode then
            print("\n🌍 地图更换: " .. obj.Name)
        end
        ScanMap(obj)
    end
end)
DisasterFolder.ChildAdded:Connect(RescanMaps)
DisasterFolder.ChildRemoved:Connect(RescanMaps)

-- 主循环
coroutine.wrap(function()
    while true do
        RescanMaps()
        task.wait(Config.MainLoopInterval)
    end
end)()

print("\n✅ 自动触碰 coin + 自动移除伤害 + 自动胜利（有限胜利触碰）已启动")

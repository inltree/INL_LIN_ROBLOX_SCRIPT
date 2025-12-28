if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Tora_Library/Tora_Library.lua", true))()
local MainWindow = Library:CreateWindow("Don't Press The Button 4")
local ConfigWindow = Library:CreateWindow("配置面板")

-- 全局功能开关
_G.AutoWin_DangerDelete = false
_G.AutoWin_WinTrigger = false      -- 原始胜利触发（对象触碰）
_G.AutoWin_CoinCollect = false
_G.AutoWin_PathTrigger = false
_G.AutoWin_MapMonitor = false
_G.AutoWin_TextMonitor = false     -- 胜利触发v2（文本监听）

-- 配置参数
_G.AutoWin_Config = {
    MapInterval = 0.5,
    CoinInterval = 0.1,
    PathInterval = 0.1,
    WinInterval = 0.3,
    DangerInterval = 0.1,
    WinLimit = 5
}

-- 运行状态
local CurrentMap = nil
local WinCount = 0
local LastPathMap = nil
local IsPlayerWon = false  -- 用于“胜利触发v2”的终止标志

-- 关键词表
local Keywords = {
    Win = {"win","wpart","castlechest","teleportout","escaped","victory","finish","end"},
    Coin = {"coin","pumpkin","reward"},
    Danger = {"cactus","die","death","explode","kill","hurt","poison","lava","laser","lightorb","quicksand","spike","trap","thorn"}
}

-- 固定路径映射
local MapPaths = {
    Map19 = {"Win"}, Map36 = {"TheWatee"}, Map78 = {"Winners"},
    Map87 = {"Shapes"}, Map88 = {"hitboxes"}, Map92 = {"Rings"},
    Map98 = {"Pads"}, Map110 = {"Blocks","B"}, Map113 = {"TheCandy"},
    Map114 = {"Fireworks"}, Map115 = {"CurrentLeaks"}, Map116 = {"Spawns"},
    Map134 = {"Active"}, Map141 = {"MeshPart"}, Map149 = {"UsedPresent"}
}

-- === 工具函数 ===
local function Contains(text, list)
    for _, item in ipairs(list) do
        if string.find(string.lower(text), string.lower(item)) then
            return true
        end
    end
    return false
end

local function FindMap()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^Map%d+$") then
            return obj
        end
    end
    return nil
end

local function TriggerTouch(transmitter, part)
    pcall(function()
        firetouchinterest(transmitter.Parent, part, 0)
        task.wait(0.05)
        firetouchinterest(transmitter.Parent, part, 1)
    end)
end

local function TriggerAll(parent, part)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("TouchTransmitter") then
            TriggerTouch(obj, part)
        end
    end
end

-- === 玩家胜利文本监听系统 ===
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerName = LocalPlayer.Name

-- 安全获取 Winners 标签（防止界面未加载）
local function GetWinnersLabel()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end
    local disaster = gui:FindFirstChild("DisasterGUI")
    if not disaster then return nil end
    local textLabel = disaster:FindFirstChild("TextLabel")
    if not textLabel then return nil end
    return textLabel:FindFirstChild("Winners")
end

-- 监听 Winners 文本变化
spawn(function()
    while wait(1) do
        local WinnersLabel = GetWinnersLabel()
        if WinnersLabel and _G.AutoWin_TextMonitor then
            WinnersLabel:GetPropertyChangedSignal("Text"):Wait()
            if _G.AutoWin_TextMonitor and not IsPlayerWon then
                local text = WinnersLabel.Text
                if text and string.find(text, PlayerName, 1, true) then
                    IsPlayerWon = true
                    print("[inltree] 🏆 检测用户名在胜利列表中，自动暂停胜利触发v2")
                end
            end
        else
            task.wait(1)
        end
    end
end)

-- === 功能线程 ===

-- 🚫 伤害删除
spawn(function()
    while task.wait(_G.AutoWin_Config.DangerInterval) do
        if _G.AutoWin_DangerDelete then
            local map = FindMap()
            if map then
                pcall(function()
                    local function DeleteDanger(obj)
                        for _, child in ipairs(obj:GetChildren()) do
                            if Contains(child.Name, Keywords.Danger) then
                                child:Destroy()
                                print("[inltree] 💀 删除伤害对象:", child:GetFullName())
                            else
                                DeleteDanger(child)
                            end
                        end
                    end
                    DeleteDanger(map)
                end)
            end
        end
    end
end)

-- 🏆 原始胜利触发（对象触碰）
spawn(function()
    while task.wait(_G.AutoWin_Config.WinInterval) do
        if _G.AutoWin_WinTrigger and WinCount < _G.AutoWin_Config.WinLimit then
            local map = FindMap()
            if map then
                pcall(function()
                    local targets = {}
                    for _, obj in ipairs(map:GetDescendants()) do
                        if Contains(obj.Name, Keywords.Win) then
                            table.insert(targets, obj)
                        end
                    end
                    
                    if #targets > 0 then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChildWhichIsA("BasePart")
                        if hrp then
                            local remain = _G.AutoWin_Config.WinLimit - WinCount
                            local count = 0
                            for _, obj in ipairs(targets) do
                                TriggerAll(obj, hrp)
                                print("[inltree] 🎉 触发胜利（原始）:", obj:GetFullName())
                                count += 1
                                if count >= remain then break end
                            end
                            WinCount += count
                        end
                    end
                end)
            end
        end
    end
end)

-- 🪙 硬币收集
spawn(function()
    while task.wait(_G.AutoWin_Config.CoinInterval) do
        if _G.AutoWin_CoinCollect then
            local map = FindMap()
            if map then
                pcall(function()
                    local coins = {}
                    for _, obj in ipairs(map:GetDescendants()) do
                        if Contains(obj.Name, Keywords.Coin) then
                            table.insert(coins, obj)
                        end
                    end
                    
                    if #coins > 0 then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChildWhichIsA("BasePart")
                        if hrp then
                            for _, obj in ipairs(coins) do
                                TriggerAll(obj, hrp)
                                print("[inltree] 💰 收集硬币:", obj:GetFullName())
                                task.wait(_G.AutoWin_Config.CoinInterval)
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- 🧭 固定路径
spawn(function()
    while task.wait(_G.AutoWin_Config.PathInterval) do
        if _G.AutoWin_PathTrigger then
            local map = FindMap()
            if map then
                local mapName = map.Name
                if mapName ~= LastPathMap then
                    LastPathMap = nil
                end
                
                local paths = MapPaths[mapName]
                if paths then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChildWhichIsA("BasePart")
                    if hrp then
                        for _, path in ipairs(paths) do
                            local fullPath = mapName .. "." .. path
                            local obj = workspace
                            for segment in string.gmatch(fullPath, "[^%.]+") do
                                if obj then
                                    obj = obj:FindFirstChild(segment)
                                end
                            end
                            if obj then
                                print("[inltree] 🛣️ 触发路径:", fullPath)
                                TriggerAll(obj, hrp)
                                task.wait(_G.AutoWin_Config.PathInterval)
                            end
                        end
                        LastPathMap = mapName
                    end
                end
            end
        end
    end
end)

-- 🎯 地图监控（重置计数 + 重置胜利状态）
spawn(function()
    while task.wait(_G.AutoWin_Config.MapInterval) do
        if _G.AutoWin_MapMonitor then
            local map = FindMap()
            if map and map.Name ~= CurrentMap then
                CurrentMap = map.Name
                WinCount = 0
                IsPlayerWon = false  -- 关键：切换地图后允许再次触发
                print("[inltree] 🔄 切换地图:", CurrentMap)
            end
        end
    end
end)

-- 🏆 胜利触发v2（基于 Winners 文本监听）
spawn(function()
    while task.wait(_G.AutoWin_Config.WinInterval) do
        if _G.AutoWin_TextMonitor and not IsPlayerWon then
            local map = FindMap()
            if map and WinCount < _G.AutoWin_Config.WinLimit then
                pcall(function()
                    local targets = {}
                    for _, obj in ipairs(map:GetDescendants()) do
                        if Contains(obj.Name, Keywords.Win) then
                            table.insert(targets, obj)
                        end
                    end
                    
                    if #targets > 0 then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChildWhichIsA("BasePart")
                        if hrp then
                            local remain = _G.AutoWin_Config.WinLimit - WinCount
                            local count = 0
                            for _, obj in ipairs(targets) do
                                TriggerAll(obj, hrp)
                                print("[inltree] 🎉 触发胜利（v2）:", obj:GetFullName())
                                count += 1
                                if count >= remain then break end
                            end
                            WinCount += count
                        end
                    end
                end)
            end
        end
    end
end)

local FuncFolder = MainWindow:AddFolder("功能控制")

FuncFolder:AddToggle({
    text = "伤害删除",
    state = false,
    callback = function(state)
        _G.AutoWin_DangerDelete = state
    end
})

FuncFolder:AddToggle({
    text = "胜利触发",  -- 原始方式
    state = false,
    callback = function(state)
        _G.AutoWin_WinTrigger = state
    end
})

FuncFolder:AddToggle({
    text = "胜利触发v2",  -- 新增：基于 Winners 文本监听
    state = false,
    callback = function(state)
        _G.AutoWin_TextMonitor = state
        if not state then
            IsPlayerWon = false  -- 关闭时重置状态
        end
    end
})

FuncFolder:AddToggle({
    text = "硬币收集",
    state = false,
    callback = function(state)
        _G.AutoWin_CoinCollect = state
    end
})

FuncFolder:AddToggle({
    text = "固定路径",
    state = false,
    callback = function(state)
        _G.AutoWin_PathTrigger = state
    end
})

FuncFolder:AddToggle({
    text = "地图监控",
    state = false,
    callback = function(state)
        _G.AutoWin_MapMonitor = state
    end
})

-- 配置面板
local ConfigFolder = ConfigWindow:AddFolder("参数配置")

ConfigFolder:AddSlider({
    text = "地图监控间隔",
    min = 0.1, max = 2, value = 0.5,
    callback = function(value)
        _G.AutoWin_Config.MapInterval = value
    end
})

ConfigFolder:AddSlider({
    text = "硬币触碰间隔",
    min = 0.05, max = 1, value = 0.1,
    callback = function(value)
        _G.AutoWin_Config.CoinInterval = value
    end
})

ConfigFolder:AddSlider({
    text = "路径扫描间隔",
    min = 0.05, max = 1, value = 0.1,
    callback = function(value)
        _G.AutoWin_Config.PathInterval = value
    end
})

ConfigFolder:AddSlider({
    text = "胜利触发间隔",
    min = 0.1, max = 1, value = 0.3,
    callback = function(value)
        _G.AutoWin_Config.WinInterval = value
    end
})

ConfigFolder:AddSlider({
    text = "伤害删除间隔",
    min = 0.05, max = 1, value = 0.1,
    callback = function(value)
        _G.AutoWin_Config.DangerInterval = value
    end
})

ConfigFolder:AddSlider({
    text = "胜利次数上限",
    min = 1, max = 20, value = 5,
    callback = function(value)
        _G.AutoWin_Config.WinLimit = value
    end
})

-- 工具按钮
local ToolFolder = MainWindow:AddFolder("工具")
ToolFolder:AddButton({
    text = "手动触发胜利",
    callback = function()
        local map = FindMap()
        if map then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChildWhichIsA("BasePart")
            if hrp then
                for _, obj in ipairs(map:GetDescendants()) do
                    if Contains(obj.Name, Keywords.Win) then
                        TriggerAll(obj, hrp)
                        print("[inltree] 🎯 手动触发胜利:", obj:GetFullName())
                    end
                end
            end
        end
    end
})

Library:Init()
print("[inltree] ✅ Don't Press The Button 4 Script loaded successfully.")

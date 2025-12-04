-- 加载 Tora Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Tora_Library/Tora_Library.lua",true))()

-- 自动胜利脚本配置和功能
local cfg = {
    mainInterval = 0.5,   -- 地图监控间隔
    coinInterval = 0.1,   -- 硬币触碰间隔
    pathInterval = 0.1,   -- 固定路径扫描间隔
    winInterval = 0.3,    -- 胜利触发间隔
    dangerInterval = 0.1, -- 伤害删除间隔
    winLimit = 5,         -- 每张地图胜利触发次数上限
    debug = false          -- 调试模式
}

local LocalPlayer = game.Players.LocalPlayer
local curMap = nil
local winCount = 0
local lastPathMap = nil

-- 功能表
local WIN = {"win","wpart","castlechest","teleportout","escaped","victory","finish","end"}
local COIN = {"coin","pumpkin","reward"}
local DAG = {"cactus","die","death","explode","kill","hurt","poison","lava","laser","lightorb","quicksand","spike","trap","thorn"}

-- 固定路径表
local MAP_PATHS = {
    Map19 = {"Win"},
    Map36 = {"TheWatee"},
    Map78 = {"Winners"},
    Map87 = {"Shapes"},
    Map88 = {"hitboxes"},
    Map92 = {"Rings"},
    Map98 = {"Pads"},
    Map110 = {"Blocks","B"},
    Map113 = {"TheCandy"},
    Map114 = {"Fireworks"},
    Map115 = {"CurrentLeaks"},
    Map116 = {"Spawns"},
    Map134 = {"Active"},
    Map141 = {"MeshPart"},
    Map149 = {"UsedPresent"}
}

-- 控制变量
local scriptsRunning = {
    dangerDelete = false,
    winTrigger = false,
    coinTrigger = false,
    pathTrigger = false,
    mapMonitor = false
}

-- 线程句柄
local threads = {}

-- 打印格式化
local function inltreeLog(emoji, category, message)
    print("[自动胜利] " .. emoji .. " [" .. category .. "] " .. message)
end

local function has(str, tbl)
    for _, v in ipairs(tbl) do
        if string.find(string.lower(str), string.lower(v)) then
            return true
        end
    end
end

local function findMap()
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v.Name:match("^Map%d+$") then
            return v
        end
    end
end

local function touch(tt, hrp)
    pcall(function()
        firetouchinterest(tt.Parent, hrp, 0)
        task.wait(0.05)
        firetouchinterest(tt.Parent, hrp, 1)
    end)
end

local function triggerUnder(obj, hrp)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("TouchTransmitter") then
            touch(v, hrp)
        end
    end
end

-- 🚫 伤害删除线程
local function startDangerDelete()
    if threads.dangerDelete then 
        threads.dangerDelete = nil
        task.wait(0.1)
    end
    
    scriptsRunning.dangerDelete = true
    threads.dangerDelete = task.spawn(function()
        while scriptsRunning.dangerDelete do
            local map = findMap()
            if map then
                pcall(function()
                    local function deleteDangerous(obj)
                        for _, child in ipairs(obj:GetChildren()) do
                            if has(child.Name, DAG) then
                                child:Destroy()
                                if cfg.debug then
                                    inltreeLog("💀", "伤害删除", child:GetFullName())
                                end
                            else
                                deleteDangerous(child)
                            end
                        end
                    end
                    deleteDangerous(map)
                end)
            end
            task.wait(cfg.dangerInterval)
        end
    end)
end

-- 🏆 胜利触发线程
local function startWinTrigger()
    if threads.winTrigger then 
        threads.winTrigger = nil
        task.wait(0.1)
    end
    
    scriptsRunning.winTrigger = true
    threads.winTrigger = task.spawn(function()
        while scriptsRunning.winTrigger do
            local map = findMap()
            if map and winCount < cfg.winLimit then
                pcall(function()
                    local foundObjs = {}
                    for _, v in ipairs(map:GetDescendants()) do
                        if has(v.Name, WIN) then
                            table.insert(foundObjs, v)
                        end
                    end
                    if #foundObjs == 0 then return end

                    local c = LocalPlayer.Character
                    local hrp = c and c:FindFirstChildWhichIsA("BasePart")
                    if not hrp then return end

                    local remain = cfg.winLimit - winCount
                    local count = 0
                    
                    for _, obj in ipairs(foundObjs) do
                        triggerUnder(obj, hrp)
                        if cfg.debug then 
                            inltreeLog("🎉", "胜利触发", obj:GetFullName())
                        end
                        count += 1
                        if count >= remain then break end
                    end
                    winCount += count
                end)
            end
            task.wait(cfg.winInterval)
        end
    end)
end

-- 🪙 硬币触发线程
local function startCoinTrigger()
    if threads.coinTrigger then 
        threads.coinTrigger = nil
        task.wait(0.1)
    end
    
    scriptsRunning.coinTrigger = true
    threads.coinTrigger = task.spawn(function()
        while scriptsRunning.coinTrigger do
            local map = findMap()
            if map then
                pcall(function()
                    local foundObjs = {}
                    for _, v in ipairs(map:GetDescendants()) do
                        if has(v.Name, COIN) then
                            table.insert(foundObjs, v)
                        end
                    end
                    if #foundObjs == 0 then return end

                    local c = LocalPlayer.Character
                    local hrp = c and c:FindFirstChildWhichIsA("BasePart")
                    if not hrp then return end

                    for _, obj in ipairs(foundObjs) do
                        triggerUnder(obj, hrp)
                        if cfg.debug then 
                            inltreeLog("💰", "硬币触发", obj:GetFullName())
                        end
                        task.wait(cfg.coinInterval)
                    end
                end)
            end
            task.wait(cfg.coinInterval)
        end
    end)
end

-- 🧭 固定路径线程
local function startPathTrigger()
    if threads.pathTrigger then 
        threads.pathTrigger = nil
        task.wait(0.1)
    end
    
    scriptsRunning.pathTrigger = true
    threads.pathTrigger = task.spawn(function()
        local function safeFindPath(startObj, pathStr)
            local obj = startObj
            for seg in string.gmatch(pathStr, "[^%.]+") do
                if not obj then return nil end
                obj = obj:FindFirstChild(seg)
            end
            return obj
        end

        while scriptsRunning.pathTrigger do
            local map = findMap()
            if map then
                local mapName = map.Name
                if mapName ~= lastPathMap then
                    lastPathMap = nil
                end

                local paths = MAP_PATHS[mapName]
                if paths then
                    local c = LocalPlayer.Character
                    local hrp = c and c:FindFirstChildWhichIsA("BasePart")
                    if hrp then
                        for _, relPath in ipairs(paths) do
                            local fullPath = mapName .. "." .. relPath
                            local obj = safeFindPath(workspace, fullPath)
                            if obj then
                                if cfg.debug then 
                                    inltreeLog("🛣️", "路径触发", fullPath)
                                end
                                triggerUnder(obj, hrp)
                                task.wait(cfg.pathInterval)
                            elseif cfg.debug and mapName ~= lastPathMap then
                                inltreeLog("❓", "路径未检索", fullPath)
                            end
                        end
                        lastPathMap = mapName
                    end
                elseif cfg.debug and mapName ~= lastPathMap then
                    inltreeLog("⏭️", "跳过路径", "未定义路径表：" .. mapName)
                    lastPathMap = mapName
                end
            end
            task.wait(cfg.pathInterval)
        end
    end)
end

-- 🎯 地图监控线程
local function startMapMonitor()
    if threads.mapMonitor then 
        threads.mapMonitor = nil
        task.wait(0.1)
    end
    
    scriptsRunning.mapMonitor = true
    threads.mapMonitor = task.spawn(function()
        while scriptsRunning.mapMonitor do
            local map = findMap()
            if map then
                if map.Name ~= curMap then
                    curMap = map.Name
                    winCount = 0
                    inltreeLog("🔄", "地图切换", "当前地图: " .. curMap)
                end
            end
            task.wait(cfg.mainInterval)
        end
    end)
end

-- 停止所有脚本
local function stopAllScripts()
    for key, _ in pairs(scriptsRunning) do
        scriptsRunning[key] = false
    end
    
    for key, thread in pairs(threads) do
        if thread then
            task.cancel(thread)
            threads[key] = nil
        end
    end
    
    inltreeLog("🛑", "系统停止", "所有脚本已停止")
end

-- 启动所有脚本
local function startAllScripts()
    stopAllScripts() -- 先停止之前的
    task.wait(0.2)
    
    startMapMonitor()
    startDangerDelete()
    startWinTrigger()
    startCoinTrigger()
    startPathTrigger()
    
    inltreeLog("🚀", "系统启动", "自动胜利脚本已启动 - UI控制版")
    inltreeLog("⚙️", "配置信息", "调试模式: " .. tostring(cfg.debug))
end

-- 创建UI界面
local tab = library:CreateWindow("自动胜利脚本 v1.1.14")

-- 主控制文件夹
local mainFolder = tab:AddFolder("主控制")

mainFolder:AddToggle({
    text = "启用所有功能",
    flag = "masterToggle",
    callback = function(v)
        if v then
            startAllScripts()
        else
            stopAllScripts()
        end
    end
})

mainFolder:AddButton({
    text = "启动所有脚本",
    callback = function()
        startAllScripts()
    end
})

mainFolder:AddButton({
    text = "停止所有脚本",
    callback = function()
        stopAllScripts()
    end
})

-- 功能控制文件夹
local functionFolder = tab:AddFolder("功能控制")

functionFolder:AddToggle({
    text = "伤害删除",
    flag = "dangerToggle",
    callback = function(v)
        if v then
            startDangerDelete()
        else
            scriptsRunning.dangerDelete = false
            if threads.dangerDelete then
                task.cancel(threads.dangerDelete)
                threads.dangerDelete = nil
            end
        end
    end
})

functionFolder:AddToggle({
    text = "胜利触发",
    flag = "winToggle",
    callback = function(v)
        if v then
            startWinTrigger()
        else
            scriptsRunning.winTrigger = false
            if threads.winTrigger then
                task.cancel(threads.winTrigger)
                threads.winTrigger = nil
            end
        end
    end
})

functionFolder:AddToggle({
    text = "硬币收集",
    flag = "coinToggle",
    callback = function(v)
        if v then
            startCoinTrigger()
        else
            scriptsRunning.coinTrigger = false
            if threads.coinTrigger then
                task.cancel(threads.coinTrigger)
                threads.coinTrigger = nil
            end
        end
    end
})

functionFolder:AddToggle({
    text = "固定路径",
    flag = "pathToggle",
    callback = function(v)
        if v then
            startPathTrigger()
        else
            scriptsRunning.pathTrigger = false
            if threads.pathTrigger then
                task.cancel(threads.pathTrigger)
                threads.pathTrigger = nil
            end
        end
    end
})

functionFolder:AddToggle({
    text = "地图监控",
    flag = "mapToggle",
    callback = function(v)
        if v then
            startMapMonitor()
        else
            scriptsRunning.mapMonitor = false
            if threads.mapMonitor then
                task.cancel(threads.mapMonitor)
                threads.mapMonitor = nil
            end
        end
    end
})

-- 配置设置文件夹
local configFolder = tab:AddFolder("配置设置")

configFolder:AddSlider({
    text = "地图监控间隔",
    min = 0.1,
    max = 2,
    value = cfg.mainInterval,
    callback = function(v)
        cfg.mainInterval = v
    end
})

configFolder:AddSlider({
    text = "硬币触碰间隔",
    min = 0.05,
    max = 1,
    value = cfg.coinInterval,
    callback = function(v)
        cfg.coinInterval = v
    end
})

configFolder:AddSlider({
    text = "路径扫描间隔",
    min = 0.05,
    max = 1,
    value = cfg.pathInterval,
    callback = function(v)
        cfg.pathInterval = v
    end
})

configFolder:AddSlider({
    text = "胜利触发间隔",
    min = 0.1,
    max = 1,
    value = cfg.winInterval,
    callback = function(v)
        cfg.winInterval = v
    end
})

configFolder:AddSlider({
    text = "伤害删除间隔",
    min = 0.05,
    max = 1,
    value = cfg.dangerInterval,
    callback = function(v)
        cfg.dangerInterval = v
    end
})

configFolder:AddSlider({
    text = "胜利次数上限",
    min = 1,
    max = 20,
    value = cfg.winLimit,
    callback = function(v)
        cfg.winLimit = v
    end
})

configFolder:AddToggle({
    text = "调试模式",
    flag = "debugToggle",
    callback = function(v)
        cfg.debug = v
    end
})

-- 状态信息文件夹
local statusFolder = tab:AddFolder("状态信息")

statusFolder:AddLabel({
    text = "当前地图: 无",
    flag = "mapLabel"
})

statusFolder:AddLabel({
    text = "胜利次数: 0",
    flag = "winLabel"
})

-- 更新状态信息的函数
local function updateStatus()
    local map = findMap()
    local mapName = map and map.Name or "无"
    library.flags.mapLabel = "当前地图: " .. mapName
    library.flags.winLabel = "胜利次数: " .. tostring(winCount)
end

-- 状态更新线程
task.spawn(function()
    while true do
        updateStatus()
        task.wait(1)
    end
end)

-- 工具文件夹
local toolFolder = tab:AddFolder("工具")

toolFolder:AddButton({
    text = "重置胜利计数",
    callback = function()
        winCount = 0
        inltreeLog("🔄", "状态重置", "胜利计数已重置")
    end
})

toolFolder:AddButton({
    text = "手动触发胜利",
    callback = function()
        local map = findMap()
        if map then
            local c = LocalPlayer.Character
            local hrp = c and c:FindFirstChildWhichIsA("BasePart")
            if hrp then
                for _, v in ipairs(map:GetDescendants()) do
                    if has(v.Name, WIN) then
                        triggerUnder(v, hrp)
                        inltreeLog("🎯", "手动触发", v:GetFullName())
                    end
                end
            end
        end
    end
})

toolFolder:AddButton({
    text = "打印当前状态",
    callback = function()
        inltreeLog("📊", "状态报告", "胜利次数: " .. winCount)
        inltreeLog("📊", "状态报告", "当前地图: " .. (curMap or "无"))
        inltreeLog("📊", "状态报告", "运行状态: " .. tostring(scriptsRunning.winTrigger))
    end
})

-- 初始化UI
library:Init()

-- 启动消息
inltreeLog("✅", "UI加载", "自动胜利脚本UI已加载完成")
inltreeLog("ℹ️", "使用提示", "请在UI界面中启用所需功能")

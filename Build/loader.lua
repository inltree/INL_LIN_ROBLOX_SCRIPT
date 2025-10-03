--[[
    ┌──────────────────────────────────────────────────────────┐
    │                   inltree｜Lin 脚本加载器                 │
    │                    版本: 1.2.0                          │
    │                作者: inltree｜Lin×DeepSeek               │
    └──────────────────────────────────────────────────────────┘
]]

local StarterGui = game:GetService("StarterGui")

-- 配置信息
local CONFIG_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Game_Config.lua"
local DEFAULT_SCRIPT = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_Tools/Player_Info.lua"

local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

-- 打印格式化信息
local function printBox(title, content)
    local border = "┌" .. string.rep("─", 38) .. "┐"
    local middle = "│" .. string.rep(" ", 38) .. "│"
    local bottom = "└" .. string.rep("─", 38) .. "┘"
    
    print(border)
    print("│ " .. title .. string.rep(" ", 36 - #title) .. "│")
    print(middle)
    
    if type(content) == "table" then
        for key, value in pairs(content) do
            local line = "│  • " .. key .. ": " .. tostring(value)
            line = line .. string.rep(" ", 36 - #line) .. "│"
            print(line)
        end
    else
        local line = "│  " .. tostring(content)
        line = line .. string.rep(" ", 36 - #line) .. "│"
        print(line)
    end
    
    print(bottom)
end

print("╔════════════════════════════════════════════╗")
print("║           inltree｜Lin 脚本加载器           ║")
print("║                版本 1.2.0                  ║")
print("╚════════════════════════════════════════════╝")

-- 加载外部配置
printBox("配置加载状态", "正在加载外部配置文件...")

local GAME_CONFIG = {}
local configSuccess, configResult = pcall(function()
    return loadstring(game:HttpGet(CONFIG_URL))()
end)

if configSuccess and type(configResult) == "table" then
    GAME_CONFIG = configResult
    printBox("配置加载成功", {
        ["支持游戏数量"] = #GAME_CONFIG,
        ["配置来源"] = "外部配置"
    })
else
    printBox("配置加载警告", {
        ["状态"] = "使用空配置",
        ["提示"] = "将继续加载默认脚本"
    })
end

-- 主加载逻辑
local currentGameId = game.PlaceId
local scriptConfig = GAME_CONFIG[currentGameId]

if scriptConfig and scriptConfig.ScriptUrl ~= "" then
    printBox("游戏匹配成功", {
        ["游戏名称"] = scriptConfig.Name,
        ["游戏ID"] = currentGameId
    })
    
    notify("🎯 匹配成功", scriptConfig.Name, 3)

    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptConfig.ScriptUrl))()
    end)
    
    if success then
        printBox("脚本加载状态", {
            ["状态"] = "✅ 加载成功",
            ["游戏"] = scriptConfig.Name
        })
    else
        printBox("脚本加载错误", {
            ["状态"] = "❌ 加载失败",
            ["错误信息"] = err,
            ["操作"] = "触发默认脚本"
        })
        
        notify("⚠️ 加载失败", "触发默认脚本", 3)
        loadstring(game:HttpGet(DEFAULT_SCRIPT))()
    end
else
    printBox("默认脚本加载", {
        ["状态"] = "当前游戏未在支持列表中",
        ["操作"] = "加载 Player Info 脚本"
    })
    
    notify("🔧 默认加载", "Player Info", 3)
    loadstring(game:HttpGet(DEFAULT_SCRIPT))()
end

print("\n🎊 脚本加载流程完成 🎊")

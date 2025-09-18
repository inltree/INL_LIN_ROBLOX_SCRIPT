--[[
    脚本名称：inltree｜Lin 游戏脚本加载器
    脚本版本：1.1.0
    脚本作者：inltree｜Lin×DeepSeek
    核心功能：根据当前Roblox游戏ID，自动匹配并加载对应远程脚本，支持多游戏配置管理
]]
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SCRIPT_LOADER_INFO = {
    DESCRIPTION = "inltree｜Lin｜脚本加载器",
    VERSION = "1.1.0",
    AUTHOR = "inltree｜Lin×DeepSeek",
    NOTIFICATION_DURATION = {
        LOADING = 3,
        MATCH_SUCCESS = 3,
        FAIL = 8
    }
}

local GAME_CONFIG = {
    [4483381587] = {
        Name = "一个字面上的底板。｜(a literal baseplate.)",
        ScriptUrl = ""
    },
    [126884695634066] = {
        Name = "种植花园｜(Grow a Garden)",
        ScriptUrl = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Grow_a_Garden.lua"
    },
    [76455837887178] = {
        Name = "挖掘它｜(Dig it)",
        ScriptUrl = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Dig_it.lua"
    },
    [99078474560152] = {
        Name = "M.E.G.无尽现实｜(M.E.G. Endless Reality)",
        ScriptUrl = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/M.E.G._Endless_Reality.lua"
    }
}

local function printFormattedLog(title: string, content: {[string]: string|number})
    local logLines = {("="):rep(40), ("- 标题: %s"):format(title)}
    for key, value in pairs(content) do
        table.insert(logLines, ("- %s: %s"):format(key, value))
    end
    table.insert(logLines, ("="):rep(40))
    print("\n" .. table.concat(logLines, "\n"))
end

local function sendNotification(title: string, text: string, duration: number)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

local initLogContent = {
    ["游戏名称"] = "未知游戏",
    ["描述"] = SCRIPT_LOADER_INFO.DESCRIPTION,
    ["版本"] = SCRIPT_LOADER_INFO.VERSION,
    ["作者"] = SCRIPT_LOADER_INFO.AUTHOR,
    ["执行时间"] = os.date("%H:%M:%S")
}

local currentGameId = game.PlaceId
local gameName = "未知游戏"
local success, gameInfo = pcall(function()
    return MarketplaceService:GetProductInfo(currentGameId)
end)
if success and gameInfo then
    gameName = gameInfo.Name or gameName
    initLogContent["游戏名称"] = gameName
else
    warn(("获取游戏信息失败：%s"):format(gameInfo or "未知错误"))
end

printFormattedLog("加载器初始化中", initLogContent)
sendNotification(
    gameName,
    "inltree｜" .. gameName .. " Script Loading...｜加载中...",
    SCRIPT_LOADER_INFO.NOTIFICATION_DURATION.LOADING
)

local scriptConfig = GAME_CONFIG[currentGameId]
local supportedCount = 0
for _ in pairs(GAME_CONFIG) do
    supportedCount += 1
end

if scriptConfig then
    printFormattedLog("匹配成功", {
        ["游戏名称"] = scriptConfig.Name,
        ["游戏ID"] = currentGameId,
        ["脚本URL"] = scriptConfig.ScriptUrl,
        ["状态"] = "正在加载",
        ["加载时间"] = os.date("%H:%M:%S")
    })
    sendNotification(
        gameName,
        "游戏地图｜匹配成功",
        SCRIPT_LOADER_INFO.NOTIFICATION_DURATION.MATCH_SUCCESS
    )

    local loadSuccess, loadErr = pcall(function()
        local scriptContent = game:HttpGet(scriptConfig.ScriptUrl, true)
        loadstring(scriptContent)()
    end)

    if loadSuccess then
        printFormattedLog("加载完成", {
            ["游戏名称"] = scriptConfig.Name,
            ["状态"] = "加载成功",
            ["完成时间"] = os.date("%H:%M:%S")
        })
        sendNotification(
            gameName,
            scriptConfig.Name .. "｜加载完成",
            SCRIPT_LOADER_INFO.NOTIFICATION_DURATION.LOADING
        )
    else
        local errMsg = ("脚本加载失败：%s"):format(loadErr)
        warn(errMsg)
        sendNotification(
            "加载失败",
            "详情请查看控制台",
            SCRIPT_LOADER_INFO.NOTIFICATION_DURATION.FAIL
        )
    end
else
    printFormattedLog("游戏不支持", {
        ["当前游戏"] = gameName,
        ["游戏ID"] = currentGameId,
        ["支持游戏数量"] = supportedCount,
        ["状态"] = "终止加载",
        ["终止时间"] = os.date("%H:%M:%S")
    })
    sendNotification(
        gameName,
        ("当前地图不在列表｜详细信息见控制台\n支持 %d 游戏"):format(supportedCount),
        SCRIPT_LOADER_INFO.NOTIFICATION_DURATION.FAIL
    )
    print("\n支持游戏列表:\n" .. ("="):rep(40))
    local index = 1
    for gameId, config in pairs(GAME_CONFIG) do
        warn(("%2d. %s (ID: %d)"):format(index, config.Name, gameId))
        index += 1
    end
end

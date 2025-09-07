local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- 游戏配置表
local GAME_CONFIG = {
    [4483381587] = {
        name = "一个字面上的底板。｜(a literal baseplate.)", 
        scriptUrl = ""
    },
    [126884695634066] = {
        name = "种植花园｜(Grow a Garden)",
        scriptUrl = "https://raw.githubusercontent.com/InLTree/LinRobloxScript/main/Grow_a_Garden.lua"
    },
    [76455837887178] = {
        name = "挖掘它｜(Dig it)",
        scriptUrl = "https://raw.githubusercontent.com/InLTree/LinRobloxScript/refs/heads/main/Dig_it.lua"
    },
    [99078474560152] = {
        name = "M.E.G.无尽现实｜(M.E.G. Endless Reality)", 
        scriptUrl = "https://raw.githubusercontent.com/InLTree/LinRobloxScript/refs/heads/main/M.E.G._Endless_Reality.lua"
    }
    
}

-- 获取当前游戏信息
local currentGameId = game.PlaceId
local gameInfo = MarketplaceService:GetProductInfo(currentGameId)
local gameName = gameInfo.Name or "未知游戏"

-- 初始化打印
warn("\n"..(("="):rep(40).."\n- 游戏名称: "..gameName.."\n- 描述: inltree｜Lin｜脚本加载器\n- 版本: 1.0.0\n- 作者: inltree｜Lin×DeepSeek\n- 执行时间: "..os.date("%H:%M:%S").."\n"..("="):rep(40)))

StarterGui:SetCore("SendNotification", {
    Title = gameName,
    Text = "inltree｜"..gameName.." Script Loading...｜加载中...",
    Duration = 1
})

-- 检查游戏支持
local scriptConfig = GAME_CONFIG[currentGameId]
local supportedCount = 0
for _ in pairs(GAME_CONFIG) do supportedCount = supportedCount + 1 end

if scriptConfig then
    print("\n"..(("="):rep(40).."\n- 游戏名称: "..scriptConfig.name.."\n- 游戏ID: "..currentGameId.."\n- 脚本URL: "..scriptConfig.scriptUrl.."\n- 状态: 正在加载\n- 加载时间: "..os.date("%H:%M:%S").."\n"..("="):rep(40)))
    
    StarterGui:SetCore("SendNotification", {
        Title = gameName,
        Text = "游戏地图｜匹配成功",
        Duration = 5
    })
    
    -- 加载并执行脚本
    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptConfig.scriptUrl, true))()
    end)
    
    if success then
        print("\n"..(("="):rep(40).."\n- 游戏名称: "..scriptConfig.name.."\n- 状态: 加载成功\n- 完成时间: "..os.date("%H:%M:%S").."\n"..("="):rep(40)))
        
        StarterGui:SetCore("SendNotification", {
            Title = gameName,
            Text = scriptConfig.name.."｜加载完成",
            Duration = 1
        })
    else
        warn("脚本加载失败: ", err)
        StarterGui:SetCore("SendNotification", {
            Title = "加载失败",
            Text = "详情请查看控制台",
            Duration = 8
        })
    end
else
    -- 不支持游戏打印
    print("\n"..(("="):rep(40).."\n- 当前游戏: "..gameName.."\n- 游戏ID: "..currentGameId.."\n- 支持游戏数量: "..supportedCount.."\n- 状态: 终止加载\n- 终止时间: "..os.date("%H:%M:%S").."\n"..("="):rep(40)))
    
    StarterGui:SetCore("SendNotification", {
        Title = gameName,
        Text = "当前地图不在列表｜详细信息见控制台\n〉支持 "..supportedCount.." 游戏〈",
        Duration = 8
    })
    
    -- 打印支持列表
    print("支持游戏列表:\n"..("="):rep(40))
    local i = 1
    for id, config in pairs(GAME_CONFIG) do
        warn(string.format("%2d. %s (ID: %d)", i, config.name, id))
        i = i + 1
    end
end

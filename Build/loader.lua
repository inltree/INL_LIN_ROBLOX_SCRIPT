--[[
    inltree｜Lin 脚本加载器
    版本：2.0.0
]]
local CONFIG_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Game_Config.lua"
local DEFAULT_SCRIPT = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_Tools/Player_Info.lua"

local Games = loadstring(game:HttpGet(CONFIG_URL))()
local ScriptURL = Games[game.PlaceId]

if ScriptURL then
    print("🎯 inltree｜Lin - 加载游戏脚本")
    loadstring(game:HttpGet(ScriptURL))()
else
    print("🔧 inltree｜Lin - 加载默认脚本")
    loadstring(game:HttpGet(DEFAULT_SCRIPT))()
end

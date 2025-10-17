local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
local gameName = ok and info.Name or "Unknown Game"
pcall(function() StarterGui:SetCore("SendNotification", {Title = gameName, Text = "inltree｜"..gameName.." Script Loading...｜加载中...", Duration = 3}) end)

local DEFAULT_SCRIPT_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_Tools/Player_Info.lua"
local CONFIG_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Game_Config.lua"

local function loadScript(url) return pcall(function() loadstring(game:HttpGet(url))() end) end

local configSuccess, gameConfigs = pcall(function() return loadstring(game:HttpGet(CONFIG_URL))() end)
if not configSuccess then loadScript(DEFAULT_SCRIPT_URL) return end

local gameConfig = gameConfigs[game.PlaceId]
if gameConfig and gameConfig.ScriptUrl and gameConfig.ScriptUrl ~= "" then
    if loadScript(gameConfig.ScriptUrl) then print("Loaded: "..gameConfig.Name.." Game PlaceId: "..game.PlaceId) else loadScript(DEFAULT_SCRIPT_URL) end
else
    warn("No script for this game. Supported:")
    for _,cfg in pairs(gameConfigs) do if cfg.Name then print("- "..cfg.Name.." Game PlaceId: "..game.PlaceId) end end
    loadScript(DEFAULT_SCRIPT_URL)
end

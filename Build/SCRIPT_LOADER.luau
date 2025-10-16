local DEFAULT_SCRIPT_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_Tools/Player_Info.lua"
local success, Games = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Game_Config.lua"))()
end)

if not success then
    warn("Failed to load game config:", Games)
    local ok, err = pcall(function()
        loadstring(game:HttpGet(DEFAULT_SCRIPT_URL))()
    end)
    if not ok then
        warn("Failed to load default script:", err)
    end
    return
end

local GameConfig = Games[game.PlaceId]

if GameConfig and GameConfig.ScriptUrl and GameConfig.ScriptUrl ~= "" then
    local scriptSuccess, err = pcall(function()
        loadstring(game:HttpGet(GameConfig.ScriptUrl))()
    end)
    if scriptSuccess then
        print("Successfully executed script for:", GameConfig.Name)
    else
        warn("Failed to load game script:", err)
        local ok, defaultErr = pcall(function()
            loadstring(game:HttpGet(DEFAULT_SCRIPT_URL))()
        end)
        if ok then
            print("Fallback to default script.")
        else
            warn("Failed to load default script:", defaultErr)
        end
    end
else
    warn("No script configured for this game. Supported games:")
    for _, cfg in pairs(Games) do
        print("-", cfg.Name)
    end
    local ok, defaultErr = pcall(function()
        loadstring(game:HttpGet(DEFAULT_SCRIPT_URL))()
    end)
    if ok then
        print("Fallback to default script.")
    else
        warn("Failed to load default script:", defaultErr)
    end
end

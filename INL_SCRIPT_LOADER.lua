local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local function showNotification(type, title, message, level)
    if type == "notify" then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = message,
                Duration = 3
            })
        end)
        return true
    elseif type == "print" then
        local prefix = level and ("[inltree] " .. level .. " ") or "[inltree] "
        print(prefix .. title .. (message and (" " .. message) or ""))
        return true
    elseif type == "warn" then
        local prefix = level and ("[inltree] " .. level .. " ") or "[inltree] "
        warn(prefix .. title .. (message and (" " .. message) or ""))
        return true
    end
    return false
end

local isSuccess, gameInfo = pcall(function() 
    return MarketplaceService:GetProductInfo(game.PlaceId) 
end)
local gameName = isSuccess and gameInfo.Name or "Unknown Game"

showNotification("notify", gameName, "inltree｜"..gameName.." is loading...")
showNotification("print", "▶️ Loading script for:", gameName, "(PlaceId: " .. game.PlaceId .. ")")

local DEFAULT_SCRIPT_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_Tools/Player_Info.lua"
local CONFIG_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Script_Config.lua"

local function loadScriptFromUrl(url)
    local success, response = pcall(function() 
        return game:HttpGet(url) 
    end)
    if not success or response == "" then 
        return false 
    end
    local loadedFunction = loadstring(response)
    return loadedFunction and select(1, pcall(loadedFunction))
end

local configLoadedSuccessfully, gameConfig = pcall(function() 
    return loadstring(game:HttpGet(CONFIG_URL))() 
end)

if not configLoadedSuccessfully or type(gameConfig) ~= "table" then
    showNotification("warn", "❌ Failed to load config. Using default script.")
    showNotification("notify", "Config Load Failed", "Using default script. ❌")
    loadScriptFromUrl(DEFAULT_SCRIPT_URL)
    return
end

local function displaySupportedGamesList()
    showNotification("print", "📜 Supported Games:")
    for placeId, config in pairs(gameConfig) do
        if config.Name then 
            print("● " .. config.Name .. " (PlaceId: " .. placeId .. ")")
        end
    end
end

local currentGameData = gameConfig[game.PlaceId]

if currentGameData and currentGameData.ScriptUrl ~= "" then
    if loadScriptFromUrl(currentGameData.ScriptUrl) then
        showNotification("print", "✅ Script loaded successfully:", currentGameData.Name .. " (PlaceId: " .. game.PlaceId .. ")")
        showNotification("notify", gameName.." Loaded", "Script loaded successfully. ✅")
    else
        showNotification("warn", "⚠️ Script load failed. Using default script.")
        showNotification("notify", "Script Load Failed", "Using default script. ⚠️")
        loadScriptFromUrl(DEFAULT_SCRIPT_URL)
    end
    displaySupportedGamesList()
else
    showNotification("warn", "⚠️ No matching script found. Using default script.")
    displaySupportedGamesList()
    showNotification("notify", "No Matching Script", "Loaded default script. ⚠️")
    loadScriptFromUrl(DEFAULT_SCRIPT_URL)
end

-- Anti-AFK
if getconnections then
    for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
        if connection.Disable then
            connection:Disable()
        elseif connection.Disconnect then
            connection:Disconnect() 
        end
    end
else
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

showNotification("print", "✅ Anti Afk Successfully Enabled.")
showNotification("notify", "Anti-AFK", "Successfully Enabled. ✅")

local MPS = game:GetService("MarketplaceService")
local GUI = game:GetService("StarterGui")

local ok, info = pcall(function() return MPS:GetProductInfo(game.PlaceId) end)
local name = ok and info.Name or "Unknown Game"

pcall(function()
	GUI:SetCore("SendNotification", {Title = name, Text = "inltree｜"..name.." is loading...", Duration = 3})
end)
print("[inltree] ▶️ Loading script for:", name, "(PlaceId:", game.PlaceId .. ")")

local DEF_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_Tools/Player_Info.lua"
local CFG_URL = "https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Game_Config.lua"

local function loadURL(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if not ok or res == "" then return false end
	local fn = loadstring(res)
	return fn and select(1, pcall(fn))
end

local okCfg, cfg = pcall(function() return loadstring(game:HttpGet(CFG_URL))() end)
if not okCfg or type(cfg) ~= "table" then
	warn("[inltree] ❌ Failed to load config. Using default script.")
	GUI:SetCore("SendNotification", {Title = "Config Load Failed", Text = "Using default script.", Duration = 4})
	loadURL(DEF_URL)
	return
end

local function printList()
	print("\n[inltree] 📜 Supported Games:")
	for id, c in pairs(cfg) do
		if c.Name then print("   ● " .. c.Name .. " (PlaceId: " .. id .. ")") end
	end
end

local data = cfg[game.PlaceId]
if data and data.ScriptUrl ~= "" then
	if loadURL(data.ScriptUrl) then
		print("[inltree] ✅ Script loaded successfully:", data.Name, "(PlaceId:", game.PlaceId .. ")")
		GUI:SetCore("SendNotification", {Title = name.." Loaded", Text = "Script loaded successfully ✅", Duration = 4})
	else
		warn("[inltree] ⚠️ Script load failed. Using default script.")
		GUI:SetCore("SendNotification", {Title = "Script Load Failed", Text = "Using default script.", Duration = 4})
		loadURL(DEF_URL)
	end
	printList()
else
	warn("[inltree] ⚠️ No matching script found. Using default script.")
	printList()
	GUI:SetCore("SendNotification", {Title = "No Matching Script", Text = "Loaded default script.", Duration = 4})
	loadURL(DEF_URL)
end

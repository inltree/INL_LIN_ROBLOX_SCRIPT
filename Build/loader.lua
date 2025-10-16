local Games = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Config/Game_Config.lua"))()

local URL = Games[game.PlaceId]

if URL and URL ~= "" then
  loadstring(game:HttpGet(URL))()
else
  warn("No script configured for this game.")
end

--[[
   不要按按钮四自动胜利 v1.1.12
   Made by inltree | Lin & ChatGPT
]]
local cfg = {
	mainInterval = 0.5,   -- 地图监控间隔
	coinInterval = 0.1,   -- 硬币触碰间隔
	pathInterval = 0.1,   -- 固定路径扫描间隔
	winInterval = 0.3,    -- 胜利触发间隔
	dangerInterval = 0.1, -- 伤害删除间隔
	winLimit = 3,         -- 每张地图胜利触发次数上限
	debug = false          -- 调试模式
}

local plr = game.Players.LocalPlayer
local curMap = nil
local winCount = 0
local lastPathMap = nil

local WIN = {"win","winpatr","winpar","winner","thewin","winwin","winpart","winbrick","winning","wpart","victory","finish","end","CastleChest","complete","teleportout","escaped"}
local COIN = {"coin","pumpkin","money","cash","reward","point","score"}
local DAG = {"cube","cactus","die","death","explode","kill","hurt","poison","lava","laser","lightorb","QuickSand","spike","trap","thorn"}

-- 🧭 固定路径表
local MAP_PATHS = {
    Map19 = {"Win"},
	Map87 = {"Shapes"},
	Map92 = {"Rings"},
	Map98 = {"Pads"},
	Map110 = {"Blocks"},
	Map113 = {"TheCandy"},
	Map114 = {"Fireworks"},
	Map115 = {"CurrentLeaks"},
	Map116 = {"Spawns"},
	Map149 = {"UsedPresent"}
}
--[[]
    Map91 = {"REWARD"} -- 抢劫银行
workspace.Map91.TeleportOut -- 抢劫银行
    Map142 = {"FadingPlatforms"} -- 有点缺德
]]

-- 美化打印函数
local function inltreeLog(emoji, category, message)
	print("[不要按按钮四] " .. emoji .. " [" .. category .. "] " .. message)
end

-- 名称匹配函数
local function has(str, tbl)
	for _, v in ipairs(tbl) do
		if string.find(string.lower(str), string.lower(v)) then
			return true
		end
	end
end

-- 查找当前地图
local function findMap()
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") and v.Name:match("^Map%d+$") then
			return v
		end
	end
end

-- 安全触碰
local function touch(tt, hrp)
	pcall(function()
		firetouchinterest(tt.Parent, hrp, 0)
		task.wait(0.05)
		firetouchinterest(tt.Parent, hrp, 1)
	end)
end

-- 扫描对象下的触碰控件
local function triggerUnder(obj, hrp)
	for _, v in ipairs(obj:GetDescendants()) do
		if v:IsA("TouchTransmitter") then
			touch(v, hrp)
		end
	end
end

-- 🚫 伤害删除线程（最高优先级）
task.spawn(function()
	while true do
		local map = findMap()
		if map then
			pcall(function()
				-- 递归删除伤害物体
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

-- 🏆 胜利触发线程
task.spawn(function()
	while true do
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

				local c = plr.Character
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

-- 🪙 硬币触发线程
task.spawn(function()
	while true do
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

				local c = plr.Character
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

-- 🧭 固定路径线程
task.spawn(function()
	local function safeFindPath(startObj, pathStr)
		local obj = startObj
		for seg in string.gmatch(pathStr, "[^%.]+") do
			if not obj then return nil end
			obj = obj:FindFirstChild(seg)
		end
		return obj
	end

	while true do
		local map = findMap()
		if map then
			local mapName = map.Name
			if mapName ~= lastPathMap then
				lastPathMap = nil
			end

			local paths = MAP_PATHS[mapName]
			if paths then
				local c = plr.Character
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

-- 🎯 地图监控线程（主控）
task.spawn(function()
	while true do
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

-- 启动消息
inltreeLog("🚀", "系统启动", "自动胜利脚本已启动 - 多线程优化版")
inltreeLog("⚙️", "配置信息", "调试模式: " .. tostring(cfg.debug))

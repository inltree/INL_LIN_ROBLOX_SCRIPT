local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local TARGET_COINS = 15
local isCollecting = false

local function startCollectingCoins()
    if isCollecting then
        return
    end

    local matchCurrency = LocalPlayer:FindFirstChild("MatchCurrency")
    if not matchCurrency or matchCurrency.Value >= TARGET_COINS then
        return
    end

    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end

    isCollecting = true
    print("[inltree] ℹ️ 开始使用收集金币...")

    repeat
        for _, descendant in ipairs(Workspace.Gems:GetDescendants()) do
            if not isCollecting or matchCurrency.Value >= TARGET_COINS then
                break
            end

            if descendant.Name == "TouchInterest" and descendant.Parent and descendant.Parent:IsA("BasePart") then
                firetouchinterest(humanoidRootPart, descendant.Parent, 0)
                task.wait(0.02)
                firetouchinterest(humanoidRootPart, descendant.Parent, 1)
            end
        end
        task.wait(0.1)
    until matchCurrency.Value >= TARGET_COINS or not isCollecting

    isCollecting = false
    print("[inltree] 🎉 金币收集完成！当前数量：", matchCurrency.Value)
end

Workspace.Time.Changed:Connect(function(currentTime)
    if currentTime == 119 then
        startCollectingCoins()
    elseif currentTime < 10 then
        isCollecting = false
    end
end)

LocalPlayer.CharacterAdded:Connect(startCollectingCoins)

startCollectingCoins()

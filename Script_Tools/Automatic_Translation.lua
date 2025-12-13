--[[
    借鉴作者源码：「Kenny」「黑洞中心」特别感谢！
    作者: inltree｜Lin × AI
]]

-- 服务变量
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 加载库
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Tora_Library/Tora_Library.lua", true))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Notification_Library/Notification_Library.luau"))()

-- 状态/配置
local isAutoTranslateEnabled = false
local isSystemEnabled = true
local TargetLanguageCode = "zh-CN"
local TranslationCache = {}
local TranslatedGuiSet = {}
local OriginalTextMap = {}

-- 优化频率限制配置
local TranslationConfig = {
    minRequestInterval = 0.1,      -- 最小间隔0.1秒
    maxRequestsPerWindow = 10,     -- 增加窗口内最大请求数10
    windowDuration = 1,            -- 增加时间窗口1秒
    maxTextLength = 100            -- 增加最大文本长度100
}

local LastRequestTime = 0
local RequestTimestamps = {}

-- 优化频率限制控制器 - 修复卡死问题
local function WaitForRateLimit()
    if not isSystemEnabled then return end
    
    local now = os.clock()

    -- 清理过期请求
    for i = #RequestTimestamps, 1, -1 do
        if now - RequestTimestamps[i] > TranslationConfig.windowDuration then
            table.remove(RequestTimestamps, i)
        end
    end

    -- 使用非阻塞方式等待窗口可用
    local waitStart = os.clock()
    while #RequestTimestamps >= TranslationConfig.maxRequestsPerWindow do
        -- 添加超时保护，避免无限等待
        if os.clock() - waitStart > 5 then
            Notification:SendNotification("Warning", "频率限制超时，跳过等待", 2)
            break
        end
        
        task.wait(0.05)  -- 减少等待时间
        now = os.clock()
        for i = #RequestTimestamps, 1, -1 do
            if now - RequestTimestamps[i] > TranslationConfig.windowDuration then
                table.remove(RequestTimestamps, i)
            end
        end
    end

    -- 最小调用间隔
    local sinceLast = now - LastRequestTime
    if sinceLast < TranslationConfig.minRequestInterval then
        task.wait(math.min(TranslationConfig.minRequestInterval - sinceLast, 0.5))
    end

    LastRequestTime = os.clock()
    table.insert(RequestTimestamps, LastRequestTime)
end

-- 语言选项
local LanguageOptions = {
    { display = "中文 (简体)", code = "zh-CN" },
    { display = "中文 (繁体)", code = "zh-TW" },
    { display = "English",    code = "en"    },
    { display = "日本語",      code = "ja"    },
    { display = "한국어",      code = "ko"    },
    { display = "Русский",    code = "ru"    },
    { display = "Español",    code = "es"    },
    { display = "Français",   code = "fr"    },
    { display = "Deutsch",    code = "de"    },
    { display = "Português",  code = "pt"    },
    { display = "Italiano",   code = "it"    },
    { display = "العربية",    code = "ar"    },
    { display = "हिन्दी",      code = "hi"    },
    { display = "Türkçe",     code = "tr"    },
    { display = "ไทย",        code = "th"    },
    { display = "Tiếng Việt", code = "vi"    },
}

local DisplayToLangCode = {}
local LanguageDisplayList = {}

for _, lang in ipairs(LanguageOptions) do
    DisplayToLangCode[lang.display] = lang.code
    table.insert(LanguageDisplayList, lang.display)
end

-- 语言检测
local function DetectSourceLanguage(text)
    if text:match("[\228-\233][\128-\191][\128-\191]") then
        return "zh-CN"
    elseif text:match("[\227][\129-\131]") then
        return "ja"
    elseif text:match("[\234-\237][\128-\191]") then
        return "ko"
    elseif text:match("[\208-\209][\128-\191]") then
        return "ru"
    elseif text:match("[A-Za-z]") then
        return "en"
    end
    return "auto"
end

-- 优化翻译功能
local function TranslateText(text)
    if not text or text == "" then return text end
    if TranslationCache[text] then return TranslationCache[text] end
    if #text > TranslationConfig.maxTextLength then
        task.spawn(function()
            Notification:SendNotification("Warning", "文本过长跳过翻译 ("..#text.." > "..TranslationConfig.maxTextLength..")", 3)
        end)
        return text
    end

    local sourceLang = DetectSourceLanguage(text)
    if sourceLang == TargetLanguageCode then
        TranslationCache[text] = text
        return text
    end

    local success, result = pcall(function()
        WaitForRateLimit()
        
        local ok, response = pcall(function()
            local url = string.format(
                "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=%s&dt=t&q=%s",
                TargetLanguageCode,
                HttpService:UrlEncode(text)
            )
            return game:HttpGet(url)
        end)

        if ok and response then
            local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, response)
            if decodeSuccess and data and data[1] then
                local translatedResult = ""
                for _, seg in ipairs(data[1]) do
                    if seg[1] then
                        translatedResult ..= seg[1]
                    end
                end
                TranslationCache[text] = translatedResult
                return translatedResult
            end
        end
        return text
    end)
    
    if success then
        TranslationCache[text] = result
        return result
    else
        TranslationCache[text] = text
        return text
    end
end

-- 优化GUI翻译
local function TranslateGuiIfNeeded(gui)
    if not isSystemEnabled or not isAutoTranslateEnabled then return end
    if TranslatedGuiSet[gui] then return end
    if not gui:IsDescendantOf(game) then return end

    if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
        local originalText = gui.Text
        if originalText and originalText ~= "" then
            if not OriginalTextMap[gui] then
                OriginalTextMap[gui] = originalText
            end

            TranslatedGuiSet[gui] = true
            
            task.spawn(function()
                local success, translatedText = pcall(function()
                    return TranslateText(originalText)
                end)
                
                if success and gui and gui.Parent then
                    pcall(function()
                        gui.Text = translatedText
                    end)
                end
            end)
        end
    end
end

-- 恢复/重新翻译
local function RestoreAllTexts(silent)
    local count = 0
    for gui, originalText in pairs(OriginalTextMap) do
        if gui and gui.Parent then
            pcall(function()
                gui.Text = originalText
                count += 1
            end)
        end
    end

    TranslationCache = {}
    TranslatedGuiSet = {}

    if not silent then
        Notification:SendNotification("Info", "成功还原 " .. count .. " 文本", 3)
    end
end

-- 优化重新翻译函数 - 添加分批处理和进度提示
local function RetranslateAllTrackedGuis()
    if not isAutoTranslateEnabled then
        Notification:SendNotification("Warning", "启动自动翻译", 3)
        return
    end

    local reTranslateNotification = Notification:SendNotification("Info", "正在重新翻译中...", 3)
    
    RestoreAllTexts(true)
    task.wait(0.2)

    local totalCount = 0
    for _ in pairs(OriginalTextMap) do totalCount += 1 end
    
    if totalCount == 0 then
        if reTranslateNotification and reTranslateNotification.Close then
            reTranslateNotification:Close()
        end
        Notification:SendNotification("Info", "未成功检索文本", 3)
        return
    end

    local processedCount = 0
    local batchSize = 5
    
    for gui, originalText in pairs(OriginalTextMap) do
        if gui and gui.Parent then
            TranslatedGuiSet[gui] = true
            
            task.spawn(function()
                local success, translatedText = pcall(function()
                    return TranslateText(originalText)
                end)
                
                if success and gui and gui.Parent then
                    pcall(function()
                        gui.Text = translatedText
                        processedCount += 1
                        
                        -- 每完成一批更新进度
                        if processedCount % batchSize == 0 then
                            local progress = math.floor((processedCount / totalCount) * 100)
                            Notification:SendNotification("Info", 
                                string.format("翻译进度: %d/%d (%d%%)", processedCount, totalCount, progress), 1)
                        end
                    end)
                else
                    processedCount += 1
                end
            end)
            
            if processedCount % batchSize == 0 then
                task.wait(0.1)
            end
        end
    end

    -- 等待所有翻译完成（带超时）
    local startTime = os.clock()
    while processedCount < totalCount and os.clock() - startTime < 30 do
        task.wait(0.5)
    end

    if reTranslateNotification and reTranslateNotification.Close then
        reTranslateNotification:Close()
    end

    Notification:SendNotification("Success", 
        string.format("重新翻译成功: %d/%d 个文本", processedCount, totalCount), 3)
end

-- GUI监听器优化
local function BindGuiListener(root)
    root.DescendantAdded:Connect(function(gui)
        task.defer(TranslateGuiIfNeeded, gui)
    end)

    -- 分批处理现有元素避免卡死
    local descendants = root:GetDescendants()
    local batchSize = 10
    
    for i = 1, #descendants, batchSize do
        for j = i, math.min(i + batchSize - 1, #descendants) do
            task.defer(TranslateGuiIfNeeded, descendants[j])
        end
        task.wait(0.05)  -- 批次间延迟
    end
end

-- 系统关闭函数
local function ShutdownSystem()
    isSystemEnabled = false
    isAutoTranslateEnabled = false
    RestoreAllTexts(true)
    Library:Close()
    Notification:SendNotification("Warning", "自动翻译成功关闭！", 5)
end

-- 初始化监听
task.spawn(function()
    BindGuiListener(PlayerGui)
    BindGuiListener(CoreGui)
end)

-- UI界面
local Window = Library:CreateWindow("自动翻译")

local TranslateTab = Window:AddFolder("翻译设置")

TranslateTab:AddToggle({
    text = "自动翻译(启用后再执行对应脚本)",
    callback = function(state)
        isAutoTranslateEnabled = state
        Notification:SendNotification(state and "Success" or "Warning", state and "自动翻译启用" or "自动翻译关闭", 3)
    end
})

TranslateTab:AddList({
    text = "目标语言",
    values = LanguageDisplayList,
    default = "中文 (简体)",
    callback = function(choice)
        TargetLanguageCode = DisplayToLangCode[choice] or "zh-CN"
        TranslationCache = {}
        TranslatedGuiSet = {}
        Notification:SendNotification("Info", "目标语言: " .. choice, 3)
    end
})

TranslateTab:AddButton({
    text = "重新翻译",
    callback = function()
        Notification:SendNotification("Info", "重新翻译中...", 2)
        RetranslateAllTrackedGuis()
    end
})

TranslateTab:AddButton({
    text = "还原原文",
    callback = function()
        RestoreAllTexts(false)
    end
})

TranslateTab:AddButton({
    text = "关闭面板",
    callback = ShutdownSystem
})

local ConfigTab = Window:AddFolder("性能配置")

ConfigTab:AddSlider({
    text = "API调用间隔(秒)",
    min = 0.1, 
    max = 5.0,
    default = TranslationConfig.minRequestInterval,
    callback = function(value)
        TranslationConfig.minRequestInterval = value
        Notification:SendNotification("Info", "调用间隔: " .. value .. "秒", 2)
    end
})

ConfigTab:AddSlider({
    text = "最大请求数",
    min = 10,
    max = 50, 
    default = TranslationConfig.maxRequestsPerWindow,
    callback = function(value)
        TranslationConfig.maxRequestsPerWindow = math.floor(value)
        Notification:SendNotification("Info", "最大请求数: " .. math.floor(value), 2)
    end
})

ConfigTab:AddSlider({
    text = "请求速度(秒)", 
    min = 1,
    max = 5,
    default = TranslationConfig.windowDuration, 
    callback = function(value)
        TranslationConfig.windowDuration = value
        Notification:SendNotification("Info", "请求速度: " .. value .. "秒", 2)
    end
})

ConfigTab:AddSlider({
    text = "翻译长度", 
    min = 100,
    max = 500,
    default = TranslationConfig.maxTextLength, 
    callback = function(value)
        TranslationConfig.maxTextLength = math.floor(value)
        Notification:SendNotification("Info", "翻译长度: " .. math.floor(value), 2)
    end
})

ConfigTab:AddButton({
    text = "重置配置",
    callback = function()
        TranslationConfig = {
            minRequestInterval = 0.1,
            maxRequestsPerWindow = 10,
            windowDuration = 1,
            maxTextLength = 100
        }
        Notification:SendNotification("Success", "成功重置设置", 3)
    end
})

Library:Init()

-- 安全初始化
task.spawn(function()
    task.wait(1)
    Notification:SendNotification("Success", "自动翻译成功加载！", 5)
end)

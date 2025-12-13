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

local TranslationConfig = {
    minRequestInterval = 0.1,
    maxRequestsPerWindow = 10,
    windowDuration = 1,
    maxTextLength = 100
}

local LastRequestTime = 0
local RequestTimestamps = {}

local function WaitForRateLimit()
    if not isSystemEnabled then return end
    local now = os.clock()
    for i = #RequestTimestamps, 1, -1 do
        if now - RequestTimestamps[i] > TranslationConfig.windowDuration then
            table.remove(RequestTimestamps, i)
        end
    end

    while #RequestTimestamps >= TranslationConfig.maxRequestsPerWindow do
        task.wait(0.1)
        now = os.clock()
        for i = #RequestTimestamps, 1, -1 do
            if now - RequestTimestamps[i] > TranslationConfig.windowDuration then
                table.remove(RequestTimestamps, i)
            end
        end
    end

    local sinceLast = now - LastRequestTime
    if sinceLast < TranslationConfig.minRequestInterval then
        task.wait(TranslationConfig.minRequestInterval - sinceLast)
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

-- 翻译功能
local function TranslateText(text)
    if not text or text == "" then return text end
    if TranslationCache[text] then return TranslationCache[text] end
    if #text > TranslationConfig.maxTextLength then
        Notification:SendNotification("Warning", "文本过长跳过翻译 ("..#text.." > "..TranslationConfig.maxTextLength..")", 3)
        return text
    end

    local sourceLang = DetectSourceLanguage(text)
    if sourceLang == TargetLanguageCode then
        TranslationCache[text] = text
        return text
    end

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
        local success, data = pcall(HttpService.JSONDecode, HttpService, response)
        if success and data and data[1] then
            local result = ""
            for _, seg in ipairs(data[1]) do
                result ..= seg[1]
            end
            TranslationCache[text] = result
            return result
        end
    end

    TranslationCache[text] = text
    return text
end

-- GUI翻译
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
            pcall(function()
                gui.Text = TranslateText(originalText)
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

local function RetranslateAllTrackedGuis()
    if not isAutoTranslateEnabled then
        Notification:SendNotification("Warning", "启用自动翻译", 3)
        return
    end

    local reTranslateNotification = Notification:SendNotification("Info", "正在重新翻译中...", 10)
    
    RestoreAllTexts(true)
    task.wait(0.5)

    local count = 0
    for gui, originalText in pairs(OriginalTextMap) do
        if gui and gui.Parent then
            TranslatedGuiSet[gui] = true
            pcall(function()
                gui.Text = TranslateText(originalText)
                count += 1
            end)
        end
    end

    -- 关闭提示
    if reTranslateNotification and reTranslateNotification.Close then
        reTranslateNotification:Close()
    end

    Notification:SendNotification("Success", ("成功重新翻译 %d 文本"):format(count), 3)
end

local function ShutdownSystem()
    isSystemEnabled = false
    isAutoTranslateEnabled = false
    RestoreAllTexts(true)
    Library:Close()
    Notification:SendNotification("Warning", "自动翻译面板成功关闭", 5)
end

-- GUI监听器
local function BindGuiListener(root)
    root.DescendantAdded:Connect(function(gui)
        task.defer(TranslateGuiIfNeeded, gui)
    end)

    for _, gui in ipairs(root:GetDescendants()) do
        task.defer(TranslateGuiIfNeeded, gui)
    end
end

BindGuiListener(PlayerGui)
BindGuiListener(CoreGui)

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
        Notification:SendNotification("Info", "请等待！弹窗提示成功！", 3)
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

local ConfigTab = Window:AddFolder("翻译配置")

ConfigTab:AddSlider({
    text = "API调用间隔(秒)",
    min = 0.1, 
    max = 5.0,
    default = TranslationConfig.minRequestInterval,
    callback = function(value)
        TranslationConfig.minRequestInterval = value
        Notification:SendNotification("Info", "调用间隔: " .. value .. "秒", 3)
    end
})

ConfigTab:AddSlider({
    text = "最大请求",
    min = 10,
    max = 50, 
    default = TranslationConfig.maxRequestsPerWindow,
    callback = function(value)
        TranslationConfig.maxRequestsPerWindow = math.floor(value)
        Notification:SendNotification("Info", "最大请求: " .. math.floor(value), 3)
    end
})

ConfigTab:AddSlider({
    text = "请求速度(秒)", 
    min = 1,
    max = 30.0,
    default = TranslationConfig.windowDuration, 
    callback = function(value)
        TranslationConfig.windowDuration = value
        Notification:SendNotification("Info", "请求速度: " .. value .. "秒", 3)
    end
})

ConfigTab:AddSlider({
    text = "翻译长度", 
    min = 100,
    max = 512,
    default = TranslationConfig.maxTextLength, 
    callback = function(value)
        TranslationConfig.maxTextLength = math.floor(value)
        Notification:SendNotification("Info", "翻译长度: " .. math.floor(value), 3)
    end
})

Library:Init()

Notification:SendNotification("Success", "自动翻译加载成功！", 5)

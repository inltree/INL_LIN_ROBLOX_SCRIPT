# Tora Library
## 简单的 UI 库。具有简洁且时尚的界面(Tora Library)

- Made by Tora Is Me
- Github：https://github.com/liebertsx/Tora-Library/

### 配置库(Setup The Library)

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Tora_Library/Tora_Library.lua",true))()
```

### 添加标签页(Adding Tab)

```lua
local tab = library:CreateWindow("Your Title")
```

### 添加文件夹(Adding Folder)

```lua
local folder = tab:AddFolder("Folder")
```

### 添加按钮(Adding Button)

```lua
folder:AddButton({
    text = "点击我",
    flag = "button",
    callback = function()
        print("hello world")
    end
})
```

### 添加开关(Adding Toggle)

```lua
folder:AddToggle({
    text = "开关",
    flag = "toggle",
    callback = function(v)
        print(v)
    end
})
```

### 添加标签(Adding Label)

```lua
folder:AddLabel({
    text = "这很酷！",
    type = "label"
})
```

### 添加滑块(Adding Slider)

```lua
folder:AddSlider({
    text = "视野",
    min = 70,
    max = 170,
    dual = true,
    type = "slider",
    callback = function(v)
        print(v)
    end
})
```

### 添加文本框(Adding TextBox)

```lua
folder:AddColor({
    text = "颜色选择器",
    flag = "color",
    type = "color",
    callback = function(v)
        print(v)
    end
})
```

### 添加下拉菜单(Adding Dropdown)

```lua
folder:AddList({
    text = "颜色",
    values = {"红色", "绿色", "蓝色"},
    callback = function(value)
        print("已选择颜色:", value)
    end,
    open = false,
    flag = "color_option"
})
```

### 添加按键绑定(Adding Bind)

```lua
folder:AddBind({
    text = "绑定",
    key = "X",
    hold = false,
    callback = function()
    end
})
```

### 关闭库(Close Lib)

```lua
library:Close()
```

### 最终初始化 (必须执行，否则 UI 将不会显示)(Final (REQUIRED OR THE UI WILL NOT SHOW))

```lua
library:Init()
```

### 鸣谢：Tora(Credits : Tora Is Me)

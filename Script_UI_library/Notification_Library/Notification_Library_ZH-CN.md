# 通知库

首先，你需要加载这个库

```lua
local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/inltree/INL_LIN_ROBLOX_SCRIPT/main/Script_UI_library/Notification_Library/Notification_Library.luau"))()
```

然后你就可以使用 `SendNotification` 函数来发送通知

可用模式包括：
```
Success    成功
Warning    警告
Error       错误
Info        信息
```
你可以通过以下方式发送通知：
```lua
NotificationLibrary:SendNotification("Info", "我是条酷炫的消息", 3)
--NotificationLibrary:SendNotification(主题, 消息内容, 持续时间（秒）)
```
使用所有主题发送通知的示例如下：
```lua
NotificationLibrary:SendNotification("Success", "我是条酷炫的消息", 3)

NotificationLibrary:SendNotification("Warning", "我是条酷炫的消息", 3)

NotificationLibrary:SendNotification("Error", "我是条酷炫的消息", 3)

NotificationLibrary:SendNotification("Info", "我是条酷炫的消息", 3)
```

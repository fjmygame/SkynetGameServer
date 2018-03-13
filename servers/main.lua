
local skynet = require "skynet"

-- 启动服务(启动函数)
skynet.start(function()
    -- 启动函数里调用Skynet API开发各种服务
    print("======Server start=======")
    
    skynet.newservice("debug_console",8001)
    skynet.exit()
end)

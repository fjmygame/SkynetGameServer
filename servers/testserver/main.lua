
local skynet = require "skynet"
local debugport = tonumber(skynet.getenv("debugport") or "8888")

-- 启动服务(启动函数)
skynet.start(function()
    -- 启动函数里调用Skynet API开发各种服务
    print("======Server start=======")
    skynet.newservice("console")
    skynet.newservice("debug_console",debugport)
    skynet.newservice("mutil_c")    
    
    skynet.exit()
end)

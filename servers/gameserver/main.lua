
local skynet = require "skynet"

-- 启动服务(启动函数)
skynet.start(function()
    -- 启动函数里调用Skynet API开发各种服务
    print("======Server start=======")
    
    skynet.newservice("logservice")
    skynet.newservice("debug_console",8001)
    local watchdog = skynet.newservice("watchdog")
    skynet.call(watchdog,"lua", "start",{
          port=8200,
          maxclient=100,
          nodelay=true
          })
    skynet.exit()
end)

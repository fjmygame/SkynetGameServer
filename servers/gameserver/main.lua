
local skynet = require "skynet"
local cache_util = require "cache_util"

local logfilename = skynet.getenv("logfilename") or skynet.getenv("nodename") or "unknownsvr"

-- 启动服务(启动函数)
skynet.start(function()
    -- 启动函数里调用Skynet API开发各种服务
    print("======Server start=======")
    skynet.newservice("clustermgr")
    skynet.newservice("logservice")
    skynet.call(".logservice", "lua", "set_log_file", logfilename)
    skynet.newservice("debug_console",8001)

    skynet.uniqueservice("protoloader")
    skynet.newservice("constloader")
    local watchdog = skynet.newservice("watchdog")
    skynet.call(watchdog,"lua", "start",{
          port=8200,
          maxclient=100,
          nodelay=true
          })
    cache_util.init()
    skynet.exit()
end)

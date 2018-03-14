
local skynet = require "skynet"

-- 启动服务(启动函数)
skynet.start(function()
    -- 启动函数里调用Skynet API开发各种服务
    print("======Server start=======")
    
    skynet.newservice("debug_console",8001)
    skynet.newservice("socket1")
    skynet.newservice("myservice")
    skynet.newservice("myservice1")
    skynet.newservice("service2")
    skynet.send("SOCKETSERVER","lua","Test")
    skynet.call("SERVICE2","lua","set","a",1)
    local i = 0;
    --while true do 
    --  i = i>100000000 and 0 or i+1
    --  if i==0 then
    --     print("I am working")
    --  end
    --end
    skynet.error("skynet error wql")
    --skynet.fork(function()
    --    while true do
    --      skynet.sleep(1000)
    ---      skynet.send("SOCKETSERVER","lua","Wakeup")
     --     print("main send msg");
    --    end
    --end)
    skynet.exit()
end)

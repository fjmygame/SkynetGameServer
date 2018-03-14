local skynet = require "skynet"
require "skynet.manager"


local command = {}
function command.test()
   print("myService Test");
   return true;
end

skynet.start(function()
    print("==========myService Start=========")
    skynet.register "MYSERVER1"    
    skynet.fork(function()
         skynet.sleep(200)
         print("fork myService")
         skynet.call("MYSERVER","lua","Wakeup")
         print("call wakeup back")
    end)
end)

local skynet = require "skynet"
require "skynet.manager"

local command = {}
function command.TEST()
   print("myService Test");
   return true;
end

function command.WAKEUP()
   if command.threadid then
       print("wakeup thread")
       skynet.wakeup(command.threadid)
       skynet.sleep(300)
   end 
end
skynet.start(function()
    print("==========myService Start=========")
    skynet.dispatch("lua",function(session,address,cmd,...)
           local f = command[string.upper(cmd)]
           if f then
              skynet.ret(skynet.pack(f(...)))
           else
              print("error")
           end
    end);
    skynet.register "MYSERVER"    
    skynet.fork(function()
       while true do
           print("MyService");
           skynet.send(skynet.self(),"debug","GC")
           local threadid = coroutine.running()
           skynet.sleep(100);
           print("Sleep Back")
           command.threadid = threadid
           skynet.wait() 
           print("wait Back")
           --skynet.newservice("checkdeadloop")
       end
    end)
end)

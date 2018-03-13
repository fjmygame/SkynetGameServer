local skynet = require "skynet"
require "skynet.manager"

skynet.start(function() 
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
    	 
    end)

    skynet.register ".logservice"
end)

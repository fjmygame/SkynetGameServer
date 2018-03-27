local skynet = require "skynet"
local cluster = require "lkcluster"
require "skynet.manager"

local node,address = ...

skynet.register_protocol {
	name = "system",
	id = skynet.PTYPE_SYSTEM,
	unpack = function (...) return ... end,
}

local forward_map = {
	[skynet.PTYPE_SNAX] = skynet.PTYPE_SYSTEM,
	[skynet.PTYPE_LUA] = skynet.PTYPE_SYSTEM,
	[skynet.PTYPE_RESPONSE] = skynet.PTYPE_RESPONSE,
}

skynet.forward_type(forward_map, function()
	local clusterd = skynet.uniqueservice("lkclusterd")
	local n = tonumber(address)
	if n then
		address = n
    end
    skynet.dispatch("system", function(session,source,msg,sz) 
        skynet.ret(skynet.rawcall(clusterd, "lua", skynet.pack("req", node, address, msg, sz)))
    end)
end)
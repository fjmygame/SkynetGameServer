local skynet = require "skynet"
local cluster = require "lkcluster"

local mc = {
	send = cluster.send,
	call = cluster.call,
}


function mc.get(name)
    return skynet.call(".clustermgr", "lua", "get", name)
end

function mc.set(name,address)
    return skynet.call(".clustermgr", "lua", "set", name, address)
end

function mc.names(pat)
    return skynet.call(".clustermgr", "lua", "names", pat)
end

function mc.broadcast(pat,address,...)
    return cluster.broadcast(mc.names(pat), address, ...)
end

function mc.mcall(pat,address, ...)
    return cluster.mcall(mc.names(pat), address, ...)
end

return mc
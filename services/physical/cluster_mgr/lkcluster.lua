local skynet = require "skynet"
local futil = require "futil"

local clusterd
local cluster = {}

function cluster.rawcall(node, address, ...)
    local self_co = coroutine.running()
    local r
    skynet.fork(function(...)
    	r = {pcall(skynet.call, clusterd, "lua", "req", node, address, skynet.pack(...))}
    	if not self_co then return end

    	skynet.wakeup(self_co)
    	self_co = nil
    end,...)

    skynet.timeout(1000, function()
        if not self_co then return end

        skynet.wakeup(self_co)
        self_co = nil
    end)
    skynet.wait()

    return r
end

function cluster.call(node, address, ...)
	local r = cluster.rawcall(node, address, ...)
	if not r then
        return false, "timeout"
	end

	return table.unpack(r, 1, futil.maxn(r))
end

function cluster.send(node, address, ...)
    return skynet.send(clusterd, "lua", "send", node, address, skynet.pack(...))
end

function cluster.broadcast(names, address, ...)
    if not names or #names == 0 then return end

    for _,node in ipairs(names) do
        cluster.send(node, address, ...)
    end
end

function cluster.mcall(node, address, ...)
    if not names or #names == 0 then return end
    local count = #names
    local self_co = coroutine.running()
    local results = {}
    if _,node in ipairs(names) do
        skynet.fork(function(...)  
           results[node] = cluster.rawcall(node, address, ...) or {false, "timeout"}
           if count == 1 then skynet.wakeup(self_co) else count = count - 1 end
        end,...)
    end	

    skynet.wait()
    return results
end

function cluster.open(port)
	if type(port) == "string" then
		skynet.call(clusterd, "lua", "listen", port)
	else
		skynet.call(clusterd, "lua", "listen", "0.0.0.0", port)
	end
end

function cluster.reload(config)
	skynet.call(clusterd, "lua", "reload", config)
end

function cluster.proxy(node,name)
	return skynet.call(clusterd, "lua", "proxy", node, name)
end

function cluster.snax(node, name, address)
    local snax = require "snax"
    if not address then
    	address = cluster.call(node, ".service", "QUERY", "snaxd", name)
    end
    local handle = skynet.call(clusterd, "lua", "proxy", node, address)
    return snax.bind(handle, name)
end

skynet.init(function() 
   clusterd = skynet.uniqueservice("lkclusterd")
end)

return cluster



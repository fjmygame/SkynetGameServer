local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local logger = require "logger"

local CMD = {}
local SOCKET = {}
local gate
local wsgate = {}
local wswatchdogport = tonumber(skynet.getenv("wswatchdogport") or 0)
local state
local maxclient
local client_number = 0

local function close_agent(fd,no_wait)
	local a = agent[fd]
	if a then
       local ret = skynet.call(a,"lua","exit",no_wait)
       if ret.errCode == 0 then
           client_number = client_number - 1
           agent[fd] = nil
           skynet.kill(a)
           return true
       else
       	   return false
       end
	end
end

function SOCKET.open(fd,addr,sock_type)
	if not sock_type then
        sock_type = "BSD"
	end
	if client_number + 1 < maxclient then
        agent[fd] = skynet.newservice("agent")
        if sock_type == "BSD" then
        	skynet.call(agent[fd], "lua", "start", gate, fd, addr, sock_type)
        elseif sock_type == "WEBSOCKET" then
        	skynet.call(agent[fd], "lua", "start", wsgate, fd, addr, sock_type)
        end
        client_number = client_number + 1
    else
    	if sock_type == "BSD" then
        	skynet.call(gate, "lua", "kick", fd)
        elseif sock_type == "WEBSOCKET" then
        	skynet.call(wsgate, "lua", "kick", fd)
        end
	end
end

function SOCKET.close(fd)
	local a = agent[fd]
	if a then
		skynet.send(a,"lua","on_socket_close")
	    client_number = client_number-1
	end
	agent[fd] = nil
end

function SOCKET.error(fd,msg)
	local a = agent[fd]
	if a then
		skynet.send(a,"lua","on_socket_close")
	    client_number = client_number-1
	end
	agent[fd] = nil
end

function CMD.close_agent(fd,no_wait)
	return close_agent(fd,no_wait)
end

function CMD.redirect_agent(old_fd,fd,ip,sock_type)
	if not sock_type then
        sock_type = "BSD"
	end
	local a = agent[old_fd]
	if a then
        agent[old_fd] = nil
    	if sock_type == "BSD" then
        	skynet.call(gate, "lua", "kick", fd)
        elseif sock_type == "WEBSOCKET" then
        	skynet.call(wsgate, "lua", "kick", fd)
        end
        skynet.call(a,"lua","on_socket_redirect", fd, ip)
	end
end

function CMD.kick(fd,reason,sock_type)
	if not sock_type then
        sock_type = "BSD"
	end
    if sock_type == "BSD" then
    	skynet.call(gate, "lua", "kick", fd)
    elseif sock_type == "WEBSOCKET" then
    	skynet.call(wsgate, "lua", "kick", fd)
    end
	
	local user = agent[fd]
	if user then
        skynet.call(user, "lua", "kick", reason)
	end

	local res = close_agent(fd, true)
	if res then
		return {errCode = 0}
	else
		return {errCode = 1}
    end
end

function SOCKET.data(fd,msg)
	-- body
end

function CMD.start(conf)
	local ok,err = pcall(skynet.call,gate,"lua","open",conf)
	if not ok then
		logger.err("call gate failed")
		error(err)
	end
	if conf.wsport and conf.wsport ~= 0 then
		ok,err = pcall(skynet.call, wsgate, "lua", "open", conf)
		if not ok then
			logger.err("call wsgate failed")
		end
	end
	maxclient = conf.maxclient or 3000
end

function CMD.forward(source,fd)
	if not agent[fd] then
        agent[fd] = source
	end
end

function CMD.unforward(fd)
	client_number = client_number-1
	agent[fd] = nil
end

function CMD.shutdown()

end

function CMD.shutdown_socket(fd,sock_type)
	if not sock_type then
        sock_type = "BSD"
	end
	if sock_type == "BSD" then
        	skynet.call(gate, "lua", "kick", fd)
    elseif sock_type == "WEBSOCKET" then
    	skynet.call(wsgate, "lua", "kick", fd)
    end
	return {errCode = 0}
end

function CMD.reset_maxclient(max_client)
	if type(max_client) ~= "number" then
	    return "max_client is not number"..tonumber(max_client)
	end

	if max_client < 500 then
        return "max_client is samller then 500"
	end
	maxclient = max_client
	return "new maxclient is "..tostring(maxclient)
end

skynet.start(function() 
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
    	 if cmd == "socket" then
    	    local f = SOCKET[subcmd]
    	    f(...)
    	 else
    	 	--return skynet_util_docmd(CMD, session, string.lower(cmd), subcmd, ...)
    	 	return skynet.ret(skynet.pack(table.unpack(res)))
    	 end
    end)

    gate = skynet.newservice("gate")
    if wswatchdogport ~= 0 then
        wsgate = skynet.newservice("wsgate")
    end

    skynet.register ".watchdog"
end)

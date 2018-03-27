local skynet = require "skynet"
local dispatchhandler = {}

local modules = {}
local player

local module_config = {
	login = require("login.login_sink"),

	forward_map = {}
}

function dispatchhandler.on_socket_close()
	for k,v in pairs(modules) do
        if v.on_socket_close then
        	v:on_socket_close()
        end
	end
end

function dispatchhandler.on_redis_event(channel,msg)
	-- body
end

function dispatchhandler.can_exit()
	-- body
end

function dispatchhandler.on_client_reconnect()
	-- body
end

function dispatchhandler.on_login_success()
	-- body
end

function dispatchhandler.exit()
	-- body
end

function dispatchhandler.create_module(module_name)
	local m = module_config[module_name]
	modules[module_name] = m.new(player)
end

function dispatchhandler.update()
	-- body
end

function dispatchhandler.get_module(module_name)
	if not modules[module_name] then
		dispatchhandler:create_module(module_name)
	end

	return module_name[module_name]
end

function dispatchhandler.init(p)
	player = p
end

function dispatchhandler.on_client_request(proto_head, proto_name, args)
	local module_name = module_config.forward_map[proto_head] or proto_head
	local module = dispatchhandler.get_module(module_name)
	if module_config.forward_map[proto_head] then
		module:on_client_request_foreignCMD(proto_head,proto_name,args)
	else
	    module:on_client_request(proto_name,args)
	end
end

function dispatchhandler.on_sink_request(module_name, proto_name, ...)
	
end

return dispatchhandler
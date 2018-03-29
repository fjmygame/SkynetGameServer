local skynet = require "skynet"

local _params = table.pack(...)
local _module_name = _params[1]
local _service_id = _params[2]

local l_module = require(_module_name)
local _module_impl = l_module.new(table.unpack(_params))
local _module = base_module.new(_module_impl)
_module_impl:set_module(_module)

skynet.start(function()
     local function on_request(m,cmd,...)
     	return m:on_command(cmd,...)
     end

     skynet.dispatch("lua", function(session, source, cmd, ...)
       return skynet_util.lua_docmd(on_request, session, cmd, _module, cmd, ...)
     end)

	 skynet.register(_service_id);
end)
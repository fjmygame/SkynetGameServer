local skynet = require "skynet"

local util = {}

function util.lua_docmd(cmdhandler,session,cmd,...)
	local res = {}
	local handler_type = type(cmdhandler)
	if handler_type ~= "table" and handler_type ~= "function" then
	    print("service command handler type error,type:"..tostring(handler_type))
	else
		local f
		if handler_type == "table" then
			f = cmdhandler[cmd]
		elseif handler_type == "function" then
			f = cmdhandler
		end
        
                if not f then
                	local l_des = string.format("Unknow command %s", tostring(cmd))
                	res = {false,l_des}
                else
                	local l_rst = pcall(f,...)
                	if not l_rst then
                		res = {false,"raise error"}
                	else
                		res = {l_rst[2],l_rst[3],l_rst[4]}
                	end
                end
        end

        if session == 0 then
        	return table.unpack(res)
        else
        	return skynet.ret(skynet.pack(table.unpack(res)))
        end
end

return util
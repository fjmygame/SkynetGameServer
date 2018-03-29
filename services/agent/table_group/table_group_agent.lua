local skynet = require "skynet"

local clustermc = require "clustermc"

local table_group_agent = {}
local service_node_name = {}

local function skynet_call(dest, proto, cmd_id, ...)
	local node_name = service_node_name[dest]
	if not node_name then
         --getroominfo
         node_name = "cell_0_127.0.0.1:6123"
	end

	if not node_name then
		return skynet.call(dest,proto,cmd_id, ...)
	else
		local r_self,r_service,rst = clustermc.call(node_name, dest, cmd_id)
		return r_service,rst
	end
end

local function skynet_send(dest, proto, cmd_id, ...)

end

return table_group_agent
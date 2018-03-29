local skynet = require "skynet"

local function create_table_group(room_id,config)
	local ad = basemodule_service_helper.newservice("table_group_module", room_id, room_id)

	skynet.call(ad,"lua", "set_table_group_config", config)
end


skynet.start(function() 
   
     
end)
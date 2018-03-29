local skynet = require "skynet"


local base_module_service_helper = {}

function base_module_service_helper.newservice(module_name, service_id, ...)
	return skynet.newservice("base_module_service", module_name, service_id, ...)
end

return base_module_service_helper
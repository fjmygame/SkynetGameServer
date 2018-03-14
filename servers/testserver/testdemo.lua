local _client_agent = require "_client_agent"

local testdemo = setmetatable({},{__index = _client_agent})

local timerid
local status_handler = {}

local STATUS = 
{

}

function testdemo:request_handler()
	-- body
end

function testdemo:init(id)
	_client_agent:init()
	testdemo:request_handler()
	if not self.request_handler then
		self.exit()
	else
		self:open_client(self.request_handler)
		self:login(id)
	end
	self.ctx_room_id = "room_cell_10"
	self.switch_status(STATUS.LOGIN)
end

return testdemo
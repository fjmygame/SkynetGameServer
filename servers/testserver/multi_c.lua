local skynet = require "skynet"
require "skynet.manager"
local client_num = skynet.getenv("client_num")
local clients = {}

local function new_multi_client()
	for i=80000,80000+(client_num-1) do
        clients[i] = skynet.newservice("single_c", i)
        skynet.sleep(10)
	end
end

skynet.start(function() 
    skynet.fork(new_multi_client)
end)
local skynet = require "skynet"
local c = require "c"  --网络连接处理
local _client_agent
local client

_client_agent = setmetatable({}, {__index = self})

function _client_agent:init()
	-- body
end

function _client_agent:open_client(request_handler)
    client = c:new("127.0.0.1", 8200)
    client:init(request_handler)    
end

function _client_agent:exit()
	-- body
end

function _client_agent:closed()
	-- body
end

function _client_agent:login(id)
	print("login")
	local loginRes = self:request("login_openid",{id="123"..id},true)
	loginRes = self:request("login_openid",{id="123"..id},true)
	loginRes = self:request("login_openid",{id="123"..id},true)
	loginRes = self:request("login_openid",{id="123"..id},false)
	loginRes = self:request("login_room",{id="123"..id},false)
	loginRes = self:request("login_room",{id="123"..id},false)
	loginRes = self:request("login_room",{id="123"..id},false)
	print("loginRes")
	print(loginRes)
end

function block_func(x)
	x.co = coroutine.running()
	return function(res)
		x.res = res
		skynet.wakeup()
	end
end

function _client_agent:request(name,args,block)
	if not block then
        return client:send_request(name, args)
	end
	local x = {}
	client:send_request(name,args,block_func(x))
	skynet.wait()
	return x.res
end

return _client_agent
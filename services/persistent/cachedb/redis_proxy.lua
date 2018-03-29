local skynet = require "skynet"

require "skynet.manager"
local redis = require "redis"
local cjson = require "cjson"
local futil = require "futil"

local psub_redis_host = skynet.getenv("psub_redis_host") or ''
local psub_redis_port = skynet.getenv("psub_redis_port") or 0

local conf =
{
	host = psub_redis_host,
	port = psub_redis_port,
	db = 0
}

local channel_observers = {}

local function sub_channel(channel,observer)
end

local function handler_channel_event(channel,msg)
end

local function handler_agecncy_related(channel,msg)
end

local function IsAgentExists(userid)
end

local sub_handler = {
	
}

local request_cmd = {}

function request_cmd.subcribe(channel,source)
end

local pub_redis = nil
function request_cmd.publish(channel,msg)
	return true
end

skynet.start(function() 
	skynet.dispatch("lua", function(session,address,cmd,...)
	    local handler = request_cmd[cmd]
	    if handler then
	    	if session ~= 0 then
            	skynet.ret(skynet.pack(handler(...)))
            else
            	handler(...)
            end
        else
        	--error
	    end
	end)

	skynet.register(".redis_proxy")

end)




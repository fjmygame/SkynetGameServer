local skynet = require "skynet"
local redis = require "redis"
local futil = require "futil"

require "skynet.manager"

local redis_util = {}
local redis_svr = skynet.getenv "redis_svr"

function redis_util.init()

	skynet.newservice("redis_db",redis_svr)
	skynet.uniqueservice("redis_proxy")

    local channels = futil.split(skynet.getenv("subs_channel"),";")
    for k,channel in pairs(channels) do
        skynet.call(".redis_proxy", "lua", "subscribe", channel)
    end
end


function redis_util.query_with_gsub(redisstr,args,redispt,pattern)
	pattern = pattern or "$([%w_]+)"
	redispt = redispt or " "
	local redis_cmd = futil.split(redisstr,redispt)
	for _id,_rd in pairs(redis_cmd) do
        redis_cmd[_id] = string.gsub(_rd,pattern,args)
	end

	return skynet.call(redis_svr,"lua",table.unpack(redis_cmd))
end

function redis_util.querycmd(...)
	return skynet.call(redis_svr,"lua",...)
end

function redis_util.excute_with_gsub(redisstr,args,redispt,pattern)
	pattern = pattern or "$([%w_]+)"
	redispt = redispt or " "
	local redis_cmd = futil.split(redisstr,redispt)
	for _id,_rd in pairs(redis_cmd) do
        redis_cmd[_id] = string.gsub(_rd,pattern,args)
	end

	return skynet.send(redis_svr,"lua",table.unpack(redis_cmd))
end

return redis_util
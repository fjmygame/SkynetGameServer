local skynet = require "skynet"
local redis = require "redis"
local logger = require "logger"
local clustermc = require "clustermc"

require "skynet.manager"

local server_id,redis_host,redis_port = ...

if not server_id then
	server_id = ".redis_db"
end

if not redis_host then
	redis_host = skynet.getenv "redis_host"
end
if not redis_port then
	redis_port = skynet.getenv "redis_port"
end

local conf = {
	host = redis_host,
	port = redis_port,
	auth = nil
}

local db
local cmdStat = {
	total = {
       cnt = 0,
       time = 0.0,
       avg = 0.0,
    },
    cmds = {},
}

local function doCmdStat(cmd,startTime,endTime)
    local costTime = endTime - startTime
    cmdStat.total.cnt = cmdStat.total.cnt + 1
    cmdStat.total.time = cmdStat.total.time + costTime
    cmdStat.total.avg = cmdStat.total.time / cmdStat.total.cnt

    if not cmdStat.cmds[cmd] then
    	cmdStat.cmds[cmd] = {}
    	cmdStat.cmds[cmd].cnt = 0
    	cmdStat.cmds[cmd].time = 0.0
    	cmdStat.cmds[cmd].avg = 0.0
    end

    local theCmd = cmdStat.cmds[cmd]
    theCmd.cnt = theCmd.cnt + 1
	theCmd.time = theCmd.time + costTime
	theCmd.avg = theCmd.time / theCmd.cnt
end

skynet.start(function() 
	skynet.dispatch("lua", function(session,address,cmd,...)
	    cmd = string.lower(cmd)
	    local f = db[cmd]
	    if not f then
	    	skynet.ret(skynet.pack(nil))
	    end

	    local sTime = skynet.time()
	    local ok,res = pcall(f,db,...)
	    if not ok then
            if session ~= 0 then
            	skynet.ret(skynet.pack(nil))
            end
	    else
	    	if session ~= 0 then
            	skynet.ret(skynet.pack(res))
            end
	    end
	    doCmdStat(cmd,sTime,skynet.time())
	end)

	db = redis.connect(conf)

	clustermc.call("pandamjserver",".logservice","test_log",1)

    --skynet.infofunc(dbginfo)
	skynet.register(server_id)

end)
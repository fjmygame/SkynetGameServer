local skynet = require "skynet"
require "skynet.manager"

local redis = require "redis"
local futil = require "futil"

local cluster = require "lkcluster"

local command = {}

local running = false
local nodeName = skynet.getenv("nodename")
local clusterFilePath = skynet.getenv("cluster")

local nodeIp,nodePort,nodeLocalIp,nodeEndpoint
if nodeName then
    nodeIp = assert(skynet.getenv("nodeip"), "Set proper ip, please!")
    nodePort = assert(tonumber(skynet.getenv("nodeport")), "Set proper port, please!")
    nodeLocalIp = skynet.getenv("nodelocalip") or "0.0.0.0"
    nodeEndpoint = string.format("%s:%s", nodeIp, nodePort)
end

local cluster_cfg_mgr = (require "cluster_cfg_mgr").new(clusterFilePath, {})
local redisDb

local nodegroups = futil.split(skynet.getenv("nodegroup") or "default", ";")
local config_keys = {}

for _,nodegroup in pairs(nodegroups) do
    config_keys[#config_keys+1] = string.format("clusterconfig:wt:%s", nodegroup)
end

local now_script = "return redis.call('time')[1]"

local redis_delta_time

local function redis_now()
    if not redis_delta_time then
    	local t = tonumber(redisDb:eval(now_script, 0))
    	redis_delta_time = t - os.time()
    	return t
    end
    return redis_delta_time + os.time()
end

local function regSelf()
    if not running then
    	skynet.error("cluster node not running, stop regSelf")
        return
    end
    
    skynet.timeout(2000,regSelf)
    local now = redis_now()
    for _,config_key in pairs(config_keys) do
        redisDb:hset(config_key, nodeName, string.format("%s;%s", nodeEndpoint, now))
    end
end

local function noticeExistedClusters(allConf)
    if not nodeEndpoint then
        return
    end

    for k,v in pairs(allConf) do
        if k ~= nodeName then
        	local ok,err = cluster.call(k, ".clustermgr", "set", nodeName, nodeEndpoint)
        	if not ok then
        	else
        	end
        end
    end
end

local function del_expired_node(config_key, expired_nodes)
    if not expired_nodes or #expired_nodes == 0 then return end

    redisDb:hdel(config_key, table.unpack(expired_nodes))
end

local function del_one_node(config_key, nn)
    if not nn or nn == '' then return end

    redisDb:hdel(config_key, nn)
end

local function updateCluster()
    skynet.timeout(2000,updateCluster)

    local now = redis_now()
    local allConf = {}
    if nodeEndpoint then
    	allConf[nodeName] = nodeEndpoint
    end

    for _,config_key in pairs(config_keys) do
        local expired_nodes = {}

        local r = redisDb:hgetall(config_key)
        if r and #r > 0 then
            for i=1,#r,2 do
               local name = r[i]
               if nodeName ~= name then
               	   local address,t = string.match(r[i+1], "(^;]*);?(.*)$")
               	   t = tonumber(t)
               	   if not t or now - t < 60 then
               	   	    allConf[name] = address
               	   else
               	   	    expired_nodes[#expired_nodes+1] = name
               	   end
               end
            end
        end

        if #expired_nodes > 0 then
        	skynet.fork(del_expired_node, config_key, expired_nodes)
        end
    end

    -- if cluster_cfg_mgr:set_all(allConf) then
    -- 	cluster.reload(allConf)
    -- end
    cluster.reload(allConf)

    return allConf
end

function command.get(name)
	if not name or name == nodeName then
		return skynet.ret(skynet.pack(nodeEndpoint))
	end
	return skynet.ret(skynet.pack(cluster_cfg_mgr:get(name)))
end

function command.set(name,address)
	if name ~= nil and address ~= nil then
		if cluster_cfg_mgr:set(name,address) then
			cluster.reload(cluster_cfg_mgr:get_all())
		end
	end
	return skynet.ret(skynet.pack())
end

function command.names(pat)
	return skynet.ret(skynet.pack(cluster_cfg_mgr:names(pat)))
end

function command.goodbye()
	if nodeEndpoint then
		running = false

		for _,config_key in pairs(config_keys) do
           del_one_node(config_key,nodeName)
		end
	end
	local ret = {ok=true}
	return skynet.ret(skynet.pack(ret))
end

skynet.start(function()  
    skynet.dispatch("lua", function(session,source,cmd,...)  
        local f = command[string.lower(cmd)]
        f(...)
    end)

    redisDb = redis.connect{
        host = skynet.getenv("cluster_redis_host") or skynet.getenv("redis_host"),
        port = skynet.getenv("cluster_redis_port") or skynet.getenv("redis_port"),
        auth = skynet.getenv("cluster_redis_auth") or skynet.getenv("redis_auth"),
    }

    if not redisDb then
    end

    if nodeEndpoint then
        local clusterd = skynet.uniqueservice("lkclusterd")
        skynet.call(clusterd, "lua", "listen", nodeLocalIp, nodePort)
        running = true
        regSelf()
    end

    local allConf = updateCluster()
    skynet.fork(noticeExistedClusters, allConf)
    skynet.register(".clustermgr")
end)
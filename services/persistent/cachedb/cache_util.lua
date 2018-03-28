local skynet = require "skynet"
local mysql = require "mysql"

require "skynet.manager"
local cjson = require "cjson"

local sqlutil = require "sqlutil"

local mysql_util = require "mysql_util"
local redis_util = require "redis_util"
local cache_conf = require "cache_conf"

local cache_util = {}

local function join_sql_util(sql,parttern,args)
	local argv = {}
	for key,val in pairs(args) do
       if key ~= "table_name" and key ~= "game_id" and type(val) == "string" then
          argv[key] = sqlutil.quote_sql_str(val)
       else
       	  argv[key] = val
       end
	end

	local join_sql = args and string.gsub(sql,parttern,argv) or sql
	return join_sql
end

function cache_util.init()
	mysql_util.init()

	redis_util.init()

	skynet.uniqueservice("proxyloader")
end

function cache_util.call(dbname, cache_name, args)
	args = args or {}
	local dbcache = cache_conf[dbname]
	local cacheconf = dbcache[cache_name]

	local parttern = cacheconf.parttern or "$([%w_]+)"
	local redispt = cacheconf.redispt or " "

	if cacheconf.redis then
		local ret = redis_util.query_with_gsub(cacheconf.redis,args,redispt,parttern)

		if cacheconf.expire and cacheconf.cachekey then
           local rediskey = string.gsub(cacheconf.cachekey,parttern,args)
           redis_util.querycmd("EXPIRE",rediskey,cacheconf.expire)
		end

		return ret
	end
    print(dbcache,cacheconf,cacheconf.sql)
	if cacheconf.sql then
		if cacheconf.queryrd and cacheconf.cacherd then
            --查询缓存
            local qyresult = redis_util.query_with_gsub(cacheconf.queryrd, args, redispt, parttern)
            if qyresult and (type(qyresult) ~= "table" or #qyresult > 0) then
                return qyresult
            end

            --缓存没有，查询mysql
            local sql = join_sql_util(cacheconf.sql, parttern, args)
            local sqlcache = mysql_util.query(dbname,sql,cacheconf.divide)

            --写入缓存
            if sqlcache ~= nil then
               for _,col in pairs(sqlcache) do
            	   local rds = redis_util.query_with_gsub(cacheconf.cacherd, col)
            	   if rds ~= "OK" and rds ~= 1 then
            	   end

            	   --超时
            	   if cacheconf.expire and cacheconf.cachekey then
			           local rediskey = string.gsub(cacheconf.cachekey,parttern,col)
			           redis_util.querycmd("EXPIRE",rediskey,cacheconf.expire)
				   end
               end
            end

            return redis_util:query_with_gsub(cacheconf.queryrd, args, redispt, parttern)
        elseif cacheconf.cachekey then
        	local rdskey = args and string.gsub(cacheconf.cachekey, parttern, args) or cacheconf
        	local rdscache = redis_util.querycmd("GET", rdskey)
        	if rdscache then
               return cjson.decode(rdscache)
        	end

        	--缓存没有，查询mysql
            local sql = join_sql_util(cacheconf.sql, parttern, args)
            local sqlcache = mysql_util.query(dbname,sql,cacheconf.divide)

            --写入缓存
            if sqlcache ~= nil then
            	local seriredis = cjson.decode(sqlcache)
            	local rds
        	    if cacheconf.expire then
		           rds = redis_util.querycmd("SETEX",rdskey,cacheconf.expire,seriredis)
		        else
		           rds = redis_util.querycmd("SET",rdskey,seriredis)
			    end
			    if rds ~= "OK" then
			    end
            end

            return sqlcache
        else
            local sql = join_sql_util(cacheconf.sql, parttern, args)
            print(sql)
            local qyresult = mysql_util.query(dbname,sql,cacheconf.divide)
            print(qyresult)

            if cacheconf.clearrd then
                redis_util.excute_with_gsub(cacheconf.clearrd,args,redispt,parttern)
            end

            return qyresult
		end
	end
end

function cache_util.send(dbname, cache_name, args)
	
end

function cache_util.publish(channel,msg)
	
end


return cache_util
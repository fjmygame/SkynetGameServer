local skynet = require "skynet"
local mysql = require "mysql"

local futil = require "futil"

require "skynet.manager"

local mysql_service,mysql_dbname = ...

local mysql_conf = {}
local mysql_handle

local function readconf()
    mysql_conf.dbname = mysql_dbname
    mysql_conf.host = skynet.getenv(string.format("%s_host",mysql_dbname))
    mysql_conf.port = skynet.getenv(string.format("%s_port",mysql_dbname))
    mysql_conf.user = skynet.getenv(string.format("%s_user",mysql_dbname))
    mysql_conf.pwd = skynet.getenv(string.format("%s_pwd",mysql_dbname))
end

local function make_conn()

    local conf = {
      host = mysql_conf.host,
      port = mysql_conf.port,
      user = mysql_conf.user,
      password = mysql_conf.pwd,
      database = mysql_conf.dbname,
      max_packet_size = 1024*1024
    }

    local conn = mysql.connect(conf)

    return conn
end

local function do_sql(session, address, sql, ...)
   if not mysql_handle then
   	   mysql_handle = make_conn();
   	   if not mysql_handle then
   	   end
   end

   local start_time = skynet.time()
   local result = mysql_handle:query(sql)

   if mysql_err(result,sql) then
   	   result = nil
   end

   print(session)
   if session ~= 0 then
   	  print("sql response")
      skynet.ret(skynet.pack(result))
   end

   do_sql_stat(sql,start_time,skynet.time())
end

local function is_conn_err(errmsg)
    if not errmsg then
   	   return false
   	end

   	if type(errmsg) == "string" and string.find(errmsg, "Connect to") then
   		return true
   	end
    return false
end

skynet.start(function()
	skynet.dispatch("lua", function(session,address,sql,...)
		print(session,address,sql)
        local ok,err = pcall(do_sql, session, address, sql, ...)
        if not ok then
            if is_conn_err(err) then
                mysql_handle = make_conn()
            end
        end
	end)

	readconf()

	mysql_handle = make_conn()

	skynet.register(mysql_service)
end)

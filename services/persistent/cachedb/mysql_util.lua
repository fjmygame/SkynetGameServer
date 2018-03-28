local skynet = require "skynet"
local mysql = require "mysql"
require "skynet.manager"

local futil = require "futil"

local mysql_util = {}

local mysql_dbservice = {}

local function readConf()
     local mysql_dbname = futil.split(tostring(skynet.getenv("mysqldb")),";")

     for k,dbname in pairs(mysql_dbname) do
         mysql_dbservice[dbname] = {}
         mysql_dbservice[dbname].wkIndex = 0
         mysql_dbservice[dbname].wkService = futil.split(skynet.getenv(string.format("%s_svr",dbname)),";")
     end
end

function mysql_util.init()
	for dbname,tbWorker in pairs(mysql_dbservice) do
        local lwkService = tbWorker.wkService
        for k,svrname in pairs(lwkService) do
            skynet.newservice("mysql_service", svrname, dbname)
            skynet.call(svrname,"lua","set names utf8mb4")
        end
	end
end

function mysql_util.query(dbname,sql,divide)
	divide = divide or false
	local mysql_dbservice_dbsvr = mysql_dbservice[dbname]
	if not mysql_dbservice_dbsvr then
	     return nil
	end

    local wkIndex = mysql_dbservice_dbsvr.wkIndex + 1
    mysql_dbservice_dbsvr.wkIndex = wkIndex%(#mysql_dbservice_dbsvr.wkService)

    local wkService = mysql_dbservice_dbsvr.wkService
    if not wkService[wkIndex] then
    	return nil
    end

    --分表处理
    if divide then
    end
    return skynet.call(wkService[wkIndex], "lua", sql)
end

function mysql_util.excute(dbname,sql,divide)
		divide = divide or false
	local mysql_dbservice_dbsvr = mysql_dbservice[dbname]
	if not mysql_dbservice_dbsvr then
	     return nil
	end

    local wkIndex = mysql_dbservice_dbsvr.wkIndex + 1
    mysql_dbservice_dbsvr.wkIndex = wkIndex%(#mysql_dbservice_dbsvr.wkService)

    local wkService = mysql_dbservice_dbsvr.wkService
    if not wkService[wkIndex] then
    	return nil
    end

    --分表处理
    if divide then
    end

    return skynet.send(wkService[wkIndex], "lua", sql)
end

readConf()

return mysql_util

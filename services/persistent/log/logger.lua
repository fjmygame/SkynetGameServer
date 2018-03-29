local skynet = require "skynet"
local const = require "logger_const"

local logger = {}
local logcmd = {}
local logLevel = const.log_level.debug

do
    local level = skynet.getenv("loglevel")
    if level and const.log_level[level] then
   	    logLevel = const.log_level[level]
    end

    skynet.timeout(0,function() 
        local ok,ret = pcall(skynet.call,"DATACENTER", "lua", "QUERY", "loglevel")
        if ok and ret and const.log_level[ret] then
        	logLevel = const.log_level[ret]
        end
    end)
end

function logcmd.set_log_level(level)
end

local function logErrhandle(error)
	skynet.error(error)
	skynet.error(debug.traceback())
end

local function log(level,fmt,...)
    if not const.log_lvlstr[level] then
    	return
    end

    if level < logLevel then
    	return
    end

    if type(fmt) ~= "string" then
    	return
    end

    local ok,content = xpcall(string.format,logErrhandle,fmt,...)
    if not ok then
    	skynet.error("log fail: ", fmt, ...)
        return 
    end

    local nowStr = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local msg = string.format("[%s %5s] %s\r\n", nowStr, const.log_lvlstr[level], content)
    skynet.send(".logservice", "lua", "log", level, msg)
end

function logger.debug(fmt,...)
	log(const_log_level.debug,fmt,...)
end

function logger.info(fmt,...)
	log(const_log_level.info,fmt,...)
end

function logger.warn(fmt,...)
	log(const_log_level.warn,fmt,...)
end

function logger.err(fmt,...)
	log(const_log_level.err,fmt,...)
end

function logger.fatal(fmt,...)
	log(const_log_level.fatal,fmt,...)
end

local function _log_dispatch(session,address,cmd,...)
	local f = logcmd[cmd]
	assert(f,cmd)
	f(...)
end

skynet.register_protocol {
	name = "log",
	id = const.PTYPE.LOG,
	pack = skynet.pack,
	unpack = skynet.unpack,
	dispatch = _log_dispatch,
}
return logger;

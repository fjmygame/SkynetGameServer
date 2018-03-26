local skynet = require "skynet"
require "skynet.manager"
local skynet_util = require "skynet_util"
local sharedata = require "sharedata"


local CMD = {}
local const

local function loadconfig(path)
	return load(io.open(path):read("*a"))()
end

function CMD.reload()
	local ok,new_const = pcall(loadconfig, "../services/common/const.lua")
	if ok and new_const then
        const = new_const
        sharedata.update("const", const)
        --logger.info("const reload success")
        return true
	end
end

skynet.init(function() 
   const = loadconfig("../services/common/const.lua")
   sharedata.new("const", const)
end)

skynet.start(function()
   skynet.dispatch("lua", function(session, source, cmd, ...)
       return skynet_util.lua_docmd(CMD,session,cmd,...)
   end)
   skynet.register(".constloader")
end)

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

local gamename = skynet.getenv("gamename") or nil

skynet.start(function()
	proto:init(gamename)
<<<<<<< HEAD
        print(proto.c2s)
=======
>>>>>>> 2f58dca0ea47f8e916757894a875986604b42b2f
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)

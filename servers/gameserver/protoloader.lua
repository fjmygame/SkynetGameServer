
local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

local gamename = skynet.getenv("gamename") or nil

skynet.start(function()
	proto:init(gamename)
	print(gamename)
	print(proto.c2s)
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
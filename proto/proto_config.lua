local proto_config = {}

local json = require "cjson"

local function read(path)
	local p = io.open(path)
	print(path)
	local text = p:read("*a")
	text = text.."\n"
	p:close()
	return text
end

local function readjson(path)
	local f = io.open(path)
	local data = f:read("*a")
	f:close()
	return data
end

local content = readjson("../proto/proto_config.json")
local config = json.decode(content)

function proto_config:init(gamename)
	self.c2s = {}
	self.s2c = {}

    --c2s
    for _,v in ipairs(config.c2s) do
    	if v.game then
    		for _,g in ipairs(v.game) do
    			if g.name == gamename then
    				self.c2s[g.name] = {basecode=g.basecode,sproto=read("../proto/c2s."..g.name..".sproto")}
    				break
    			end
    		end
    	end
    	if v.name then
    		self.c2s[v.name] = {basecode=v.basecode,sproto=read("../proto/c2s."..v.name..".sproto")}
    	end
    end

    --s2c
    for _,v in ipairs(config.s2c) do
    	if v.game then
    		for _,g in ipairs(v.game) do
    			if g.name == gamename then
    				self.s2c[g.name] = {basecode=g.basecode,sproto=read("../proto/s2c."..g.name..".sproto")}
    				break
    			end
    		end
    	end
    	if v.name then
    		self.s2c[v.name] = {basecode=v.basecode,sproto=read("../proto/s2c."..v.name..".sproto")}
    	end
    end
end

return proto_config
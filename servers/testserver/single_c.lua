local skynet = require "skynet"
require "skynet.manager"

local ok,testitem = pcall(require,skynet.getenv("testitem") or nil)
print(testitem)
print(testitem)
print(testitem)
print(testitem)
print(testitem)


local MAX_CONNECT_TIME = 300

local CMD = {}

local starttime
local id = ...

local function detect()
	while(true) do
        if os.time() - starttime > MAX_CONNECT_TIME then
            testitem.exit()
            skynet.exit()
        end
        skynet.sleep(100)
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session,source,commad,...)
		local f = CMD[string.lower(commad)]
		skynet.ret(skynet.pack(f(...)))
	end)

	starttime = os.time()
	skynet.fork(detect)

	testitem:init(id)
	skynet.fork(function()
        while true do
           testitem:update()
           skynet.sleep(100)
        end
	end)

	skynet.register("robot_"..id)
end)
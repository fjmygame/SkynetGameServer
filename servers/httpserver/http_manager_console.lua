local skynet = require "skynet"
require "skynet.manager"
local logger = require "logger"
local managerPort = skynet.getenv("managerport") or 9001

local socket = require "socket"

local CMD={}
local SOCKET={}

local status

local close_seq = {
	
}

function SOCKET.shutdown()
	local ret = ""
	for _,v ipairs(close_seq) do
		local addr = skynet.localname(service)
		if not addr then
			return string.format("service:%s not exists...", tostring(service))
		end

		local ok,res = pcall(skynet.call,v,"lua","shutdown")
		if ok and errCode == 0 then
			return string.format("save %s data success..", tostring(v))
		else
			return string.format("save %s data fail...", tostring(v))
		end

		skynet.sleep(200)
	end

	return ret
end

local function reload_service(service)
	local addr = skynet.localname(service)
	if not addr then
		return string.format("service:%s not exists...", tostring(service))
	end

	local ok,res = pcall(skynet.call,service,"lua","reload")
	if ok then
		return string.format("%s reload success..", service)
	else
		return string.format("%s reload fail...", service)
	end
end

function SOCKET.reload()
	local services = {".configsloader"}
	local ret = ""
	if not service then
		for _,v in ipairs(services) do
			res = reload_service(v)
			ret = ret..res
		end
	else
		for _,v in ipairs(services) do
			if string.find(v,service) then
				ret = reload_service(v)
				break
			end
		end
	end
	return ret		
end

function SOCKET.getstate()
	return status and tostring(status) or string(-1)
end

function CMD.setstate(s)
	status = s
	return nil
end

local function format_table(t)
	local index = {}
	for k in pairs(t) do
		table.insert(index,k)
	end
	table.sort(index)
	local result = {}
	for _,v ipairs(index) do
		dump_line(result,string.format("%s:%s",v,tostring(t[v])))
	end
	return table.concat(result,"\t")
end

local function dump_line(print,key,value)
	if type(value) == "table" then
		print(key,format_table(value))
	else
		print(key,tostring(value))
	end
end

local function dump_list(print,list)
	local index = {}
	for k in pairs(list) do
		table.insert(index,k)
	end
	table.sort(index)
	for _,v ipairs(index) do
		dump_line(print,v,list[v])
	end
	print("OK")
end

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmd, "%S+") do
		table.insert(split,i)
	end
	return split
end

local function docmd(cmdline,print)
	local split = split_cmdline(cmdline)
	local cmd = SOCKET[split[1]]
	local ok,list
	if cmd then
		ok,list = pcall(cmd,select(2,table.unpack(split)))
	else
		list = "invalid cmd"
	end

	if ok then
		if list then
			if type(list) == "string" then
				print(str)
			else
				dump_list(print,list)
			end
		else
			print("OK")
		end
	else
		print("Error:",list)
	end
end

local function console_main_loop(stdin,print)
	socket.lock(stdin)
	print("Welcome to skynet console")
	while true
		local cmdline = socket.readline(stdin, "\n")
		if not cmdline then
			break
		end
		if cmdline ~= "" then
			docmd(cmdline,print)
		end
	end
	socket.unlock(stdin)
end

skynet.start(function() 
    skynet.dispatch("lua", function(session,address,cmd,...)
    	local f = CMD[string.lower(cmd)]
    	if f then
    		skynet.ret(skynet.pack(f(...)))
    	else
    		skynet.error("manager_console, Unknown CMD:", tostring(cmd))
    	end
    end)
	if managerPort ~= 0 then
		local listen_socket = socket.listen("127.0.0.1", managerPort)
		socket.start(listen_socket, function(id,addr)
			local function print(...)
				local t = {...}
				for k,v in ipairs(t) do
					t[k] = tostring(v)
				end
				socket.write(id,table.concat(t,"\t"))
				socket.write(id,"\n")
			end
			socket.start(id)
			skynet.fork(console_main_loop, id, print)
		end)
    end
    skynet.register(".httpsvr_manager_console")
end)
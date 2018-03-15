local socket = require "socket"
local proto = require "proto"
proto:init("paodekuai")
local sproto = require "sproto"

local skynet = require "skynet"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local client = {}
client.__index = client

local function toStr(t)
	-- body
end

local function print_request(name,args)
	-- body
end

local function print_response(name,args)
	-- body
end

function client:new(address,port)
	local self = {}
	setmetatable(self, client)
	self.address = address
	self.port = port
	return self
end

function client:send_request(name,args,func)
	if func then
        self.session = self.session + 1
	end
	local str = self:request(name,args,self.session)
	self:send_package(str)
	if func then
        self.cb[self.session] = func 
	end
end

local function recv_package(self)
    local sz = socket.header(socket.read(self.fd, 2))
    return socket.read(self.fd, sz)
end

local function deal(self,v)
     self:on_package(host:dispatch(v))
end

local function dispatch(self)
     while not self.closed do
        local ok,data = pcall(recv_package,self)
        if not ok then
           error "Server closed"
        end
        skynet.fork(deal,self,data)
        skynet.sleep(0)
     end
end

function client:init(handler)
	self.session = 0
	self.closed = false
	self.request_handler = setmetatable({},{__index=handler})
	self.cb = {}
	self.fd = socket.open(self.address,self.port)
	skynet.fork(dispatch,self)
end

function client:request(name,args,session)
	if not next(args) then
	    args = nil
	end

	local ok,str = pcall(request, name, args, session)
	if not ok then
		print("pack data not ok")
	else
		return str
	end
end

function client:on_package(t,...)
	if t == "REQUEST" then
		self:on_request(...)
	else
		self.on_response(...)
	end
end

function client:on_request(name,args,response)
	local f = self.request_handler[name]
	if f then
        local r = f(args)
        if response then
        	return send_package(response(r))
        end
    end
end

function client:on_response(session,res)
	if not res then
	    self.cb[session] = nil
	    return
	end
    local f = self.cb[session]
    self.cb[session] = nil 
    if f and res then
    	f(res)
    end
end

function client:send_package(pack)
	local package = string.pack(">s2",pack)
	socket.write(self.fd, package)
end

function client:exit()
	self.closed = true
	socket.close(self.fd)
end

return client
local skynet = require "skynet"
local sc = require "socketchannel"
local socket = require "socket"
local cluster = require "cluster.core"

local futil = require "futil"

local node_address = {}
local node_session = {}
local command = {}

local function read_response(sock)
   local sz = socket.header(sock:read(2))
   local msg = sock:read(sz)
   return cluster.unpackresponse(msg)
end

local function open_channel(t,key)
   local host,port = string.match(node_address[key], "([^:]+):(.*)$")
   local c = sc.channel {
      host = host,
      port = tonumber(port),
      response = read_response,
      nodelay = true,
   }

   c:connect(true)
   t[key] = c
   return c
end

local node_channel = setmetatable({}, {_index = open_channel})

local function loadconfig(config)
   if not config then return end
   for name,address in pairs(config) do
   	   print(name,address)
       if node_address[name] ~= address then
       	  if rawget(node_channel, name) then
       	  	 node_channel[name] = nil
       	  end
       	  node_address[name] = address
       end
   end
end

function command.reload(source, config)
   loadconfig(config)
   skynet.ret(skynet.pack(nil))
end

function command.listen(source, addr, port)
    local gate = skynet.newservice("gate")
    if port == nil then
        addr,port = string.match(node_address[key], "([^:]+):(.*)$")
    end
    skynet.call(gate, "lua", "open", {address=addr, port=port})
    skynet.ret(skynet.pack(nil))
end

local function send_request(no_response, source, node,  addr, msg, sz)
    local session = node_session[node] or 1
    local dsession = no_response and session*2 or session*2-1

    local request,_,padding = cluster.packrequest(addr, dsession, msg, sz)
    if node then
    	node_session[node] = session < 0x3fffffff and session + 1 or 1
    	print(node)
    	local c = node_channel[node]
    	if no_response then dsession = nil end
    	return c:request(request, dsession, padding)
    else
    end
end

function command.req(...)
   local ok,msg,sz = pcall(send_request, false, ...)
   if ok then
   	  skynet.ret(msg, sz)
   else
   	  skynet.error(msg)
   	  skynet.response()(false)
   end
end

function command.send(...)
    send_request(true, ...)
end

local proxy = {}

function command.proxy(source,node,name)
   local fullname = node.."."..name
   if proxy[fullname] == nil then
   	   proxy[fullname] = skynet.newservice("lkclusterproxy", node, name)
   end
   skynet.ret(skynet.pack(proxy[fullname]))
end

local request_fd = {}

function command.socket(source,subcmd,fd,data)
	if subcmd == "data" then
	   local addr,session, msg = cluster.unpackrequest(data)
	   local no_response = (session&1) == 0
	   if no_response then
	   	   return skynet.rawsend(addr, "lua", msg)
	   end
	   local ok,sz
	   ok,msg,sz = pcall(skynet.rawcall,addr,"lua", msg)

	   local response
	   if sz and sz >= 0x10000 then
	   	   response = cluster.pakcreponse(session,false,"response too big")
	   elseif ok then
	   	   response = cluster.pakcreponse(session,true,msg,sz)
	   else
	   	   response = cluster.pakcreponse(session,false,msg)
	   end
	   socket.write(fd,response)
	elseif subcmd == "open" then
		skynet.call(source, "lua", "accept", fd)
    else
    	skynet.error(string.format("socket %s %d : %d", subcmd, fd, data))
	end
end

skynet.start(function() 
    skynet.dispatch("lua", function(session,source,cmd,...)  
        local f = command[cmd]
        f(source,...)
    end)
end)
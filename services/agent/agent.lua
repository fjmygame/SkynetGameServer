local skynet = require "skynet"
local skynet_util = require "skynet_util"
local sprotoloader = require "sprotoloader"
local message_queue = {}
local message_queue_fd
local cur_message = nil
local message_queue_croutine_id
local thread_id 

local host
local check_flag = 0
local last_handle_time = nil

local last_recv_time = os.time

local player = {}

local CMD = {}


local function post_queue( ... )
	local msg = {...}
    table.insert(message_queue, msg)
    if thread_id then
    	skynet.wakeup(thread_id)
    	thread_id = nil
    end
end

local function clear_queue()
    message_queue = {}
    message_queue_fd = nil
    check_flag = 0
    message_queue_croutine_id = nil
end

local function startqueue()
    skynet.fork(function() 
        local l_fd = client_fd
        message_queue_croutine_id = coroutine.running()
        local l_run_flag = true
        while l_fd == client_fd and l_run_flag do
            if #message_queue == 0 then
                thread_id = coroutine.running()
                skynet.wait()
            else
            	cur_message = table.remove(message_queue,1)
            	local ok,result,r = pcall(dispatch_client_message, cur_message[1], cur_message[2], cur_message[3])
            	if message_queue_croutine_id and message_queue_croutine_id ~= coroutine.running() or l_fd ~= client_fd then
            		logger.err("agent request finally return after timeout")
            		l_run_flag = false
            	else
            		if ok then
            			if result then
            				if #result > 0x8000 then
            					skynet.error(string.format("agent response to large package, name:%s,size:%s", cur_message[1], #result))
            					return
            				end
            				send_package(result)
            			end
            		else
            			skynet.error(result)
            			skynet.error(string.format("agent dispatch client message err:%s \n name:%s,args:%s,response:%s", result,cur_message[1],futil.toStr(cur_message[2]), futil.toStr(r)))
            		end
            		check_flag = check_flag + 1
            		cur_message = nil
            		last_handle_time = os.time()
            	end
            end
        end
    end)

    skynet.fork(function() 
        local l_cur_fd = client_fd
        while l_cur_fd == client_fd do
            local l_oldflag = check_flag
            local l_oldmessage = cur_message
            skynet.sleep(2000)

            if l_cur_fd == client_fd then
            	local is_timeout = (last_handle_time~=nil) and (os.difftime(os.time(), last_handle_time) >= 20)
            	if l_oldflag == check_flag and cur_message and l_oldmessage == cur_message and is_timeout then
                    on_message_queue_block(cur_message)
            	end
            end
        end
    end)
end

local function on_message_queue_block(msg)
   -- logger.err("message_queue blocked, cur_message:%s, traceback:%s", msg[1], )

   skynet.call(".watchdog", "lua", "shutdow_socket", client_fd, "request timeout")
end

local function dispatch_client_message(name,args,response)
   if string.lower(name) == "heartbeat" then
       last_recv_time = os.time
       return nil
   end

   local proto_head = futil.split(name,"_")[1]
   local proto_name = string.sub(name, string.find(name,"_")+1,#name)
   local l_base_info = player.get_base_info()

   local l_is_login = l_base_info and l_base_info.uid
   if not l_is_login and (proto_head ~= login and proto_head ~= "gamelogin") then
        logger.err("player send cmd before login")
        return nil
   end

   local r = dispatchhandler.on_client_request(proto_head,proto_name,args)
   if response then
   	   return response(r),r
   end
end

local function send_package(pack)
   if not client_fd then
       return
   end
   local package = string.pack(">s2", pack)
   socket.write(client_fd,package)
end

local function heartbeat()
   skynet.fork(function() 
        while true do
            if const.heartbeat.interval <= os.time() - last_recv_time then
                send_package(send_request "heartbeat")
            end
            skynet.sleep(const.heartbeat.interval*100)
        end
   end)

   skynet.fork(function() 
        while true do
        	skynet.sleep(const.heartbeat.interval*100)
            if os.time() - last_recv_time > const.heartbeat.timeout then
                if client_fd and const.heartbeat.open == 1 then
                    skynet.error("server disconnect:heartbeat timeout! ", client_fd or 0)
                    skynet.call(".watchdog", "lua", "shutdow_socket", client_fd)
                end
            end
        end
   end)
end

function CMD.start(gate,fd,addr)
   print(is_robot,"aaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
   if not is_robot then
      client_fd = fd
      client_addr = addr
      client_gate = gate

      player.fd = client_fd
      player.ip = 

      skynet.call(gate,"lua","forward",fd)

      host = sprotoloader.load(1):host "package"
      send_request = host:attach(sprotoloader.load(2))

      player.pack_data = send_request
      print("bbbbbbbbbbbbbbbbbbbbbbbbb")
   end
   heartbeat()
   skynet.fork(update)
   startqueue()
end

player = {
	agent = skynet.self(),
	send_client = send_client_func,
    call_sink = call_sink_func,
    simulate_client_request = simulate_client_request,
    ip = "",
    fd = -1,
    is_robot = is_robot or false
}

local function call_sink_func(sink_name,prefor_name,...)
	return dispatchhandler.on_sink_request(sink_name,prefor_name,...)
end


local function send_client_func(name,...)
	local data = send_request(name,...)
	if #data > 0x2000 then
	end
	return send_package(data)
end

skynet.register_protocol {
  name = "client",
  id = skynet.PTYPE_CLIENT,
  unpack = function (msg, sz)
    return host:dispatch(msg, sz)
  end,
  dispatch = function (_, _, type, ...)
    if type == "REQUEST" then
      last_recv_time = os.time()
      post_queue(...)
      print("msg:.............")
    else
      assert(type == "RESPONSE")
      error "This example doesn't support request client"
    end
  end
}

skynet.init(function()
  -- body
end)

skynet.start(function()
   skynet.dispatch("lua", function(session, source, command, ...)
       return skynet_util.lua_docmd(CMD, session, string.lower(command),...)
   end)

   skynet.fork(function() 
      while true do
         skynet.send(skynet.self(), "debug", "GC")
         skynet.sleep(3000)
      end
   end)
end)

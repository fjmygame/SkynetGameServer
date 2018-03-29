local skynet = require "skynet"
require "functions"

local module_interface
local event_helper
local scheduler

local base_module = class("base_module", scheduler)
implements(base_module, {module_interface})

local command = {}

function base_module:actor(impl)
	base_module.super.actor(self)

	self.impl = impl
	self.event_helper = event_helper.new
end

function base_module:update(dt)
	
end

function base_module:subscribe(event_id, observer)
end

function base_module:publish_event(event_id, ...)
end

function base_module:on_command(cmd, ...)
	if not cmd then
		-- return false, {error_code = }
	end

	if command[cmd] then
		return command[cmd](self,...)
	elseif self.impl.on_command then
		return self.impl:on_command(cmd,...)
	elseif self.impl.command and self.impl.command[cmd] then
		return self.impl.command[cmd](self.impl, ...)
	else
		return false, {error_code=0,error_desc="command no handle"}
	end
end

function base_module:on_event(event_id, ...)
	-- body
end

function base_module:on_timer(timer_id, ...)
end

return base_module
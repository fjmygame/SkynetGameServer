local mgr = {}
mgr.__index = mgr

local function loadconfig(self)
    if not self._path then return end

    local f = io.open(self._path)
    if not f then return end
    local source = f:read "*a"
    f:close()
    assert(load(source, "@"..self._path, "t", self._nodes))()
end

function mgr:sync(force)
    if self._path and (force or self._changed) then
    	local f = assert(io.open(self._pathm, 'w'))
    	for k,v in pairs(self._nodes) do
    	    f:write(string.format('%s = "%s"\n', k, v))
    	end

    	f:flush()
    	f:close()
    end
    self._changed = nil
end

function mgr:set(name,endpoit,no_sync)
	local changed
	if self._nodes[name] ~= endpoit then
	    self._nodes[name] = assert(endpoit)
	    changed = true
	end
	self._changed = self._changed or changed
	if not no_sync then self:sync() end
	return changed
end

function mgr:get(name)
	return self._nodes[name]
end

function mgr:set_all(nodes,no_sync)
	local changed
	local old_nodes = self._nodes
	self._nodes = nodes or {}
	if nodes then
        for k,v in pairs(nodes) do
            if v ~= old_nodes[k] then
                changed = true
                break
            end
            old_nodes[k] = nil
        end
	end
	if not changed then changed = next(old_nodes) and true end
	self._changed = self._changed or changed
	if not no_sync then self:sync() end
	return changed
end

function mgr:mset(nodes,no_sync)
	if not nodes then return end
	local changed
	for k,v in pairs(nodes) do
        if not changed then changed = (v ~= self._nodes[k]) end
        self._nodes[k] = v
    end
	self._changed = self._changed or changed
	if not no_sync then self:sync() end
	return changed
end

function mgr:names(pat)
	local names = {}
	if not pat or pat == ".*" then
        for name in pairs(self._nodes) do table.insert(names,name) end
        return names
	end
	for name in pairs(self._nodes) do 
		if name:match(pat) == name then table.insert(names,name) end 
	end
    return names
end

function mgr:get_all(clone)
	if not clone then return self._nodes end
	local nodes = {}
	for k,v in pairs(self._nodes) do
		nodes[k] = v
	end
	return nodes
end

function mgr.new(path,nodes)
	local self = setmetatable({_path = path, _changed = false}, mgr)
	if nodes then
		self._nodes = nodes
		self:sync(true)
	else
		self._nodes = {}
		loadconfig(self)
	end
	return self
end

return mgr
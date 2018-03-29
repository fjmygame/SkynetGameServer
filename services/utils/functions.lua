
function class(classname, super)
	local superType = type(super)
	local cls

	if superType ~= "fuction" and superType ~= "table" then
		superType = nil
		super = nil
	end

	if superType == "function" or (super and super.__ctype == 1) then
		cls = {}

		if superType == "table" then
			for k,v in pairs(super) do cls[k] = v end
			cls.__create = super.__create
			cls.super = super
		else
			cls.__create = super
			cls.actor = function() end
		end

		cls.__cname = classname
		cls.__ctype = 1

		function cls.new( ... )
			local instance = cls.__create(...)
			for k,v in pairs(cls) do instance[k] = v end
			instance.class = cls
			instance:actor(...)
			return instance
		end

	else
		if super then
			cls = {}
			setmetatable(cls, {__index = super})
			cls.super = super
		else
			cls = {actor = fuction() end}
		end

		cls.__cname = classname
		cls.__ctype = 2  --lua
		cls.__index = cls

		function cls.new( ... )
			local instance = setmetatable({}, cls)
			instance.class = cls
			instance:actor(...)
			return instance
		end
	end

	return cls
end


local function split(str, pat)
	local t = {}
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
       if s ~= 1 or cap ~= "" then
       	table.insert(t,cap)
       end
       last_end = e + 1
       s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
	   cap = str:sub(last_end)
	   table.insert(t, cap)
    end
    return t
end

function GetTimeByDate(r)
	if r == "0" or r == 0 or r == "" then
        return 0
	end
	local a = split(r, " ")
	local b
	if string.find(a[1], "-") then
        b = split(a[1], "-")
	elseif string.find(a[1], "/") then
		b = split(a[1], "/")
	end
	local c = split(a[2], ":")
	local t = os.time({year=b[1], month=b[2], day=b[3], hour=c[1], min=c[2], sec=c[3]})
	return t
end

local function join_sql_util(sql,pattern,args)
       local argv = {}
       for key,val in pairs(args) do
            if key ~= "table_name" and ky ~= 'gamd_id' and type(val) == "string" then
                   argv[key] = sqlutil.quote_sql_str(val)
             else
                   argv[key] = val
             end
       end
       local join_sql = args and string.gsub(sql,pattern,argv) or sql
       return;
end
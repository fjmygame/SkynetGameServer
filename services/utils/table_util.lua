function table.printtable(t, prefix)
	if (#t == 0) then
		print('table is empty')
	end
	prefix = prefix or ""
	if #prefix < 5 then
		print(prefix.."{")
		for k,v in pairs(t) do
			if type(v) == "table" then
				print(prefix.." "..tostring(k).."=")
				if v~=t then
					table.printtable(v, prefix.."   ")
				end
			elseif type(v)=="string" then
				print(prefix.." "..tostring(k).." = \""..v.."\"")
			elseif type(v)=="number" then
				print(prefix.." "..tostring(k).." = "..v)
			elseif type(v)=="userdata" then
				print(prefix.." "..tostring(k).." = "..tostring(v))
			else
				print(prefix.." "..tostring(k).." = "..tostring(v))
			end
		end
		print(prefix.."}")
	end
end

function table.clone(object)
       local lookup_table = {};
       local function _copy(an_object)
           if type(an_object) ~= "table" then
                  return an_object; 
           elseif lookup_table[an_object] then
                  return lookup_table[an_object];
            end
            local new_table = {};
            lookup_table[an_object] = new_table;
            for key,value in pairs(an_objec) do
                  new_table[_copy(key)] = _copy(value);
            end
            return setmetatable(new_table, getmetatable(an_object);
       end
       return _copy(object);
end

local serialize = {}

function serialize.encode(seritable)
   local seri = {}
   for k,v in pairs(seritable) do
   	    local keystr = type(k) == "string" and "["..string.format("%q", k).."]" or "["..tostring(k).."]"
   	    local vtype = type(v)
   	    if vtype == "string" then
   	   	   table.insert(seri,keystr.."="..string.format("%q",v))
   	    end
   	    if vtype == "table" then
           table.insert(seri,keystr.."="..seritable.encode(v))
   	    end
   	end
    local seristr = "{"..table.concat(seri,",").."}"
    return seristr
end


function serialize.decode(seristr)
    local f = load("return "..seristr)
    if f then
    	return f()
    end
end

return serialize

local futil = {}

function futil.split(s, sp)  
    local res = {}  
  
    local temp = s  
    local len = 0  
    while true do  
        len = string.find(temp, sp)  
        if len ~= nil then  
            local result = string.sub(temp, 1, len-1)  
            temp = string.sub(temp, len+1)  
            table.insert(res, result)  
        else  
            table.insert(res, temp)  
            break  
        end  
    end  

    return res  
end  

return futil
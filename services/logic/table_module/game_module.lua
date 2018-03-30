
local table_module = {}

function table_module.call_agent_in_chair(chair_id, cmd, ...)
    if  chair_id == ALL_CHAIR then
    	for k,v in pairs(self.players_in_chair) do
            self:call_agent_in_table(v.room_info.uid, cmd, ...)
    	end
    	return true
    elseif chair_id > 0 and chair_id <= self:get_chair_count() then
    	return self:call_agent_in_table(self.players_in_chair[chair_id].room_info.uid, cmd, ...)
    else
    	return false
    end
end

return table_module
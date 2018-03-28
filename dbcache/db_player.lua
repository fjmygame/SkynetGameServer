
local db_player = {}

db_player.get_user_info = {
	sql = "select * from db_player.accouts where uid = $uid"
}

return db_player
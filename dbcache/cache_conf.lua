local skynet = require "skynet"
local lfs = require "lfs"

local gameid = skynet.getenv "gameid"

local gameid_list = skynet.getenv "master_gameid"

local master_gameid = {}

local cache_conf = 
{
	db_game = require "db_game"
}

local function recur_travese_conf(conf,game_id)
	-- body
end

if gameid then
	recur_travese_conf(cache_conf,gameid)
end

for i=1,#master_gameid do
   recur_travese_conf(cache_conf,master_gameid[i])
end
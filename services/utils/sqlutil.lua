local mysql = require "mysql"

local sqlutil = {}

function sqlutil.mysql_err(res,sql)
	if not res then
		-- logger.err()
        return true
	end

	if res.badresult == true then
        -- logger.err
        return true
	end

	return false
end

function sqlutil.quote_sql_str(str)
	return mysql.quote_sql_str(str)
end

return sqlutil
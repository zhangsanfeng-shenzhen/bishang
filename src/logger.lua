local _M = { _VERSION = '0.11' }

function _M.log(...)
	local arg = {...}
	local msg = os.date("%Y-%m-%d %H:%M:%S")
	for k,v in pairs(arg) do
		if v ~= nil then
			msg = msg..tostring(v)
		end
	end
	file = io.open("logger.log", "a+")
	if file then
		file:write(os.date("%Y-%m-%d %H:%M:%S ") .. tostring(msg) .. "\n")
		file:close()
	end
	
end

return _M

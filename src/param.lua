local openssl = require'openssl'
local cipher = require'openssl'.cipher
local json = require("cjson")

msg='abcdabcdabcdabcdabcdabcd'
alg='des-ede-cbc'
key = "RDFlkt255HDld1DFG4GfD7Eg6FHF98RTY767HYRTefjk6eER1r5567ERT6542YRTYd56r6GH6FG24FGH86f37"

function testCipher()
	local c,d
	cipher.cipher(alg,true,msg,key)
        c = cipher.encrypt(alg,msg,key)
        d = cipher.decrypt(alg,c,key)
	print(d,msg)
end

local function get_json_file_string()
	local file = io.open("param.json","r")

	local str
	if file then
		str = file:read("*all")
		file:close()
	end
	if str then
		local de = cipher.decrypt(alg, str, key)
		if de then
			local js = json.decode(de)
			return js
		end
	end
end

local _M = { _VERSION = '0.11' }
	local js = get_json_file_string()
	if js then
		_M.ELECSTRUM_URL = js["ELECSTRUM_URL"]
		_M.ELECSTRUM_USERPWD = js["ELECSTRUM_USERPWD"]
		_M.password = js["password"]
		_M.redis_ip = js["redis_ip"]
		_M.redis_port = js["redis_port"]
		_M.redis_passwd = js["redis_passwd"]
	end
return _M
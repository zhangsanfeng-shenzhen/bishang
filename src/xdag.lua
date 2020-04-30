local curl = require("luacurl")
local json = require("cjson")
require("socket")

local _M = { _VERSION = '0.11' }
math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6))

local function get_xdag_reponse(post)
	local result = {}
	local c = curl.new()
	c:setopt(curl.OPT_URL, "127.0.0.1:7667")
	c:setopt(curl.OPT_POST, true)
	c:setopt(curl.OPT_TIMEOUT, 3)
	--c:setopt(curl.OPT_USERPWD, param.ELECSTRUM_USERPWD);
	c:setopt(curl.OPT_WRITEDATA, result)
	c:setopt(curl.OPT_POSTFIELDS, post)
	c:setopt(curl.OPT_WRITEFUNCTION, function(tab, buffer)
		table.insert(tab, buffer)
		return #buffer
	end)
	local ok = c:perform()
	c:close()

	return ok, table.concat(result)
end

function _M.get_version()
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "xdag_version"
	post["params"] = {}
	post = json.encode(post)
	local ok, res = get_xdag_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.xdag_get_account()
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "xdag_get_account"
	post["params"] = {}
	post["params"][1] = ""
	post = json.encode(post)
	local ok, res = get_xdag_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.xdag_get_balance()
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "xdag_get_balance"
	post["params"] = {}
	post["params"][1] = ""
	post = json.encode(post)
	local ok, res = get_xdag_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.xdag_stats()
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "xdag_stats"
	post["params"] = {}
	post["params"][1] = ""
	post = json.encode(post)
	local ok, res = get_xdag_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.xdag_get_block_info()
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "xdag_get_block_info"
	post["params"] = {}
	post["params"][1] = "V2OFkfLsIrF6H0uO2hYbZmLOUgGgsp7V"
	post = json.encode(post)
	local ok, res = get_xdag_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.xdag_do_xfer(addr,amount)
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "xdag_do_xfer"
	post["params"] = {}
	local tmp = {}
	tmp["address"]=tostring(addr)
	tmp["remark"]="REMARK"
	tmp["amount"]=tostring(amount)
	table.insert(post["params"], tmp)
	post = json.encode(post)
	print(post)
	local ok, res = get_xdag_reponse(post)
	if ok then
		return res
	end

	return nil
end

return _M

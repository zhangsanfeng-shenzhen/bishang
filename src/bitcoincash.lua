local curl = require("luacurl")
local json = require("cjson")
local param = require("param")
require("socket")

local _M = { _VERSION = '0.11' }
math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6))

local function get_elecstrum_reponse(post)
	local result = {}
	local c = curl.new()
	c:setopt(curl.OPT_URL, param.ELECSTRUM_URL)
	c:setopt(curl.OPT_POST, true)
	c:setopt(curl.OPT_TIMEOUT, 3)
	c:setopt(curl.OPT_USERPWD, param.ELECSTRUM_USERPWD);
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
	post["method"] = "version"
	post["params"] = {}
	post = json.encode(post)
	local ok, res = get_elecstrum_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.create_new_address()
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "createnewaddress"
	post["params"] = {}
	post = json.encode(post)

	ok, res = get_elecstrum_reponse(post)
	if ok then
		local js = json.decode(res)
		if js and js["result"] then
			return js["result"]
		end
	end

	return nil
end

function _M.is_validate_address(address)
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "validateaddress"
	post["params"] = {}
	post["params"][1] = address
	post = json.encode(post)

	ok, res = get_elecstrum_reponse(post)
	if ok then
		local js = json.decode(res)
		if js and js["result"] then
			return js["result"]
		end
	end

	return nil
end

function _M.get_address_balance(address)
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "getaddressbalance"
	post["params"] = {}
	post["params"][1] = address
	post = json.encode(post)

	ok, res = get_elecstrum_reponse(post)
	if ok then
		local js = json.decode(res)
		if js and js["result"] then
			return js["result"]
		end
	end

	return nil
end

function _M.validate_address(address)
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "validateaddress"
	post["params"] = {}
	post["params"][1] = address
	post = json.encode(post)

	ok, res = get_elecstrum_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.payto_address_coin(from, destination, amount)
	if from == destination then
		return nil
	end

	if tonumber(amount) < 0.00000546 then
		return nil
	end

	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "payto"
	post["params"] = {}
	post["params"]["from_addr"] = tostring(from)
	post["params"]["change_addr"] = tostring(from)
	post["params"]["password"] = tostring(param.password)
	post["params"]["destination"] = tostring(destination)
	post["params"]["amount"] = tostring(amount)

	post = json.encode(post)

	ok, res = get_elecstrum_reponse(post)
	if ok then
		local js = json.decode(res)
		if js and js["result"] and js["result"]["hex"] then
			return js["result"]["hex"]
		end
	end

	return nil
end

function _M.broadcast_tx(tx)
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "broadcast"
	post["params"] = {}
	post["params"]["tx"] = tostring(tx)
	post = json.encode(post)

	local ok, res = get_elecstrum_reponse(post)
	if ok then
		return res
	end

	return nil
end

function _M.paytomany_address_coin(from, list)
	local post = {}
	post["id"] = tostring(math.random(1,999999999))
	post["method"] = "paytomany"
	post["params"] = {}
	post["params"]["password"] = tostring(param.password)
	post["params"]["from_addr"] = tostring(from)
	post["params"]["change_addr"] = tostring(from)
	post["params"]["outputs"] = {}
	post["params"]["outputs"] = list

	post = json.encode(post)

	ok, res = get_elecstrum_reponse(post)
	if ok then
		local js = json.decode(res)
		if js and js["result"] and js["result"]["hex"] then
			return js["result"]["hex"]
		end
	end

	return nil
end

return _M

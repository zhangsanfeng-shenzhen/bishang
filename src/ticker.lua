local _M = { _VERSION = '0.11' }

local cjson = require "cjson"

local function get_tickers()
	local url = "https://www.binance-cn.com/api/v1/ticker/24hr"
	local cmd = string.format('curl %s --connect-timeout 4', url)
	local file = io.popen(cmd)
	str = file:read("*all")
	file:close()
	if str and string.len(str)>100 then
		local str_json = cjson.decode(str)
		local tmp = {}
		for i=1,#str_json do
			if str_json[i]["symbol"]:sub(-4,-1) == "USDT" then
				str_json[i]["symbol"] = str_json[i]["symbol"]:sub(1,-5)
				table.insert(tmp, str_json[i])
			end
		end
		local file = io.open("/tmp/vol.json","w")
		file:write(cjson.encode(tmp))
		file:close()
		return true
	end
	return nil
end

function _M.get_tickers_trys()
	for i=1,3 do
		if get_tickers() then
			break
		end
	end
end

function _M.get_coin_info()
	local function get_usdt_coin()
		local file = io.open("/tmp/vol.json")
		local str = file:read("*all")
		file:close()
		return cjson.decode(str)
	end

	local function vol_sort_list()
		local list = get_usdt_coin()
		local len = #list

		for i=1,#list do
			for j=i,#list do
				if tonumber(list[i]["quoteVolume"]) < tonumber(list[j]["quoteVolume"]) then
					tmp = list[i]
					list[i] = list[j]
					list[j] = tmp
				end
			end
		end
		return list
	end

	local str = ""
	local list = vol_sort_list()
	if list == nil then
		return nil
	end

	local info_list = {}
	for i=1,#list do
		local info = {}
		info["wave"] = string.format("%.2f",(list[i]["lastPrice"] - list[i]["openPrice"])*100/list[i]["openPrice"])
		info["coin_name"] = list[i]["symbol"]
		if info["coin_name"] == "BCHABC" then
			info["coin_name"] ="BCH"
		end
		info["usdt"] = string.format("%3.2f",list[i]["lastPrice"])
		print(info["wave"], info["coin_name"],info["usdt"],list[i]["quoteVolume"])
		table.insert(info_list,info)
	end
	return info_list
end

return _M
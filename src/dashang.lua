local curl = require("luacurl")
local json = require("cjson")
local bitcoincash = require("bitcoincash")
local sql = require("sql")
local param = require("param")
local logger = require("logger")
require("socket")
math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6))

local function get_html(url)
	local result = {}
	local c = curl.new()
	c:setopt(curl.OPT_URL, url)
	c:setopt(curl.OPT_TIMEOUT, 3)
	c:setopt(curl.OPT_WRITEDATA, result)
	c:setopt(curl.OPT_WRITEFUNCTION, function(tab, buffer)
		table.insert(tab, buffer)
		return #buffer
	end)
	local ok = c:perform()
	c:close()

	return ok, table.concat(result)
end


local function weibo_comments_show(count)
	local prama = "access_token=2.006auh_H0sywppe3fc5368cc0L3aIC&id=4400486146476800&page="
	local url = "https://api.weibo.com/2/comments/show.json?%s%d"
	local get = string.format(url,prama,count)
	print(get)
	local ok, res = get_html(get)
	if ok then
		return res
	else
		logger.log("weibo comments mentions is failed!", res)
	end
end

--[[
for i=1,4 do
	local str = weibo_comments_show(i)
	if not str or string.len(str) < 10 then
		logger.log("weibo comments mentions return string is null !")
		return
	end

	local file = io.open(tostring(i)..tostring(os.time())..".html","w+")
	file:write(str)
	file:close()

	local js = json.decode(str)
	if js and js["comments"] then
		for j=1, #js["comments"] do
			local cmd = js["comments"][j]
			print(cmd["user"]["id"])
			local receive_addr = sql.sql_get_user_address(cmd["user"]["id"])
			if receive_addr == nil then
				receive_addr = sql.sql_creat_user_addr(cmd["user"]["id"])
				if receive_addr then
					sql.sql_set_user_addr(cmd["user"]["id"], receive_addr)
				else
					logger.log("malloc receive address is failed !")
				end
			end
			sql.sql_write_dashang_data(receive_addr, cmd["user"]["screen_name"], cmd["user"]["id"])
		end
	end
end


local addr_list = sql.sql_get_dashang_addr()
local coin = string.format("%.7f", (1/88))
local send_addr = "qpq0xnp204mghwzwxny57ffhg9cx3p8cyskfmss6ev"
local hex = bitcoincash.paytomany_address_coin(send_addr, addr_list, coin)
bitcoincash.broadcast_tx(hex)

for i=1,#addr_list do
	print(addr_list[i])
end
]]--
local curl = require("luacurl")
local json = require("cjson")
local bitcoincash = require("bitcoincash")
local sql = require("sql")
local param = require("param")
local logger = require("logger")
local ticker = require("ticker")
require("socket")
math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6))
payto_coin_list ={}

local slogan = {"BCH，一个快速崛起的数字货币生态",
		"BCH是目前在区块链领域的最佳实践",
		"BCH，一个点对点的电子现金系统",
		"支付就用比特现金！",
		"BTC是过去，BCH是未来",
		"比特现金，全球通，转账快，费用低，转账就用比特现金！",
		"BCH，free your cap",
		"BCH，世界的数字货币",
		"BCH，一种去中心化的点对点的高度安全的数字货币 ",
		"BCH是唯一能实现即时到账手续费低于0.01%的比特币",
		"因为共识，所以本真。BCH，真BTC",
		"BCH：未来全宇宙的通用货币 ",
		"bitcoin cash is what bitcoin should be",
		"BCH世界上最可靠的钱 ",
		"用BCH支付，手续费更低，速度更快。",
		"现金为王，比特币现金为比特币之王",
		"BCH，引领未来金融",
		"BCH，让人互相信任的货币。",
		"BCH是一种安全、稳定、可靠的去中心化数字货币",
		"BCH更加有鲁棒性的比特币，会让比特币再次伟大",
		"BCH，一个成功基于区块链的点对点价值传输系统，来自开放的大区块派",
		"BCH 连微博都可以用的数字货币 ",
		"BCH，还是熟悉的味道，熟悉的比特币",
		"BCH，原来它才是正宗的比特币 ",
		"每个人要至少持有一个bch ",
		"人中吕布，马中赤兔，数字货币中的BCH",
		"BCH：极低费用，快速全球 ，属于自己的货币！",
		"我们没创造比特币，我们只是中本聪白皮书的搬运工",
		"BCH，真正自由的货币",
		"bitcoin cash,,,bitcoin plus",
		"bitcoin cash,生而自由",
		"BCH是未来支付人数最多，手续费最低的真实货币",
		"BCH, your financial freedom. ",
		"BCH,升级后的比特币",
		"BCH,一个遵循中本聪白皮书的点对点电子现金系统",
		"支付就用比特现金！",
		"BCH世界上最可靠的钱",
		"感谢您使用我们币赏的功能"
}

local function encodeURI(str)
	str = string.gsub(str, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	return string.gsub(str, " ", "+")
end

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

local function post_html(url, post)
	local result = {}
	local c = curl.new()
	c:setopt(curl.OPT_URL, url)
	c:setopt(curl.OPT_POST, true)
	c:setopt(curl.OPT_TIMEOUT, 3)
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

local function weibo_comments_mentions(count)
	local prama = "access_token=2.006auh_H0sywppe3fc5368cc0L3aIC&since_id="
	local url = "https://api.weibo.com/2/comments/mentions.json?%s%d"
	local get = string.format(url,prama,count)
	--print(get)
	local ok, res = get_html(get)
	if ok then
		return res
	else
		logger.log("weibo comments mentions is failed!", res)
	end
end

local function weibo_comments_reply(cid, id, name, coin)
	coin = coin/0.00000546
	local num = math.mod(math.random(1,200),#slogan)+1
	local reply_msg = string.format("打赏成功！您已给 %s 打赏%d金(%d聪),查看余额请私信币赏，发送“余额”即可查看余额情况！%s",name, tonumber(coin), tonumber(coin)*546, slogan[num])
	local post = "access_token=%s&cid=%s&id=%s&comment=%s"
	local parma = string.format(post,"2.006auh_H0sywppe3fc5368cc0L3aIC", tostring(cid), tostring(id), 
			encodeURI(reply_msg))
	local url = "https://api.weibo.com/2/comments/reply.json"
	local ok, res = post_html(url, parma)
	if ok then
		return res
	else
		logger.log("weibo comments reply is failed!", res)
	end
end

local function send_bch_coin(send_addr, receive_addr, text)
	if text and text:find("@币赏") then
		local coin, currency = string.match(text, "@币赏%s+(%d+)(.+)")
		if coin and tonumber(coin) and currency and currency:sub(1,3) then
			local translation = currency:sub(1,3)
			if translation == "金" then
				coin = coin * 546
			elseif translation == "镒" then
				coin = coin * 546 * 1000
			else
				coin = 0
			end
			coin = coin/(1*1000*1000*100)
			print(string.format("%0.8f",coin))

			local confirmed = bitcoincash.get_address_balance(send_addr)
			if  confirmed["confirmed"] and confirmed["unconfirmed"] then
				local money = tonumber(confirmed["confirmed"]) + tonumber(confirmed["unconfirmed"])
				if money > coin + 546/(1*1000*1000*50) then
					--local hex = bitcoincash.payto_address_coin(send_addr, receive_addr, coin)
					--bitcoincash.broadcast_tx(hex)
					for i=1,#payto_coin_list do
						if payto_coin_list[i]["send"] and payto_coin_list[i]["send"] == send_addr then
							local tmp = {receive_addr, tostring(coin)}
							table.insert(payto_coin_list[i]["recv"], tmp)
							return coin
						end
					end
					local tmp = {}
					tmp["recv"] = {}
					tmp["send"] = send_addr
					table.insert(tmp["recv"],{receive_addr, tostring(coin)})
					table.insert(payto_coin_list, tmp)
					return coin
				else
					logger.log("Sorry, "..send_addr.."address credit is running low")
				end
			end
		end
	end
end

local function send_xdag_coin(text)

end

local function get_coin_type(text)
	if text and text:find("@币赏") then
		local coin, currency = string.match(text, "@币赏%s+(%d+)(.+)")
		if coin and tonumber(coin) and currency and currency:sub(1,3) then
			local translation = currency:sub(1,3)
			if translation == "金" or translation == "镒" then
				return "bch"
			elseif translation == "叉" then
				return "xdag"
			end
		end
	end
end

local function weibo_message_processing(count)
	local str = weibo_comments_mentions(count)
	if not str or string.len(str) < 10 then
		logger.log("weibo comments mentions return string is null !")
		return
	end
	
	--print(str)
	local list = {}
	local js = json.decode(str)
	if js and js["comments"] then
		for i=1, #js["comments"] do
			local cmd = js["comments"][i]
			--lcoal created_at,main_id,send_id,send_name,receive_id,receive_name
			if cmd["reply_comment"] then
				created_at = cmd["reply_comment"]["created_at"]
				main_id = cmd["reply_comment"]["idstr"]
				send_id = cmd["user"]["id"]
				send_name = cmd["user"]["screen_name"]
				receive_id = cmd["reply_comment"]["user"]["id"]
				receive_name = cmd["reply_comment"]["user"]["screen_name"]
				coin_type = get_coin_type(cmd["text"])
			else
				created_at = cmd["created_at"]
				main_id = cmd["idstr"]
				send_id = cmd["user"]["id"]
				send_name = cmd["user"]["screen_name"]
				receive_id = cmd["status"]["user"]["id"]
				receive_name = cmd["status"]["user"]["screen_name"]
				coin_type = get_coin_type(cmd["text"])
			end

			local send_addr = sql.sql_get_user_address(coin_type, send_id)
			if send_addr == nil then
				send_addr = sql.sql_creat_user_addr(coin_type, send_id)
				if send_addr then
					sql.sql_set_user_addr(coin_type, send_id, send_addr)
				else
					logger.log("malloc send address is failed !")
				end
			end
			
			local receive_addr = sql.sql_get_user_address(coin_type, receive_id)
			if receive_addr == nil then
				receive_addr = sql.sql_creat_user_addr(coin_type, receive_id)
				if receive_addr then
					sql.sql_set_user_addr(coin_type, receive_id, receive_addr)
				else
					logger.log("malloc receive address is failed !")
				end
			end
			if sql.sql_find_deal_id(main_id) == false then
				if coin_type == "bch" then
					local coin = send_bch_coin(send_addr, receive_addr, cmd["text"])
					print(coin)
					if coin then
						local num = math.random(0,100)
						if num < 80 then
							local res = weibo_comments_reply(main_id, cmd["status"]["idstr"], receive_name, coin)
							print(res)
						end
					end
					print(created_at, main_id, send_id, send_name,
					receive_id, receive_name, send_addr, receive_addr, cmd["text"])
					sql.sql_write_deal_data(created_at, main_id, send_id, send_name,
						receive_id, receive_name, send_addr, receive_addr, cmd["text"])
					table.insert(list, main_id)
				end
			end
			table.insert(list, main_id)
		end
	end

	for i=1,#payto_coin_list do
		print("hhh", payto_coin_list[i]["send"], payto_coin_list[i]["recv"])
		local hex = bitcoincash.paytomany_address_coin(payto_coin_list[i]["send"], payto_coin_list[i]["recv"])
		bitcoincash.broadcast_tx(hex)
	end
	payto_coin_list = {}
	table.sort(list)
	if list then
		return list[#list]
	end
	return nil
end

local redis = require 'redis'
local red = redis.connect(param.redis_ip, param.redis_port)
red:auth(param.redis_passwd)
while 1 do
	local since_id = red:get("since_id")
	if not since_id then
		since_id = 0
	end

	since_id = weibo_message_processing(since_id)
	if since_id then
		red:set("since_id", since_id)
	end

	ticker.get_tickers_trys()
	os.execute("sleep 120")
end
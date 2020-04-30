local json = require("cjson")
local sql = require("sql")
local bitcoincash = require("bitcoincash")
local param = require("param")
local redis = require ("redis")
local logger = require("logger")
local ticker = require("ticker")
require("socket")
local red = redis.connect(param.redis_ip, param.redis_port)
red:auth(param.redis_passwd)

local function encodeURI(str)
	str = string.gsub(str, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	return string.gsub(str, " ", "+")
end

local function send_msg(js, msg)
	local post = {}
	post["result"] = true
	post["receiver_id"] = tonumber(js["sender_id"])
	post["sender_id"] = tonumber(js["receiver_id"])
	post["type"] = "text"
	post["data"] = {}
	post["data"]["text"] = tostring(msg)
	local data = json.encode(post)
	ngx.say(data)
end

function lua_string_split(str, split_char)
	local sub_str_tab = {}
	while (true) do
		local pos = string.find(str, split_char)
		if (not pos) then
			sub_str_tab[#sub_str_tab + 1] = str
			break
		end
		local sub_str = string.sub(str, 1, pos - 1)
		sub_str_tab[#sub_str_tab + 1] = sub_str
		str = string.sub(str, pos + 1, #str)
	end

	return sub_str_tab;
end

local function bch_check_out(js,str_table)
	if str_table[3] then
		if bitcoincash.is_validate_address(tostring(str_table[3])) ~= true then
			local command = "地址填写错误，请检查后再试"
			send_msg(js,encodeURI(command))
			return
		end
	end

	local cash = str_table[4]
	if string.lower(cash) ~= "all" and string.lower(cash) ~= "half" then
		if not tonumber(cash) then
			if cash:sub(-3,-1) == "金" and tonumber(cash:sub(1,-4)) then
				cash = tonumber(cash:sub(1,-4))*0.00000546
			else
				local command = "格式错误，请检查后再试！正确格式为 提现 bch pxxxxxxxxxxxxxxxxxxxx 数量"
				send_msg(js,encodeURI(command))
				return
			end
		else
			if tonumber(cash) < 2.0 then
				local command = "格式错误，提款金额必须大于2金(包括手续费)"
				send_msg(js,encodeURI(command))
				return
			end
			cash = tonumber(cash)*0.00000546
		end
	end

	if str_table[5] and str_table[5] ~= "金"  then
		return nil,"格式错误，提款金额的单位必须为金"
	end

	local send_addr = sql.sql_get_user_address("bch",js["sender_id"])
	if not send_addr then
		send_addr = sql.sql_creat_user_addr("bch", js["sender_id"])
		sql.sql_set_user_addr("bch", js["sender_id"], send_addr)
		local command = "您还没有注册！后台在为您分配地址，请稍后再次查询"
		send_msg(js,encodeURI(command))
		return
	end

	local balance = bitcoincash.get_address_balance(send_addr)
	if balance then
		local money = tonumber(balance["confirmed"]) + tonumber(balance["unconfirmed"])
		if money < 0.00000546 then
			local command = "您的余额太低，少于1金，不予提取，请联系三疯解决"
			send_msg(js,encodeURI(command))
			return
		end
		if string.lower(cash) == "all" then
			cash = money
		elseif string.lower(cash) == "half" then
			cash = money/2
		end
		if money < tonumber(cash) then
			local command = "您的余额不足，请检查后再试"
			send_msg(js,encodeURI(command))
			return
		end
	end

	local tmp = {}
	tmp["send_addr"] = send_addr
	tmp["receive_addr"] = tostring(str_table[3])
	tmp["cash"] = cash
	tmp["time"] = tostring(os.time())
	tmp = json.encode(tmp)
	if tmp and js["sender_id"] then
		red:set(tostring(js["sender_id"]), tostring(tmp))
	end
	local confirm_str = string.format("是否确定给%s发送金额%d金(%f BCH)？请回复 是 或者 否", str_table[3],tonumber(cash)/0.00000546,cash)
	send_msg(js,encodeURI(confirm_str))
end

local function check_cash_out(js)
	local str = js["text"]
	if str == nil or string.len(str) < 6 then
		local command = "格式错误，请检查后再试！正确格式为 提现 币种 pxxxxxxxxxxxxxxxxxxxx 数量"
		send_msg(js,encodeURI(command))
		return
	end
	local str_table = {}
	str_table = lua_string_split(str, ' ')

	if #str_table == 4 or #str_table == 5 then
		if str_table[1] ~= "提现" then
			local command = "格式错误，请检查后再试！正确格式为 提现 币种 pxxxxxxxxxxxxxxxxxxxx 数量"
			send_msg(js,encodeURI(command))
			return
		end

		if string.lower(str_table[2]) then
			if string.lower(str_table[2]) ~= "bch" and string.lower(str_table[2]) ~= "xdag" then
				local command = "币赏只支持bch和xdag两个币种！正确格式为 提现 币种 pxxxxxxxxxxxxxxxxxxxx 数量"
				send_msg(js,encodeURI(command))
				return
			end
		end

		if string.lower(str_table[2]) == "bch" then
			bch_check_out(js,str_table)
		elseif string.lower(str_table[2]) == "xdag" then
			xdag_check_out(js,str_table)
		end
	else
		local command = "格式错误，请检查后再试！正确格式为 提现 币种 pxxxxxxxxxxxxxxxxxxxx 数量"
		send_msg(js,encodeURI(command))
	end
end

local function msg_check_return(js)
	if js["text"] == "命令" then
		local command = "本应用支持以下命令：%0a充值%0a地址%0a余额%0a提现%0a账单%0a行情"
		send_msg(js,encodeURI(command))
	elseif js["text"] == "充值" or js["text"] == "地址" then
		local addr = sql.sql_get_user_address("bch",js["sender_id"])
		if not addr then
			addr = sql.sql_creat_user_addr("bch",js["sender_id"])
			sql.sql_set_user_addr("bch",js["sender_id"], addr)
		end
		local result = string.format("%s",tostring(addr))
		send_msg(js, result)
		return
	elseif js["text"] == "余额" then
		local addr = sql.sql_get_user_address("bch",js["sender_id"])
		if not addr then
			addr = sql.sql_creat_user_addr("bch",js["sender_id"])
			sql.sql_set_user_addr("bch",js["sender_id"], addr)
			local str = encodeURI("您还没有注册！后台在为您分配地址，请稍后再次查询")
			send_msg(js, str)
			return
		end
		local balance = bitcoincash.get_address_balance(addr)
		if balance then
			local str = string.format("您的余额为：%d金(%f BCH)%%0a", math.floor(balance["confirmed"]/0.00000546), balance["confirmed"])
			if balance["unconfirmed"]~=nil and tonumber(balance["unconfirmed"]) ~= 0 then
				str = str..string.format("锁定金额为：%d金(%f BCH)", math.ceil(balance["unconfirmed"]/0.00000546), balance["unconfirmed"])
			end
			send_msg(js, encodeURI(str))
			return
		end
	elseif js["text"] and js["text"]:sub(1,6) == "提现" then
		check_cash_out(js)
	elseif js["text"] == "否" then
		local tmp = {}
		tmp = json.encode(tmp)
		red:set(tostring(js["sender_id"]), tostring(tmp))
	elseif js["text"] == "是" then
		if js["sender_id"] then
			local tmp = red:get(tostring(js["sender_id"]))
			if tmp then
				local data = json.decode(tmp)
				--超过60秒再回复就不算了
				if data and data["time"] and tonumber(data["time"]) + 60 > tonumber(os.time()) then
					local cash = data["cash"] - 0.00000546
					local hex = bitcoincash.payto_address_coin(data["send_addr"], data["receive_addr"], cash)
					bitcoincash.broadcast_tx(hex)
					sql.sql_write_coin_out_data(tostring(socket.gettime()), data["receive_addr"], 
						data["send_addr"], js["sender_id"], tostring(cash))
					send_msg(js,encodeURI("转账成功！"))
				else
					local tmp = {}
					tmp = json.encode(tmp)
					red:set(tostring(js["sender_id"]), tostring(tmp))
					send_msg(js,encodeURI("回复超时，转账失败！"))
				end
			end
		end
	elseif js["text"] == "账单" then
		local list = sql.sql_get_user_deal(js["sender_id"])
		if list == nil or #list ==0 then
			send_msg(js,encodeURI("今日尚未打赏，欢迎使用币赏打赏功能"))
		end

		local str = ""
		local index
		if #list < 8 then
			index = 1
		else
			index = #list - 7
		end
		for i = index,#list do
			local coin = string.match(list[i]["text"],"(%d+金)")
			if coin then
				local hour,min,second = string.match(list[i]["time"],"(%d+):(%d+):(%d+)")
				if list[i]["is_send"] then
					str = str .. string.format("%d时%d分%d秒 打赏 %s %s %%0a",
						hour,min,second,list[i]["name"],coin)
				else
					str = str .. string.format("%d时%d分%d秒 %s 赠与 %s %%0a",
						hour,min,second,list[i]["name"],coin)
				end
				--str = str ..list[i]["receive_id"].."   "..list[i]["xxx"]
			end
		end
		send_msg(js,encodeURI(str))
	elseif js["text"] and js["text"]:sub(1,6) == "行情" then
		local coin_info = ticker.get_coin_info()
		str_table = lua_string_split(js["text"], ' ')
		if #str_table == 2 then
			for i=1,#coin_info do
				if coin_info[i]["coin_name"] == string.upper(str_table[2]) then
					local str
					if tonumber(coin_info[i]["wave"]) < 0 then
						str = string.format("币种%s 现价$%s 跌幅%s%%", coin_info[i]["coin_name"],
							coin_info[i]["usdt"], coin_info[i]["wave"])
					else
						str = string.format("币种%s 现价$%s 涨幅%s%%", coin_info[i]["coin_name"],
							coin_info[i]["usdt"], coin_info[i]["wave"])
					end
					send_msg(js,encodeURI(str))
					return
				end
			end
			send_msg(js,encodeURI("没有找到该币种，请检查后再试"))
			return
		end
		
		local str = "币种%c2%a0%c2%a0%c2%a0%c2%a0现价(usdt)%c2%a0%c2%a0%c2%a0%c2%a0涨跌幅%0a"
		for i=1,8 do
			local tmp = string.format("%s#$%s#%s%%0a",string.upper(coin_info[i]["coin_name"]), 
				coin_info[i]["usdt"], coin_info[i]["wave"])
			tmp = string.gsub(tmp,"#","%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0%%c2%%a0")
			str = str..tmp
		end
		send_msg(js,encodeURI(str))
	else
		send_msg(js,encodeURI("未知命令，请输入“命令”查看命令列表"))
	end
end

ngx.req.read_body()
local arg = ngx.req.get_post_args()
for value in pairs(arg) do
	if value and string.len(value) > 10 then
		local js = json.decode(value)
		if js["type"] and js["type"] == "text" then
			msg_check_return(js)
			sql.sql_write_msg_data(tostring(socket.gettime()), js["type"], js["receiver_id"], js["sender_id"], js["text"])
		end
	end
end
local sqlite3 = require("luasql.sqlite3")
local json = require("cjson")
local bitcoincash = require("bitcoincash")

local _M = { _VERSION = '0.11' }

function _M.sql_set_user_addr(coin_type, user, addr)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')

	if coin_type == "bch" then
		conn:execute([[create table if not exists addr_list('id' text primary key, 'address' text)]])
		local sql = string.format('insert into addr_list values(\'%s\', \'%s\')', user, addr)
		conn:execute(sql)
	end
	conn:close()
	env:close()
end

function _M.sql_creat_user_addr(coin_type, user_id)
	if user_id == nil or coin_type == nil then
		return nil
	end
	if coin_type == "bch" then
		local addr = bitcoincash.create_new_address()
		if addr then
			return addr
		end
	end
	return nil
end

function _M.sql_get_user_address(coin_type, user_id)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')
	
	local addr = nil
	if coin_type == "bch" then
		conn:execute([[create table if not exists addr_list('id' text primary key, 'address' text)]])
		local cmd = string.format("select * from addr_list where id == %s", tostring(user_id))
		local cursor,err = conn:execute(cmd)
		if cursor then
			local row = cursor:fetch({}, "a")
			while row do
				if row.address and tostring(row.id) == tostring(user_id) then
					addr = row.address
					break
				end
				row = cursor:fetch({}, "a")
			end
			cursor:close()
		end
	end
	conn:close()
	env:close()
	return addr
end

function _M.sql_write_deal_data(created_time, deal_id, send_id, send_name, receive_id, receive_name, send_addr, receive_addr, re_text)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')

	conn:execute([[create table if not exists deal('created_time' text, 'deal_id' text primary key, 'send_id' text, 'send_name' text,
		'receive_id' text, 'receive_name' text,'send_addr' text, 'receive_addr' text, 'text' text)]])
	local sql = string.format("insert into deal values(\'%s\', \'%s\', \'%s\', \'%s\', \'%s\', \'%s\', \'%s\', \'%s\', \'%s\')",
		created_time, deal_id, send_id, send_name, receive_id, receive_name, send_addr, receive_addr, re_text)
	conn:execute(sql)
	conn:close()
	env:close()
end

function _M.sql_write_msg_data(created_time, type, receiver_id, sender_id, text)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')

	conn:execute([[create table if not exists msg('created_time' text primary key, 'type' text, 'receiver_id' text, 'sender_id' text, 'text' text)]])
	local sql = string.format("insert into msg values(\'%s\', \'%s\', \'%s\', \'%s\', \'%s\')",
		created_time, type, receiver_id, sender_id, text)
	conn:execute(sql)
	conn:close()
	env:close()
end

function _M.sql_write_coin_out_data(coin_type, created_time, receiver_addr, sender_addr, sender_id, coin)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')

	if coin_type == "bch" then
		conn:execute([[create table if not exists coin_out('created_time' text primary key, 'receiver_addr' text, 'sender_addr' text, 'sender_id' text, 'coin' text)]])
		local sql = string.format("insert into coin_out values(\'%s\', \'%s\', \'%s\', \'%s\', \'%s\')",
			created_time, receiver_addr, sender_addr, sender_id, coin)
		conn:execute(sql)
	end
	conn:close()
	env:close()
end

function _M.sql_get_user_deal(send_id)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')
	
	local deal_list = {}
	local cmd = string.format("select * from deal where send_id == %s or receive_id == %s", tostring(send_id),tostring(send_id))
	local cursor,err = conn:execute(cmd)
	if cursor then
		row = cursor:fetch({}, "a")
		while row do
			local t = string.match(row.created_time, ".-%s.-%s(.-)%s")
			if tostring(t) == tostring(os.date("%d")) then
				local msg = {}
				if tostring(send_id) == tostring(row.send_id) then
					msg["name"] = row.receive_name
					msg["is_send"] = true
				elseif tostring(send_id) == tostring(row.receive_id) then
					msg["name"] = row.send_name
					msg["is_send"] = nil
				end
				msg["time"] = row.created_time
				msg["text"] = row.text
				table.insert(deal_list, msg)
			end
			row = cursor:fetch({}, "a")
		end
		cursor:close()
	end
	conn:close()
	env:close()
	return deal_list
end

function _M.sql_find_deal_id(deal_id)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')
	
	local flag = false
	local cmd = string.format("select * from deal where deal_id == %s", tostring(deal_id))
	local cursor,err = conn:execute(cmd)
	if cursor then
		local row = cursor:fetch({}, "a")
		while row do
			if tostring(deal_id) == tostring(row.deal_id) then
				 flag = true
				 break
			end
			row = cursor:fetch({}, "a")
		end
		cursor:close()
	end
	conn:close()
	env:close()
	return flag
end


function _M.sql_write_dashang_data(addr, name, id)
	local env  = sqlite3.sqlite3()
	local conn = env:connect('dashang.db')

	conn:execute([[create table if not exists bch_1('addr' text primary key, 'name' text, 'id' text)]])
	local sql = string.format("insert into bch_1 values(\'%s\', \'%s\', \'%s\')",
		tostring(addr), tostring(name), tostring(id))
	conn:execute(sql)
	conn:close()
	env:close()
end

function _M.sql_get_dashang_addr()
	local env  = sqlite3.sqlite3()
	local conn = env:connect('dashang.db')
	
	local bch_list = {}
	local cmd = string.format("select * from bch_1")
	local cursor,err = conn:execute(cmd)
	if cursor then
		local row = cursor:fetch({}, "a")
		while row do
			table.insert(bch_list, row.addr)
			row = cursor:fetch({}, "a")
		end
		cursor:close()
	end
	conn:close()
	env:close()
	return bch_list
end


function _M.sql_get_address_list()
	local env  = sqlite3.sqlite3()
	local conn = env:connect('weibo.db')
	
	local list = {}
	local cmd = string.format("select * from addr_list")
	local cursor,err = conn:execute(cmd)
	if cursor then
		local row = cursor:fetch({}, "a")
		while row do
			if row.address then
				table.insert(list,row.address)
			end
			row = cursor:fetch({}, "a")
		end
		cursor:close()
	end
	conn:close()
	env:close()
	return list
end

return _M
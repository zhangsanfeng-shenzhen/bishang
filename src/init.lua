local function init()
	while true do
		local file = io.popen("ps aux")
		str = file:read("*all")
		file:close()

		if not str:find("lua weibo.lua") then
			os.execute("nohup lua weibo.lua &")
		end
		os.execute("sleep 60")
	end
end

init()
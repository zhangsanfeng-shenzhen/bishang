local file = io.open("index.html")
if file then
	html = file:read("*all")
	file:close()
	ngx.say(html)
end
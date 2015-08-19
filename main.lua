-- Settings
FRAMERATE = 25
FRAMECOUNT = 11
WIDTH = 1920
HEIGHT = 1080
FORCEIP = nil
SEND_TIME = 5

-- Variables
loading = "frames"
updated = false
frames = {}
playing = false
pos = 0
mute = false
screen = 1

function play()
	if loading then return end

	pos = 0
	playing = true
	
	if not mute then
		music:play()
	end
end

function getTime()
	return love.timer.getTime() - start
end

function love.load(args)
	if FORCEIP then
		args = { "lovegame", FORCEIP }
	end
	
	if #args >= 3 then
		mute = true
	end
	
	if #args >= 4 then
		screen = tonumber(args[4])
	end

	start = love.timer.getTime()
	love.window.setMode(WIDTH, HEIGHT, { ["borderless"] = true, ["display"] = screen })
	scale = WIDTH / 1920
	
	local ip
	if #args < 2 then
		server = true
		client = false
	else
		server = false
		client = true
	end
	
	require("socket")
	sock = socket.tcp()
	sockList = { sock }
	sock:setoption("tcp-nodelay", true)
	
	if server then
		sock:bind("*", 45566)
		sock:listen(16)
		sock:settimeout(10)
	elseif client then -- For the sake of readability
		sock:connect(args[2], 45566)
	end
end

function handle(s)
	local action = s:receive("*l")
	
	if action == "sync" then
		local ping = 0
		
		for i = 1, 100 do
			local start = getTime()
			s:send(tostring(math.floor(math.random() * 89197)) .. "\n")
			s:receive("*l")
			
			ping = ping + (getTime() - start)
		end
		
		s:send("end\n")
		s:send(tostring(getTime() + ping / 200) .. "\n")
	end
end

function love.update(dt)
	if trigger then
		if getTime() >= trigger then
			trigger = nil
			play()
		end
	end

	if server then
		local r, s = socket.select(sockList, nil, 1 / 60)
		
		if r then
			for k, v in ipairs(r) do
				if v == sock then
					local nc = sock:accept()
					
					if nc then
						table.insert(sockList, nc)
					end
				else
					handle(v)
				end
			end
		end
	elseif client and not trigger and not playing then
		local r, s = socket.select(sockList, nil, 1 / 60)
		
		if r and r[1] == sock then
			trigger = tonumber(sock:receive("*l"))
		end
	end

	if loading and updated then
		if loading == "frames" then
			for id = 1, FRAMECOUNT do
				frames[id] = love.graphics.newImage("frames/" .. id .. ".png")
			end
		
			loading = "music"
			updated = false
		elseif loading == "music" then
			music = love.audio.newSource("music.mp3", "static")
			music:setLooping(true)
			
			loading = client and "sync" or nil
			updated = false
		elseif loading == "sync" then
			sock:send("sync\n")
			
			while true do
				if sock:receive("*l") == "end" then
					break
				end
				
				sock:send(tostring(math.floor(math.random() * 247894)) .. "\n")
			end
			
			start = love.timer.getTime() - tonumber(sock:receive("*l"))
			loading = nil
			updated = false
		end
	elseif playing then
		pos = pos + dt * FRAMERATE
	end
end

function simplify(x)
	return tostring(x) -- tostring(math.floor(x * 1000) / 1000)
end

function love.draw()
	local g = love.graphics
	
	if loading then
		g.push()
		g.scale(4, 4)
		g.setColor(0, 255, 0)
		g.print("Loading " .. loading .. "...", 10, 10)
		g.pop()
		
		updated = true
	elseif not playing then
		local info = ""
		
		if trigger then
			info = "\n" .. simplify(trigger - getTime())
		end
		
		if server then
			info = info .. "\n" .. (#sockList - 1)
		end
	
		g.push()
		g.scale(2, 2)
		g.setColor(255, 0, 0)
		g.print(simplify(getTime()) .. info, 10, 10)
		g.pop()
	else
		g.push()
		g.scale(scale, scale)
		g.setColor(255, 255, 255, 255)
		g.draw(frames[math.floor(math.fmod(pos, FRAMECOUNT)) + 1])
		g.pop()
	end
end

function love.keyreleased()
	if server then
		trigger = getTime() + SEND_TIME
		
		for k, v in ipairs(sockList) do
			if v ~= sock then
				while true do
					-- Make sure we can write this socket
					local r, s = socket.select(nil, { v })
					
					if s and s[1] == v then
						break
					end
				end
			
				v:send(tostring(trigger) .. "\n")
			end
		end
	end
end

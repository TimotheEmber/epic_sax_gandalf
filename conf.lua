function love.conf(t)
	t.version = "0.9.2"
	t.identity = "EpicSaxGandalf"
	t.window.title = "Epic Sax Gandalf"
	
	-- Disable un-needed modules
	t.modules.joystick = false
	t.modules.physics = false
	t.modules.thread = false
end

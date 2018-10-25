-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.draw_debug = true
	
	Input.set("primary", "mouse.1")
	Input.set("secondary", "mouse.2")
	
	Draw.setBackgroundColor("white")
	BlankE.init("PlayState")
end
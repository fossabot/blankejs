-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.init("PlayState",{
		filter="nearest",
		resolution=4
	})
	
	BlankE.draw_debug = true
end
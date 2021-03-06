--engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="JoystickState",
		plugins={"Pathfinder","Platformer"},
		resolution=2,
		filter="nearest",
		debug={
			log=true
		},
		inputs={
			{"lclick","mouse.1"},
			{"rclick","mouse.2"},
			{"move_l","left","a"},
			{"move_r","right","d"},
			{"move_u","up","w","pad.2"},
			{"move_d","down","s"},
			{"action","space"}
		}
	}
	Draw.setBackgroundColor("white")
end

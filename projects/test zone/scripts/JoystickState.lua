BlankE.addState("JoystickState")

local sc_level1
local vw_main = View("main")
local w = 0

function JoystickState:enter()
	w = game_width
	
	Scene.tile_hitboxes = {"ground"}
	sc_level1 = Scene("Platforming")
	local ent_mario = sc_level1:addEntity("spawn",Mario,"bottom left")[1]
	View("main"):follow(ent_mario)
end

function JoystickState:update(dt)
	if Input("action").released then
		Tween(View("main"), {zoom=2}, 2):play()
	end
end

function JoystickState:draw()
	View("main"):draw(function()
		sc_level1:draw()
	end)
end

BlankE.addState("PlayState");

local player
main_camera = nil

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("level1")
	sc_level1.draw_order = {"ground","MovingBlock","spike","Player"}
	-- hitboxes
	sc_level1:addHitbox("ground")
	sc_level1:addHitbox("player_die")
	-- entities
	player = sc_level1:addEntity("player", Player, "bottom-center")[1]
	sc_level1:addEntity("moving_block", MovingBlock)
	
	main_camera = View()
	main_camera.zoom = 2
	main_camera:follow(player)
end

function PlayState:update(dt)
	
end

function PlayState:draw()
	main_camera:draw(function()
		sc_level1:draw()
	end)
end
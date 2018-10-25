BlankE.addState("PlayState")

local everything = Group()
local player_cart

function PlayState:enter()
	placeObjects()
	Timer():every(function()
		everything:sort("y")
	end, 1):start()
end

function placeObjects()
	player_cart = FoodCart()
	player_cart.x = game_width / 2
	player_cart.y = game_height / 2
	
	everything:forEach(function(o, obj)
		obj:destroy()	
	end)
	for n = 0, 20 do
		everything:add(Npc())
	end
	everything:add(player_cart)
end

function PlayState:draw()
	everything:call("draw")
end
BlankE.addState("MainState")

local img_mask = Image("Basic Bird")
img_mask:setScale(2)
local test_mask = Mask()
test_mask:setup("inside")
local offset = 0

local effect = Effect("crt")

local grp_elements = Group()
local ui_element_list = UI.list{
	x = 100, y = 100,
	item_width = 50,
	item_height = 50,
	max_height = game_height - 200,
	max_width = 50,
	fn_drawItem = function(i, x, y)
		local el = grp_elements:get(i)
		el.x = x
		el.y = y
		el:draw()
	end
}

local mario
local rptr

function MainState:enter()
	MainState.background_color = "white"
	mario = Mario()
	rptr = Repeater(mario,{rate=100, lifetime=1})
	
	test_mask.fn = function()
		test_mask:useImageAlphaMask(img_mask)
	end
	
	for i = 1, 30 do
		grp_elements:add(Element())
		grp_elements:get(i).index = i
	end
end

function MainState:draw()
	rptr.spawn_x = mouse_x
	rptr.spawn_y = mouse_y
	
	rptr.end_color = {randRange(0,100)/100,randRange(0,100)/100,randRange(0,100)/100,0}

	rptr:draw()
	
	img_mask.x = mouse_x
	img_mask.y = mouse_y
	
	mario:draw()
	--effect.chroma_shift.radius = lerp(0,10,mouse_x/game_width)
	effect:draw(function()
		img_mask:draw()
	end)
	
	-- dt_mod = (mouse_x / game_width) * 5

	Draw.translate(game_width/2, game_height/2)
	Draw.setColor("blue")
	Draw.grid(3, 3, 50, 50, function(x, y, row, column)
		Draw.circle("line", x, y, 3)
		Draw.text("("..row..", "..column..")", x, y)
	end)
	--[[ 
	test_mask:draw(function()
		Draw.setColor("white")
		Draw.rect("fill", 0, 0, game_width, game_height)
	end)
	
	img_mask.x = game_width / 2 --sinusoidal(game_width / 4, game_width - (game_width / 4), 0.5)
	
	ui_element_list:setSize(grp_elements:size())
	--ui_element_list:draw()
	]]
end
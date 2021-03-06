BlankE.addEntity("Mario");

function Mario:init()
	self:addSprite{name="luigi_walk", image="sprite-example", frames={"1-3",1}, frame_size={27,49}, speed=0.01, offset={9,54}, border=2}

	self.real_mario = Image("sprite-example")
	self.real_mario.xoffset = self.real_mario.width / 2
	self.real_mario.yoffset = self.real_mario.height / 2
	self.real_mario.x = game_width /2
	self.real_mario.y = game_height /2
	
	self.effect = Effect("chroma shift")
	--self.effect = Effect("static")
	self.direction = 0
	self.can_jump = true
	
	self:addPlatforming()
	self.gravity_direction = 90
	self.gravity = 10
	
	Input("move_u").can_repeat = false
end

function Mario:update(dt)	
	local s = 200
	local hx = 0
	if Input("move_l").pressed or Input.getAxis(1) < -0.2 then hx = hx - s end
	if Input("move_r").pressed or Input.getAxis(1) > 0.2 then hx = hx + s end
	
	local ax = Input.getAxis(1)
	if math.abs(ax) > 0.05 then
		hx = hx + (s * ax)
	end
	
	if Input("move_u").released then self.can_jump = true end
	if Input("move_u").pressed and self.can_jump then 
		self.vspeed = -500
		self.can_jump = false
	end
	self.hspeed = hx
	
	self:platformerCollide{tag="ground"}
end

function Mario:draw()
	self:drawSprite()
	--self:debugCollision()
	--[[
	self.effect:draw(function()
		Draw.setColor("black")
		Draw.rect("fill",0,0,game_width/2,game_height)
		Draw.reset("color")
			
		self.real_mario:draw()
	end)]]
end
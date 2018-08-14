Repeater = Class{
	init = function(self, texture, options)
		self.real_texture = nil

		if texture.classname then
			if texture.classname == "Image" then self.real_texture = texture.image end
			if texture.classname == "Canvas" then self.real_texture = texture.canvas end
		end

		assert(self.real_texture, "not a valid Repeater texture");

		self.system = love.graphics.newParticleSystem(self.real_texture)

		self.x = 0
		self.y = 0
		self.duration = -1
		self.lifetime = 5 -- needs max
		self.rate = 1
		self.linear_accel_x = 0 -- needs max
		self.linear_accel_y = 0
		self.linear_damp_x = 0
		self.linear_damp_y = 0
		-- self.speed = 0 -- needs max
		self.color = {1,1,1,1}
		self.end_color = {1,1,1,1}

		table.update(self, options)

		_addGameObject('repeater', self)
	end,

	update = function(self, dt)
		self.system:update(dt)
	end,

	setSpeed = function(self, min, max)
		self.system:setSpeed(min, max)
	end,

	draw = function(self)
		self.system:setParticleLifetime(self.lifetime)
		self.system:setEmitterLifetime(self.duration)
		self.system:setEmissionRate(self.rate)
		self.system:setLinearAcceleration(self.linear_accel_x, self.linear_accel_y)
		self.system:setLinearDamping(self.linear_damp_x, self.linear_damp_y)
		
		local c1 = Draw._parseColorArgs(self.color)
		local c2 = Draw._parseColorArgs(self.end_color)
		self.system:setColors(c1[1], c1[2], c1[3], c1[4], c2[1], c2[2], c2[3], c2[4])

		love.graphics.draw(self.system, self.x, self.y)
	end
}

return Repeater
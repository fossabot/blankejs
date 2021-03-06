-- TODO: add ability to change shape size

Hitbox = Class{
	_color = {},
	polygonCheck = true,

	init = function(self, shape, args, tag)
		self.xoffset = 0
		self.yoffset = 0

		self.HCShape = nil
		--[[
		if Hitbox.polygonCheck and shape == "polygon" then
			-- check if polygon is just a point
			if #args == 2 then
				shape = "point"
			end

			-- check if a polygon is a rectangle instead
			if #args == 8 then
				local x_diffs = {}
				local y_diffs = {}
				print('checking')
				for a = 1, #args, 2 do
					local x = args[a]
					local y = args[a+1]
					print(x,y)
				end
			end
		end]]

		if shape == "rectangle" then
			self.HCShape = HC.rectangle(unpack(args))
		elseif shape == "polygon" then
			self.HCShape = HC.polygon(unpack(args))
		elseif shape == "circle" then
			self.HCShape = HC.circle(unpack(args))
		elseif shape == "point" then
			self.HCShape = HC.point(unpack(args))
		end

		self.HCShape.xoffset = 0--xoffset
		self.HCShape.yoffset = 0--yoffset
		if shape ~= "polygon" then
			self.HCShape.xoffset = (args[1]) / 2
			self.HCShape.yoffset = (args[2]) / 2
		end

		self.HCShape.tag = tag
		self.HCShape.box = {self.HCShape:bbox()}
		self.HCShape.x = self.HCShape.box[1]
		self.HCShape.y = self.HCShape.box[2]
		self.HCShape.width = self.HCShape.box[3]-self.HCShape.box[1]
		self.HCShape.height = self.HCShape.box[4]-self.HCShape.box[2]

		self._enabled = true
		self.color = {255,0,0,255/3}
		self.parent = nil
		self.args = args
		self.auto_update = false

		self.center_x = 0
		self.center_y = 0

		self.onPropSet["angle"] = function(self,v) if self._enabled then self.HCShape:setRotation(math.rad(v), self.center_x, self.center_y) end end
		self.onPropGet["angle"] = function(self) return 0 end

		_addGameObject('hitbox', self)
	end,

	draw = function(self, mode)
		if self._enabled then
			local color = Draw._parseColorArgs(ifndef(Hitbox._color[self.HCShape.tag], self.color))
			color[4] = .3
			local limit = 200 / 255
			if color[1] >= limit and color[2] >= limit and color[3] >= limit then
				color[1] = limit
				color[2] = limit
				color[3] = limit
			end

			local x, y = self:center()

            Draw.stack(function()
                Draw.setLineWidth(1)
                Draw.setColor(color)
                self.HCShape:draw(ifndef(mode, 'fill'))
			end)
		end
	end,

	setTag = function(self, new_tag)
		self.HCShape.tag = new_tag
	end,

	getTag = function(self)
		return self.HCShape.tag
	end,

	getHCShape = function(self)
		return self.HCShape
	end,

	move = function(self, x, y)
		if self._enabled then
			self.HCShape:move(x, y)
		end
	end,

	moveTo = function(self, x, y)
		if self._enabled then
			self.HCShape:moveTo(x+self.HCShape.xoffset, y+self.HCShape.yoffset)
		end
	end,

	center = function(self)
		x, y = self.HCShape:center()
		return x-self.HCShape.xoffset, y-self.HCShape.yoffset
	end,	

	pointTest = function(self, x, y)
		return self.HCShape:contains(x,y)
	end,

	enable = function(self)
		if not self._enabled then
			self._enabled = true
			HC.register(self.HCShape)
		end
	end,

	disable = function(self)
		if self._enabled then
			self._enabled = false
			HC.remove(self.HCShape)
		end
	end,

	destroy = function(self)
		self:disable()
		_destroyGameObject('hitbox',self)
    	self = nil
	end,

	setColor = function(self, new_color)
		self.color = Draw._parseColorArgs(new_color)
		self.color[4] = 255/2.5
	end,

	setParent = function(self, parent)
		self.parent = parent
		self.HCShape.parent = parent
	end
}

return Hitbox
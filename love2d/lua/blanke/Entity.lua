local cos = math.cos
local sin = math.sin
local rad = math.rad
local floor = function(v) return math.floor(v+0.5) end
local entity_spash = {}

Entity = Class{
	x = 0,
	y = 0,
	net_sync_vars = {'x', 'y', 'hspeed', 'vspeed', 'gravity', 'friction', 'persistent'},
	net_excludes = {'^_images$','^_sprites$','^sprite$','previous$','start$','^shapes$','^collision','^onCollision$','^is_net_entity$'},
    _init = function(self, parent) 
    	self._entity = true   
    	self.classname = ifndef(self.classname, 'entity')

    	if not entity_spash[self.classname] then
    		entity_spash[self.classname] = SpatialHash(math.min(game_width, game_height)/2)
    	end

    	self._destroyed = false
		self.draw_debug = false
		self.scene_show_debug = false

		-- x and y coordinate of sprite
		self.x = ifndef(self.x, Entity.x)
		self.y = ifndef(self.y, Entity.y)
		self.parent = parent

		Entity.x = 0
		Entity.y = 0

		self.sprite_obj = {}
		self.sprite = {}
		self.sprite_width = 0
		self.sprite_height = 0

		-- movement variables
		self.friction = 0
		self.gravity = 0
		self.gravity_direction = 90
		self.hspeed = 0
		self.vspeed = 0
		self.xprevious = 0
		self.yprevious = 0
		self.xstart = self.x
		self.ystart = self.y

		-- collision
		self.shapes = {}
		self._main_shape = nil
		self.collisions = {}
		self.collisionStop = nil
		self.collisionStopX = nil
		self.collisionStopY = nil	

		self.onCollision = {["*"] = function() end}

		self.onPropGet["direction"] = function() Debug.log(self.hspeed, self.vspeed); return direction(0,0,self.hspeed,self.vspeed) end
		self.onPropGet["speed"] = function() return distance(0,0,self.hspeed,self.vspeed) end

		self.onPropSet["sprite_index"] = function(self,v) self:refreshSpriteDims(v) end
		self.onPropSet["sprite_color"] = function(self,v) return Draw._parseColorArgs(v) end
		self.onPropSet["angle"] = function(self,v) self:rotateTo(v) end
		self.onPropGet["angle"] = function() return 0 end

    	_addGameObject('entity', self)
    end,

    _post_init = function(self)
		if not self.sprite_index then
			self.sprite_index = table.keys(self._sprites)[1]
		end
		-- entity_spash[self.classname]:register(self, self.x, self.y, self.x, self.y)
    end,

    __eq = function(self, other)
    	return (self.uuid == other.uuid)
    end,

    destroy = function(self)
    	-- destroy hitboxes
    	for s, shape in pairs(self.shapes) do
    		shape:destroy()
    	end
    	if self.netSync then self:netSync('destroy') end

    	-- entity_spash[self.classname]:remove(self)
    	_destroyGameObject('entity', self)
    end,

    onNetAdd = function(self)
    	self:netSync("x","y")
    end,

    _update = function(self, dt)
    	if self._destroyed then return end

    	-- subtract friction
    	if self.hspeed ~= 0 then 
    		self.hspeed = (self.hspeed - (self.hspeed * self.friction))
    		if self.friction > 0 and self.gravity == 0 and math.abs(self.hspeed) <= 1 then
    			self.hspeed = 0
    		end
    	end
    	if self.vspeed ~= 0 then 
    		self.vspeed = (self.vspeed - (self.vspeed * self.friction))
    		if self.friction > 0 and self.gravity == 0 and math.abs(self.vspeed) <= 1 then
    			self.vspeed = 0
    		end
    	end

    	if self.update then
			self:update(dt)
		end

    	if self._destroyed then return end -- call again in case entity is destroyed during update

		-- x/y extra coordinates
		if self.xstart == 0 then
			self.xstart = self.x
		end
		if self.ystart == 0 then
			self.ystart = self.y
		end

		-- check for collisions
		local dx, dy = self.hspeed, self.vspeed
		if not self.pause then
			-- calculate gravity/gravity_direction
			local gravx, gravy = 0,0
			if self.gravity ~= 0 then
				gravx = math.floor(self.gravity * cos(rad(self.gravity_direction)))
				gravy = math.floor(self.gravity * sin(rad(self.gravity_direction)))
			end

			-- add gravity to hspeed/vspeed
			if gravx ~= 0 then dx = dx + gravx end
			if gravy ~= 0 then dy = dy + gravy end

			-- move shapes if the x/y is different
			if self.xprevious ~= self.x or self.yprevious ~= self.y then
				for s, shape in pairs(self.shapes) do
					-- account for x/y offset?
					shape:moveTo(self.x or 0, self.y or 0)
				end
			end
        
			self.xprevious = self.x
			self.yprevious = self.y

			-- move all shapes
			for s, shape in pairs(self.shapes) do
				shape:move(dx*dt, dy*dt)
			end

			local _main_shape = self.shapes[self._main_shape]
			
			self.collisions = {}
			self.precoll_hspeed = self.hspeed
			self.precoll_vspeed = self.vspeed
			for name, fn in pairs(self.onCollision) do
				-- make sure it actually exists
				if self.shapes[name] ~= nil and self.shapes[name]._enabled then
					local obj_shape = self.shapes[name]:getHCShape()

					local collisions = HC.neighbors(obj_shape)
					for other in pairs(collisions) do
					    local collides, cx, cy = obj_shape:collidesWith(other)
					    if collides and not other.tag:contains(self.classname) then
		                	local sep_vec = {x=cx, y=cy, point_x=0, point_y=0}

		                	-- calculate location of collision
		                	local bx, by, bw, bh = unpack(obj_shape.box)
		                	bw = bw - bx
		                	bh = bh - by
		                	if cx < 0 then sep_vec.point_y = by; sep_vec.point_x = (bw + cx) end
		                	if cx > 0 then sep_vec.point_y = by; sep_vec.point_x = cx end
		                	if cy < 0 then sep_vec.point_x = bx; sep_vec.point_y = (bh + cy) end
		                	if cy > 0 then sep_vec.point_x = bx; sep_vec.point_y = cy end

		                	local ox, oy = obj_shape:center()
		                	sep_vec.point_x, sep_vec.point_y = sep_vec.point_x + ox, sep_vec.point_y + oy

		                	self.collisions[name] = ifndef(self.collisions[name], {})
					    	self.collisions[name][other.tag] = sep_vec

							-- collision action functions
							self.collisionStopX = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(cx*1.1, 0)
								end
					            dx = 0
							end

							self.collisionStopY = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(0, cy*1.1)
								end
					            dy = 0
							end
							
							self.collisionStop = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(cx*1.1, cy*1.1)
								end
								dx, dy = 0, 0
							end

							self.collisionBounce = function(self, multiplier)
								for name, shape in pairs(self.shapes) do
									shape:move(cx*2, cy*2)
								end
								local mag = math.sqrt((cx^2)+(cy^2))
								local dot = (self.hspeed * (cx/mag)) + (self.vspeed * (cy/mag)) * (multiplier or 1)
								dx = self.hspeed - (2 * dot * (cx/mag))
								dy = self.vspeed - (2 * dot * (cy/mag))
							end

							-- call users collision callback if it exists
							fn(other, sep_vec)
						end
					end
				end
			end

			-- set position of sprite
			if _main_shape and _main_shape._enabled then
				self.x, self.y = _main_shape:center()
			else
				self.x = self.x + dx*dt
				self.y = self.y + dy*dt
			end
			self.xprevious = self.x
			self.yprevious = self.y

			--local old_hspd, old_vspd = self.hspeed, self.vspeed
			if self.hspeed == self.precoll_hspeed then self.hspeed = dx end
			if self.vspeed == self.precoll_vspeed then self.vspeed = dy end
			if self.postUpdate then self:postUpdate(dt) end
			--self.hspeed, self.vspeed = old_hspd, old_vspd
		end

		if self.netSync then self:netSync() end
--[[
		entity_spash[self.classname]:update(self,
			self.xprevious, self.yprevious, self.xprevious, self.yprevious,
			self.x, self.y, self.y, self.y
		)
		]]
		return self
	end,

	hadCollision = function(self, self_name, other_name)
		if not self.collisions[self_name] then return false end
		for name, sep_vec in pairs(self.collisions[self_name]) do
			if name:contains(other_name) then return true end
		end
	end,

	getCollisions = function(self, shape_name)
		if self.shapes[shape_name] then
			local hc_shape = self.shapes[shape_name]:getHCShape()
			return HC.collisions(self.shapes[shape_name])
		end
		return {}
	end,

	debugSprite = function(self)
		if self.sprites[self.sprite_index] then
			self.sprites[self.sprite_index]:debug()
		end 
	end,

	debugCollision = function(self)
		-- draw collision shapes
		for s, shape in pairs(self.shapes) do
			shape:draw("line")
		end
		return self
	end,

	drawDebug = function(self)
		self:debugSprite()
		self:debugCollision()
	end,

	getSpriteInfo = function(self, sprite_index)
		if not self.sprite[sprite_index] then return end

		local vars = {'angle','xscale','yscale','xoffset','yoffset','xshear','yshear','color','alpha','speed'}
		local info = {}
		for i, k in ipairs(vars) do 
			-- get prop from Sprite object
			info[k] = self.sprite_obj[sprite_index][k]
			
			-- check if it is overriden for just this Sprite
			if self.sprite[sprite_index][k] ~= nil then
				info[k] = self.sprite[sprite_index][k]
			end 

			-- check for overall override
			if self['sprite_'..k] ~= nil then 
				if k == 'xoffset' or k == 'yoffset' then 
					info[k] = info[k] + self['sprite_'..k]
				else
					info[k] = self['sprite_'..k]
				end 
			end
		end

		return info
	end,

	drawSprite = function(self, sprite_index)
		if not sprite_index then
			if self.sprite_index then
				self:drawSprite(self.sprite_index)
			else
				self.sprite_width = 0
				self.sprite_height = 0
				-- just draw them all
				for name, spr in pairs(self._sprites) do
					self:drawSprite(name)
				end 
			end
		end

		local sprite = self.sprite_obj[sprite_index]
		local info = self:getSpriteInfo(sprite_index)

		if info and sprite then
			local sep_frame = false
			if self.sprite[sprite_index].frame ~= nil then
				sep_frame = true
			end

			if info.speed == 0 then
				if sep_frame then
					sprite:gotoFrame(info.frame)
				else
					sprite:gotoFrame(self.sprite_frame)
				end
			end

			if not sep_frame then
				self.sprite_frame = sprite.position -- TODO: what about sprites with different amount of frames. does it even matter?
			end

			-- draw current sprite (image, x,y, angle, sx, sy, ox, oy, kx, ky) s=scale, o=origin, k=shear
			local img = self._images[sprite_index]
			Draw.stack(function()
				Draw.setColor(info.color[1], info.color[2], info.color[3], ifndef(info.color[4], info.alpha))
				--love.graphics.setColor(info.color[1], info.color[2], info.color[3], ifndef(info.color[4], info.alpha))
				
				-- is it an Animation or an Image
				if img then
					local draw_x, draw_y = floor(self.x), floor(self.y)
					if sprite.update ~= nil then
						sprite:draw(img(), draw_x, draw_y, math.rad(info.angle), info.xscale, info.yscale, -math.floor(info.xoffset), -math.floor(info.yoffset), info.xshear, info.yshear)
					else
						love.graphics.draw(img(), draw_x, draw_y, math.rad(info.angle), info.xscale, info.yscale, -math.floor(info.xoffset), -math.floor(info.yoffset), info.xshear, info.yshear)
					end
				end

				if self.draw_debug or self.scene_show_debug then self:debugSprite(sprite_index) end
			end)
		end
	end,

	draw = function(self)
		if self._destroyed then return end

		if self.preDraw then
			self:preDraw()
		end

		self:drawSprite()
		if self.show_debug then self:debugCollision() end

		if self.postDraw then
			self:postDraw()
		end
		return self
	end,

	animationMatch = function(self, src, dest)
		for key, val in pairs(self.sprite[src]) do
			self.sprite[dest][key] = val
		end
	end,

	addAnimation = function(self, args)
		-- main args
		local ani_name = args.name
		local name = args.image
		local frames = ifndef(args.frames, {1,1})
		-- other args
		local offset = ifndef(args.offset, {0,0})
		local left = offset[1]
		local top = offset[2]
		local border = ifndef(args.border, 0)
		local speed = ifndef(args.speed, 0.1)

		if Image.exists(name) then
			local image = Image(name)
			local frame_size = ifndef(args.frame_size, {image.width, image.height})
		    local grid = anim8.newGrid(frame_size[1], frame_size[2], image.width, image.height, left, top, border)
			local sprite = anim8.newAnimation(grid(unpack(frames)), speed)

			self._images[ani_name] = image
			self._sprites[ani_name] = sprite

			self:refreshSpriteDims(ani_name)
			self.sprite[ani_name] = {width=self.sprite_width, height=self.sprite_height}
		end
		return self
	end,

	refreshSpriteDims = function(self, name)
		if self._sprites[name] then
			local anim_w, anim_h = self._sprites[name]:getDimensions()
			self.sprite_width, self.sprite_height = ifndef(anim_w, 0), ifndef(anim_h, 0)
		end
	end,

	-- add a collision shape
	-- str shape: rectangle, polygon, circle, point
	-- str name: reference name of shape
	addShape = function(self, name, shape, args, tag)
		tag = ifndef(tag, self.classname..'.'..name)
		local new_hitbox = Hitbox(shape, args, tag, 0, 0)
		new_hitbox:setParent(self)
		new_hitbox:moveTo(self.x, self.y)
		self.shapes[name] = new_hitbox

		if not self._main_shape then
			self:setMainShape(name)
		end
		return self
	end,

	-- remove a collision shape
	removeShape = function(self, name)
		if self.shapes[name] ~= nil then
			self.shapes[name]:disable()
			self.shapes[name] = nil
		end
		return self
	end,

	-- the shape that the sprite will follow
	setMainShape = function(self, name) 
		if self.shapes[name] ~= nil then
			self._main_shape = name
		end 
		return self
	end,

	distancePoint = function(self, x, y)
		return math.sqrt((x - self.x)^2 + (y - self.y)^2)
	end,

	-- other : Entity object
	-- returns distance between center of self and other object in pixels
	distance = function(self, other)
		return self:distancePoint(other.x, other.y)
	end,

	rotateTo = function(self, angle)
		for s, shape in pairs(self.shapes) do
			shape.center_x = self.x
			shape.center_y = self.y
			shape.angle = angle
		end
	end, 

	-- self direction and speed will be set towards the given point
	-- this method will not set the speed back to 0 
	moveTowardsPoint = function(self, x, y, speed)
		self:moveDirection(math.deg(math.atan2(y - self.y, x - self.x)), speed)
		return self
	end,

	moveDirection = function(self, angle, speed)
		self.hspeed = cos(rad(angle)) * speed
		self.vspeed = sin(rad(angle)) * speed
		return self
	end,
    
    -- checks if the point is inside the current sprite
    containsPoint = function(self, x, y)
    	for name, sprite in pairs(self.sprite) do
	        if x >= self.x and y >= self.y and x < self.x + sprite.width and  y < self.y + sprite.height then
    	        return true
        	end
        end
        return false
    end--[[,

    getNearby = function(self, classname)
    	if entity_spash[classname] then
    		return entity_spash[classname]:cell(entity_spash[classname]:cellCoords(self.x, self.y))
    	else
    		return {}
    	end
    end]]
}

Entity.getNearby = function(classname, x, y)
    	if entity_spash[classname] then
    		return entity_spash[classname]:cellAt(x, y)
    	else
    		return {}
    	end
end

Entity.drawHash = function(classname)
	if entity_spash[classname] then
		entity_spash[classname]:draw('line')
	end
end

Entity.getCell = function(classname, x, y)
	if entity_spash[classname] then
		return entity_spash[classname]:cellCoords(x, y)
	end
	return 0, 0
end

return Entity
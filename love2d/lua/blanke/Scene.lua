-- special type of hashtable that groups objects with similar coordinates
local Scenetable = Class{
	init = function(self, mod_val)
		self.mod_val = ifndef(mod_val, 32)
		self.data = {}
	end,
	hash = function(self, x, y)
		return tostring(x - (x % self.mod_val))..','..tostring(y - (y % self.mod_val))
	end,
	hash2 = function(self, obj)
		return tostring(obj)
	end,
	add = function(self, x, y, obj)
		local hash_value = self:hash(x, y)
		local hash_obj = self:hash2(obj)

		self.data[hash_value] = ifndef(self.data[hash_value], {})
		self.data[hash_value][hash_obj] = obj
	end,
	-- returns a table containing all objects at a coordinate
	search = function(self, x, y) 
		local hash_value = self:hash(x, y)
		return ifndef(self.data[hash_value],{})
	end,
	delete = function(self, x, y, obj)
		local hash_value = self:hash(x, y)
		local hash_obj = self:hash2(obj)

		if self.data[hash_value] ~= nil then
			if self.data[hash_value][hash_obj] ~= nil then
				local obj = table.copy(self.data[hash_value][hash_obj])
				self.data[hash_value][hash_obj] = nil
				return obj
			end
		end
	end,
	exportList = function(self, key, val)
		local ret_list = {}
		for key1, tile_group in pairs(self.data) do
			for key2, tile in pairs(tile_group) do
				if not key or (key and tile[key] == val) then
					table.insert(ret_list, tile)
				end
			end
		end
		return ret_list
	end,
}

local SceneLayer = Class{
	init = function(self)
		self.parent = nil
		self.images = {}
		self.hashtable = Scenetable()
		self.spritebatches = {}
		self.hitboxes = {}
		self.entities = {}
		self.obj_name_list = {} -- contains list of all tile and entity names
		
		self.offx = 0
		self.offy = 0
		self.angle = 0
		self.draw_hitboxes = false
	end,

	-- {image (path/name), x, y, crop {x,y,w,h}}
	addTile = function(self, info)
		local img_name = info.image

		local img_ref = self.parent.tilesets[img_name]
		if img_ref then
			self.images[img_name] = Image(img_name)

			local tile_info = info

			-- add to spritebatch
			local img = self.images[img_name]
			if not self.spritebatches[img_name] then 
				self.spritebatches[img_name] = love.graphics.newSpriteBatch(img())
			end
			local sb = self.spritebatches[img_name]
			local quad = love.graphics.newQuad(info.crop.x, info.crop.y, info.crop.w, info.crop.h, img.width, img.height)
			info.id = sb:add(quad, info.x, info.y)
			
			-- add to tile hashtable
			self.hashtable:add(info.x, info.y, info)

			self.obj_name_list[img_name] = true
		end
	end,

	addHitbox = function(self, points, tag, color)
		self.hitboxes[tag] = ifndef(self.hitboxes[tag], {})
		local new_hitbox = Hitbox("polygon", points, tag)
		new_hitbox:move(self.offx, self.offy)
		if color then new_hitbox:setColor(color) end
		table.insert(self.hitboxes[tag], new_hitbox)
	end,

	addEntity = function(self, instance)
		if not self.entities[instance.classname] then 
			self.entities[instance.classname] = Group()
		end
		self.entities[instance.classname]:add(instance)

		self.obj_name_list[instance.classname] = true
	end,

	getTiles = function(self, name)
		if name then
			return self.hashtable:exportList('image', name)
		end
		return self.hashtable:exportList()
	end,

	translate = function(self, x, y)
		x, y = ifndef(x,0), ifndef(y,0)
		self.offx = self.offx + x
		self.offy = self.offy + y
		for name, hitboxes in pairs(self.hitboxes) do
			for h, hitbox in ipairs(hitboxes) do
				hitbox:move(x, y)
			end
		end
		for name, entities in pairs(self.entities) do
			entities:forEach(function(ent)
				ent.x = ent.x + x
				ent.y = ent.y + y
			end)
		end
	end,

	setRotation = function(self, a)
		self.angle = a
		-- rotate hitboxes
		for name, hitboxes in pairs(self.hitboxes) do
			for h, hitbox in ipairs(hitboxes) do
				hitbox.center_x = self.parent.center_x + self.offx
				hitbox.center_y = self.parent.center_y + self.offy
				hitbox.angle = a
			end
		end
	end,

	_drawObj = function(self, name)
		Draw.stack(function()
			Draw.translate(self.offx, self.offy)
			Draw.translate(self.parent.center_x, self.parent.center_y)
			Draw.rotate(self.angle)
			Draw.translate(-self.parent.center_x, -self.parent.center_y)

			-- tile
			if self.spritebatches[name] then
				love.graphics.draw(self.spritebatches[name])
			end
		end)

		-- entity
		if self.entities[name] then
			self.entities[name]:forEach(function(entity,e)
				if not table.hasValue(Scene.dont_draw, entity.scene_name) and
				   not table.hasValue(self.parent.dont_draw, entity.scene_name) then
					Draw.stack(function()
						entity:draw()
					end)
				end
			end)
		end
	end,

	draw = function(self, draw_order)
		local drawn = {}

		-- draw specified objects
		if draw_order then
			for _, name in ipairs(draw_order) do
				drawn[name] = true
				self:_drawObj(name)
			end
		end

		-- draw everything else
		for name, _ in pairs(self.obj_name_list) do
			if not drawn[name] then
				self:_drawObj(name)
			end
		end

		if self.draw_hitboxes then
			local specific = false
			local draw_string = ''
			if type(self.draw_hitboxes) == "table" then
				specific = true
				draw_string = table.join(self.draw_hitboxes)
			end

			for name, hitboxes in pairs(self.hitboxes) do
				if not specific or (specific and draw_string:contains(name)) then 
					for h, hitbox in ipairs(hitboxes) do
						hitbox:draw('fill')
					end
				end
			end
		end
	end
}

local Scene = Class{
	
	-- things that automatically load on Scene creation
	tile_hitboxes = {},
	hitboxes = {},
	entities = {},

	dont_draw = {},
	draw_order = {}, -- overridden by instance draw_order

	draw_outside_view = {}, -- TODO

	init = function(self, asset_name)
		self.layers = {}
		self.tilesets = {}
		self.objects = {}
		self.obj_coord_list = {}	-- loaded from .scene file
		self.entities = {}			-- instances that are added through addEntity and don't belong to a layer
		self.obj_uuid_ref = {}		-- loaded from .scene file
		self.dont_draw = {}
		self.draw_order = nil
		self.offset_x = 0
		self.offset_y = 0

		self.center_x = 0
		self.center_y = 0

		self.left = nil
		self.top = nil
		self.right = nil
		self.bottom = nil
		self.width = 0
		self.height = 0
        
		if asset_name then
			local scene = Asset.scene(asset_name)
			assert(scene, 'Scene not found: \"'..tostring(asset_name)..'\"')
			self:load(scene)
		end
		self.name = asset_name

		self.onPropSet["angle"] = function(self, v)
			-- call on layers
			for l, layer in ipairs(self.layers) do
				layer:setRotation(v)
			end
		end
		self.onPropGet["angle"] = function() return 0 end

		_addGameObject('scene', self)
	end,

	_addAnything = function(self, x, y, w, h)
		if self.left == nil or x < self.left then self.left = x end
		if self.top == nil or y < self.top then self.top = y end
		if self.right == nil or x + w > self.right then self.right = x + w end
		if self.bottom == nil or y + h > self.bottom then self.bottom = y + h end

		self.width = self.right - self.left
		self.height = self.bottom - self.top
	end,

	getLayer = function(self, name)
		for l, layer in ipairs(self.layers) do
			if layer.name == name then return layer end
		end
	end,

	getLayerByUUID = function(self, uuid)
		for l, layer in ipairs(self.layers) do
			if layer.uuid == uuid then return layer end
		end
	end,

	sortLayers = function(self)
		table.sort(self.layers, function(a, b) return a.depth < b.depth end)
		return self
	end,

	load = function(self, scene_data)
		-- layers
		for l, layer in ipairs(scene_data.layers) do
			local new_layer = SceneLayer()
			new_layer.parent = self

			local attributes = {'name', 'depth', 'offset', 'snap', 'uuid'}
			for a, attr in ipairs(attributes) do new_layer[attr] = layer[attr] end

			table.insert(self.layers, new_layer)
		end
		self:sortLayers()
		
		-- tilesets (images)
		for i, image in ipairs(scene_data.images) do
			local img_obj = Image(image.path)
			local img_name = Asset.getNameFromPath('image', image.path)

			self.tilesets[img_name] = {
				image = Image(img_name),
				snap = image.snap,
				offset = image.offset,
				spacing = image.spacing,
				coords = image.coords
			}
			
			-- add placed tile data
			for layer_name, coords in pairs(image.coords) do
				for c, coord in ipairs(coords) do
					self:addTile(layer_name, {
						x=coord[1], y=coord[2],
						crop={x=coord[3], y=coord[4], w=coord[5], h=coord[6]},
						image=img_name
					})
				end
			end
		end
		-- objects (just store their coordinates)
		self.objects = scene_data.objects
		for uuid, objs in pairs(scene_data.objects) do
			local obj_name = BlankE.settings.scene.objects[uuid].name
			self.obj_uuid_ref[obj_name] = uuid

			-- get object coord list in case user needs to get objects
			self.obj_coord_list[obj_name] = {}
			local objects = self.objects[uuid]
			for l_uuid, obj_list in pairs(objects) do
				local layer_name = self:getLayerByUUID(l_uuid).name
				self.obj_coord_list[obj_name][layer_name] = {}
				for o_uuid, coord in ipairs(obj_list) do
					table.insert(self.obj_coord_list[obj_name][layer_name], {
						 tag = coord[1], x = coord[2], y = coord[3]
					})
				end
			end
		end

		-- hitboxes, tilehitboxes, and entities
		self:addTileHitbox(unpack(Scene.tile_hitboxes)) -- BROKEN
		self:addHitbox(unpack(Scene.hitboxes)) -- BROKEN
		for e, ent in ipairs(Scene.entities) do
			self:addEntity(ent[1], ent[2], ent[3])
		end

		return self
	end,

	draw = function(self, layer_name)
		for l, layer in ipairs(self.layers) do
			if layer_name == nil or layer.name == layer_name then 
				layer.draw_hitboxes = self.draw_hitboxes
				layer:draw(ifndef(self.draw_order, Scene.draw_order))
			end
		end
	end,

	translate = function(self, x, y)
		self.offset_x = self.offset_x + x
		self.offset_y = self.offset_y + y

		-- call on layers
		for l, layer in ipairs(self.layers) do
			layer:translate(x, y)
		end

		-- call on instances that were added manually
		for name, entities in pairs(self.entities) do
			entities:forEach(function(ent)
				ent.x = ent.x + x
				ent.y = ent.y + y
			end)
		end

		for name, layers in pairs(self.obj_coord_list) do
			for o, coord in ipairs(layers) do
				coord.x = coord.x + x
				coord.y = coord.y + y
			end
		end

		self.left = self.left + x
		self.top = self.top + y
		self.right = self.left + self.width
		self.bottom = self.top + self.height

		return self
	end,

	-- returns name, tag
	_splitNameTag = function(self, obj_name)
		return unpack(obj_name:split("."))
	end,

	_list_cache = {},
	getObjects = function(self, obj_name, with_uuid)
		local name, tag = self:_splitNameTag(obj_name)
		local obj_uuid = self.obj_uuid_ref[name]

		if obj_uuid ~= nil then
			if with_uuid then
				return self.objects[obj_uuid]
			else
				-- if there is a tag, only return objects with the included tag
				if tag then
					if not self._list_cache[obj_name] then
						local ret_list = {}
						for l_name, layers in pairs(self.obj_coord_list[name]) do
							ret_list[l_name] = {}
							for o, coord in ipairs(layers) do
								if coord.tag == tag then
									table.insert(ret_list[l_name], coord)
								end
							end
						end
						self._list_cache[obj_name] = ret_list
					end
					
					return self._list_cache[obj_name]
				else
					return self.obj_coord_list[name]
				end
			end
		end
		return {}
	end,

	-- static
	getObjectNames = function()
		local names = {}
		if BlankE.settings.scene then
			for uuid, info in pairs(BlankE.settings.scene.objects) do
				table.insert(names, info.name)
			end
		end	
		return names
	end,

	getObjectInfo = function(self, name)
		assert(BlankE.settings.scene.objects, "no Scene object with name'"..name.."'")	 
		for uuid, info in pairs(BlankE.settings.scene.objects) do
			if info.name == name then
				return info
			end
		end
		error("no Scene object with name'"..name.."'")
	end,

	getObjectByUUID = function(self, uuid)
		assert(BlankE.settings.scene.objects, "no Scene object with name'"..name.."'")	 
		return BlankE.settings.scene.objects[uuid]
	end,

	-- info = {x, y, rect{}, image}
	addTile = function(self, layer_name, info)
		local layer = self:getLayer(layer_name)
		layer:addTile(info)

		self:_addAnything(info.x, info.y, info.crop.w, info.crop.h)

		return self
	end,

	-- {{x, y, image (img_name), crop{x, y, w, h} }}
	getTiles = function(self, layer_name, img_name)
		local layer = self:getLayer(layer_name)
		assert(layer, "no such layer \""..ifndef(layer_name,'').."\" in "..self.name)
		return layer:getTiles(img_name)
	end,

	addHitbox = function(self, ...)
		local obj_names = {...}

		for n, name in ipairs(obj_names) do
			local object_uuid = self.obj_uuid_ref[name]
			if object_uuid then

				local object = self:getObjectInfo(name)
				for layer_uuid, polygons in pairs(self.objects[object_uuid]) do
					local layer = self:getLayerByUUID(layer_uuid)
					for p, polygon in ipairs(polygons) do
						local points = table.copy(polygon)

						local tag = table.remove(points, 1)
						if tag ~= name and tag ~= "" then
							tag = name..'.'..tag
						else
							tag = name
						end

						if #points == 2 then
							local x, y = points[1], points[2]
							local snapx, snapy = layer.snap[1]/2, layer.snap[2]/2
							points = {
								x - snapx, y - snapy,
								x + snapx, y - snapy,
								x + snapx, y + snapy,
								x - snapx, y + snapy
							}
						end
						layer:addHitbox(points, tag, object.color)
					end
				end

			end
		end
		return self
	end,

	addTileHitbox = function(self, ...)
		local tile_names = {...}

		for n, name in ipairs(tile_names) do
			if self.tilesets[name] then
				for layer_name, coords in pairs(self.tilesets[name].coords) do
					for c, coord in ipairs(coords) do
						local layer = self:getLayer(layer_name)
						local points = table.copy(coord)

						points = {
							points[1], 				points[2],
							points[1],				points[2]+points[6],
							points[1]+points[5], 	points[2]+points[6],
							points[1]+points[5], 	points[2],
						}

						layer:addHitbox(points, name)
					end
				end
			end
		end
	end,

	getEntities = function(self, obj_name)
		return self.entities[obj_name]
	end,	

	-- returns table of created entities
	addEntity = function(self, obj_name, ent_class, align) 
		local instances = Group()
		local name, tag = self:_splitNameTag(obj_name)
		local offx, offy = self.offset_x, self.offset_y

		local object_uuid = self.obj_uuid_ref[name]
		if object_uuid then

			local object = self:getObjectInfo(name)
			for layer_uuid, polygons in pairs(self.objects[object_uuid]) do
				
				local layer = self:getLayerByUUID(layer_uuid)
				for p, polygon in ipairs(polygons) do
					local points = table.copy(polygon)

					-- give entity information from scene
					function applyInfo(obj)	
						
						obj.scene_name = name
						obj.scene_tag = table.remove(points, 1)
						obj.scene_size = object.size
						obj.scene_rect = {0,0,0,0}

						local x, y, w, h = points[1], points[2], object.size[1], object.size[2]
						local new_polygon = {}

						if #points == 2 then
							new_polygon[1] = points[1] - (object.size[1] / 2)
							new_polygon[2] = points[2] - (object.size[2] / 2)
							new_polygon[3] = math.abs(points[1] - (points[1] + (object.size[1] / 2)))
							new_polygon[4] = math.abs(points[2] - (points[2] + (object.size[2] / 2)))
							x, y = new_polygon[1], new_polygon[2]
						else
							-- x,y is smallest, x2, y2 is largest
							local x2, y2 = x, y
							for i = 1,#points,2 do
								-- smallest
								if points[i] < x then x = points[i] end
								if points[i+1] < y then y = points[i+1] end
								-- largest
								if points[i] > x2 then x2 = points[i] end
								if points[i+1] > y2 then y2 = points[i+1] end
							end
							w = x2 - x 
							h = y2 - y
						end

						obj.x = x + offx
						obj.y = y + offy
						obj.scene_rect = {x,y,w,h}
						obj.scene_points = new_polygon
						
					end
					
					if not tag or tag == points[1] then
						local new_entity
						if ent_class.is_instance then 	-- arg is an already made entity
							new_entity = ent_class
							applyInfo(new_entity)
						else							-- arg is a class that needs to be instantiated
							ent_class._init_properties = {}
							applyInfo(ent_class._init_properties)
							new_entity = ent_class()
						end 

						if align then
							local rect = new_entity.scene_rect
							if align:contains("center") then
								new_entity.x = new_entity.x + (rect[3]/2) - (new_entity.sprite_width/2)
								new_entity.y = new_entity.y + (rect[4]/2) - (new_entity.sprite_height/2)
							end
							if align:contains("top") then
								new_entity.y = new_entity.y - new_entity.sprite_yoffset
							end
							if align:contains("bottom") then
								new_entity.y = new_entity.y + rect[4] - new_entity.sprite_height - new_entity.sprite_yoffset
							end
							if align:contains("left") then
								new_entity.x = new_entity.x - new_entity.sprite_xoffset
							end
							if align:contains("right") then
								new_entity.x = new_entity.x + rect[3] - new_entity.sprite_width - new_entity.sprite_xoffset
							end
						end

						layer:addEntity(new_entity)
						instances:add(new_entity)
						
						self:_addAnything(
							new_entity.x + new_entity.sprite_xoffset,
							new_entity.y + new_entity.sprite_yoffset,
							new_entity.sprite_width, new_entity.sprite_height
						)
					end
				
				end
			end

			self.entities[name] = instances
		end
		return instances
	end,

	-- end_name: end of previous scene
	-- start_name: start of next scene
	chain = function(self, next_scene, end_name, start_name)
		local new_start_name = start_name:split(".")[1]
		local new_end_name = end_name:split(".")[1]

		local obj_start, obj_end

		-- get end position of previous scene
		local end_list = self:getObjects(new_end_name)
		if end_list then
			obj_end = (function()
				for layer_name, coords in pairs(end_list) do
					for c, coord in ipairs(coords) do
						if new_end_name..coord.tag == end_name then
							return {coord.x, coord.y}
						end
					end
				end
				return nil
			end)()
		end

		-- get start position of next scene
		local start_list = next_scene:getObjects(new_start_name)
		if start_list then
			obj_start = (function()
				for layer_name, coords in pairs(start_list) do
					for c, coord in ipairs(coords) do
						if new_start_name..coord.tag == start_name then
							return {coord.x,coord.y}
						end
					end
				end
				return nil
			end)()
		end

		-- connect the scenes
		if obj_start and obj_end then
			next_scene:translate(obj_end[1] - obj_start[1] + self.offset_x, obj_end[2] - obj_start[2] + self.offset_y)
		end
	end,
}

return Scene
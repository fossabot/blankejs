Entity.addPlatforming = function(self, left, top, width, height)
	left = left or 0
	top = top or 0
	width = ifndef(width,self.sprite_width)
	height = ifndef(height,self.sprite_height)

	-- yes, unused at the moment
	local left2 = left + self.sprite_xoffset
	local top2 = top + self.sprite_yoffset
	-- 

	self:addShape("main_box", "rectangle", {left, top, width, height-2})		-- rectangle of whole players body
	self:addShape("head_box", "rectangle", {left, top-(height-2), width*.5, 2})
	self:addShape("feet_box", "rectangle", {left, top+(height+2), width*.5, 2})	-- rectangle at players feet

	self:setMainShape("main_box")
end

Entity.platformerCollide = function(self, args)
	local ground_tag = args.tag
	local ground_contains_tag = args.tag_contains

	local fn_wall = ifndef(args.wall, function() return true end)
	local fn_ceil = ifndef(args.ceiling, function() return true end)
	local fn_floor = ifndef(args.floor, function() return true end)
	local fn_all = ifndef(args.all, function() return true end)

	self.onCollision["main_box"] = function(other, sep_vector)	-- other: other hitbox in collision
        fn_all(other, sep_vector)
        -- horizontal collision
        if math.abs(sep_vector.x) > 0 then
            if fn_wall(other, sep_vector) ~= false and (other.tag == ground_tag or (ground_contains_tag and other.tag:contains(ground_contains_tag))) then
                self:collisionStopX() 
            end
        end

        -- head collision
        if sep_vector.y > 0 and self.vspeed < 0 and self.shapes["head_box"]:getHCShape():collidesWith(other) then
			fn_all(other, sep_vector)
            if fn_ceil(other, sep_vector) ~= false and (other.tag == ground_tag or (ground_contains_tag and other.tag:contains(ground_contains_tag))) then
           		self:collisionStopY()
            end
        end

        -- foot collision
        if sep_vector.y < 0 and self.shapes["feet_box"]:getHCShape():collidesWith(other) then
			fn_all(other, sep_vector)
        	if fn_floor(other, sep_vector) ~= false and (other.tag == ground_tag or (ground_contains_tag and other.tag:contains(ground_contains_tag))) then
        		self:collisionStopY()
        	end
        end
    end
end
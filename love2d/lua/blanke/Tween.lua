local _tweens = {}

Tween = Class{
	-- a: start value, b: change in value, d: duration of tween, dt: current time
	-- t->dt, d->d, b->a, c->b
	tween_func = {
		["linear"] = function(a, b, d, dt) return b*dt/d+a end,
		["quad in"] = function(a, b, d, dt) dt=dt/d; return b*dt*dt+a end,
		["quad out"] = function(a, b, d, dt) dt=dt/d; return -b*dt*(dt-2)+a end,
		["quad in/out"] = function(a, b, d, dt)
			dt = dt / d/2
			if (dt < 1) then return b/2*dt*dt+a end
			dt=dt-1	
			return -b/2*(dt*(dt-2)-1)+a
		end,
		["circ in"] = function(a, b, d, dt) dt=dt/d; return -b*(math.sqrt(1-(dt*dt))-1)+a end
	},

	init = function(self, var, value, duration, func_type, onFinish)
		self.duration = ifndef(duration, 1)
		self.type = ifndef(func_type, 'linear')
		self.onFinish = onFinish
		self.valid = true
		self.running = false

		self:setStartValue(var)
		self:setEndValue(value)

		self:reset()
		self._func = Tween.tween_func[self.type]

		--self.persistent = true
		_addGameObject('tween', self)
	end,

	setStartValue = function(self, val)
		self.var = val
		self._start_val = val
	end,

	setEndValue = function(self, value)
		-- get whether an object is changing or single var
		self.value = value
		self._multival = false
		self._bezier = false
		if type(value) == "table" then
			if value.type and value.type == 'bezier' then
				self._bezier = value
			else
				self._table_keys = {} -- get keys in the table that lead to another table (nested)
				function checkKeys(t_keys,t_value)
					for k,v in pairs(t_value) do
						assert(type(v)~='function', "cannot use function value in Tween")
						t_keys[k] = {type='table',children={}}
						if type(v) == "table" then
							-- go deeper into table
							checkKeys(t_keys[k].children, t_value[k])

							-- was this actually a nested table or just an array of numbers/strings
							if table.len(t_keys[k].children) == 0 then
								t_keys[k].type = "multi"
							end
						else
							t_keys[k] = nil
						end
					end
				end
				checkKeys(self._table_keys, value)
				self._multival = true
			end
		end
	end,

	addFunction = function(self, name, func)
		Tween.tween_func[name] = func
	end,

	setFunction = function(self, name)
		self.type = name
		self._func = Tween.tween_func[name]
	end,

	-- fn: returns what the property should be set to 
	-- new_val = fn(start_val, end_val, key)
	updateKeys = function(self, fn)
		if not self._multival then return end
		self:_updateKeys(self._table_keys, self.var, self._start_val, self.value, fn)
	end,

	_updateKeys = function(self, t_keys, t_var, t_start, t_end, fn) 
		for key, start_value in pairs(t_start) do
			local curr_value = t_var[key]
			local end_value = t_end[key]

			-- scalar property
			if not t_keys[key] then
				if (start_value < end_value and curr_value < end_value) or (start_value > end_value and curr_value > end_value) then
					t_var[key] = fn(start_value, end_value, key)
				end

			-- its a table, go deeper
			elseif t_keys[key].type == "table" then
				self:_updateKeys(t_keys[key].children, curr_value, start_value, end_value, fn)

			-- array property
			elseif t_keys[key].type == "multi" then
				-- array of values
				for start_k, start_v in pairs(start_value) do
					-- finished?
					local curr_v = curr_value[start_k]
					local end_v = end_value[start_k]

					if (start_v < end_v and curr_v < end_v) or (start_v > end_v and curr_v > end_v) then
						t_var[key][start_k] = fn(start_v, end_v, key)
					end
				end
			end
		end
	end,

	update = function(self, dt)
		if self._go then
			self._dt = self._dt + dt

			if self._multival then
				self:updateKeys(function(start_value, end_value)
					return self._func(start_value, end_value-start_value, self.duration*1000, self._dt*1000)
				end)

				if self._dt > self.duration then
					self:_onFinish()
				end
			elseif self._bezier then
				self._start_val = self._func(self._start_val, 100-self._start_val, self.duration*1000, self._dt*1000)
				
				if math.ceil(self._start_val) >= 100 then self._start_val = 100 end
				if self._bezier:size() > 1 then
					local x, y = self._bezier:at((100-self._start_val)/100)
					if self.var.x then self.var.x = x end
					if self.var.y then self.var.y = y end
				end
				if self._start_val >= 100 then
					self:_onFinish()
				end
			else
				self.var = self._func(self._start_val, self.value-self._start_val, self.duration*1000, self._dt*1000)

				if self._dt > self.duration then
					self:_onFinish()
				end
			end
		end
	end,

	play = function(self)
		self._go = true
		self.running = true
		return self
	end,

	stop = function(self)
		self._go = false
		self.running = false
		return self
	end,

	isRunning = function(self)
		return (self._go and self._dt > 0)
	end,

	destroy = function(self)
		_destroyGameObject('tween',self)
	end,

	reset = function(self)
		-- get starting values
		self._go = false
		self._dt = 0
		self._start_val = self.var
		self.running = false
		if self._bezier then
			self._start_val = 0
		end
		if self._multival then
			self._start_val = {}
			for key, value in pairs(self.value) do
				self._start_val[key] = self.var[key]
			end
		end
	end,

	_onFinish = function(self) 
		self:reset()
		self:updateKeys(function(s,end_val,k)
			return end_val
		end)
		if self.onFinish then self:onFinish() end
	end
}

return Tween
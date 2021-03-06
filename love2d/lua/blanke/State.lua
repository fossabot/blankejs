local transition_obj = {}

local resetTransitionObj = function()
	if transition_obj.tween then transition_obj.tween:destroy() end

	transition_obj = {
		exit_state = nil,
		enter_state = nil,
		animation = '',
		transition_fn = nil,
		tween = nil
	}
end
resetTransitionObj()

local drawStateNormal = function(state)
	if state.draw then
		Draw.stack(function()
			if state.background_color then
				State.background_color = state.background_color
					Draw.setColor(state.background_color)
					Draw.rect('fill',0,0,game_width,game_height)
			else
				State.background_color = nil
			end
			state:draw()
		end)
	end
end

StateManager = {
	_stack = {},
	in_transition = false,
	_stray_objects = {},

	iterateStateStack = function(func, ...)
		local transition_active = (transition_obj.enter_state and transition_obj.exit_state)

		-- update any stateless objects
		if func == 'update' then
			for cat, objects in pairs(StateManager._stray_objects) do
				for o, obj in ipairs(objects) do
					if obj[func] then obj[func](obj, ...) end
				end
			end
		end

		for s, state in ipairs(StateManager._stack) do
			if state._off == false then

				if func == 'update' then
					for group, arr in pairs(state.game) do
				        for i_e, e in ipairs(arr) do
				            if e.auto_update and not e.pause then
				                if e._update then
				                	e:_update(...)
				                elseif e.update then
					                e:update(...)
					            end
				            end
				        end
				    end
				end

				if func == 'draw' and state.draw then
					-- is a transition happening?
					if transition_active then
						-- is this the 'entering' state?
						if transition_obj.enter_state.classname == state.classname then
							transition_obj.transition_fn(state)
						
						-- is this the 'exiting' state?
						elseif transition_obj.exit_state.classname == state.classname then
							drawStateNormal(state)

						end
					else
						drawStateNormal(state)
					end
				else
					if state[func] then state[func](state,...) end
				end
			end
		end

		if func == 'update' and transition_obj.tween then
			transition_obj.tween:update(...)
		end
	end,

	clearStack = function()
		for s, state in ipairs(StateManager._stack) do
			state:_leave()
            StateManager._stack[s] = nil
		end
		StateManager._stack = {}
		StateManager.current_state = nil
	end,

	push = function(new_state, prev_state)
		new_state = StateManager.verifyState(new_state)
		prev_state = ifndef(ifndef(prev_state, StateManager.current_state), {classname=''}).classname
        
        if new_state._off then
            new_state._off = false
            StateManager.current_state = new_state
            table.insert(StateManager._stack, new_state)
            if new_state.load and not new_state._loaded then
                new_state:load()
                new_state._loaded = true
            end
            if new_state.enter then new_state:enter(prev_state) end
        end
	end,

	-- remove newest state
	pop = function(state_name)
		function closingStatements(state)
			state:_leave()
			state._off = true
		end

		if state_name then
			for s, obj_state in ipairs(StateManager._stack) do
				if obj_state.classname == state_name then
					closingStatements(obj_state)
					table.remove(StateManager._stack, s)
            		StateManager.current_state = StateManager._stack[#StateManager._stack]
				end
			end
		else
			local state = StateManager._stack[#StateManager._stack]
			closingStatements(state)
			table.remove(StateManager._stack)
            StateManager.current_state = StateManager._stack[#StateManager._stack]
		end
	end,

	states = {},
	verifyState = function(state)
		local obj_state = state
		if type(state) == 'string' then 
			if StateManager.states[state] then obj_state = StateManager.states[state] else
				error('State \"'..state..'\" does not exist')
			end
		end
		return obj_state
	end,

	switch = function(name)
		if type(name) == "string" then name = _G[name] end

		local current_state = StateManager.current_state
        if name ~= nil and name ~= '' then
			-- add to state stack
			StateManager.clearStack()
            StateManager.push(name, current_state)
        end
	end,

	_setupTransition = function(curr_state, next_state, animation, args)

		transition_obj.exit_state = curr_state
		transition_obj.enter_state = next_state
		transition_obj.animation = animation
        
		local diag_size = math.sqrt((game_width*game_width) + (game_height*game_height))
		local stencil_fn = function(state, test, fn)
			love.graphics.stencil(fn, "replace", 1)
			love.graphics.setStencilTest(test, 0)
			drawStateNormal(state)
			love.graphics.setStencilTest()
		end

		if animation == "circle-in" then
			transition_obj.transition_fn = function(state)
				stencil_fn(state, "equal", function()
					love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.tween.var)
				end)
			end
			transition_obj.tween = Tween(diag_size, 0, .5)
		end

		if animation == "circle-out" then
			transition_obj.transition_fn = function(state)
				stencil_fn(state, "greater", function()
					love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.tween.var)
				end)
			end
			transition_obj.tween = Tween(0, diag_size, .5)
		end

		if animation == "wipe-up" then
			transition_obj.transition_fn = function(state)
				stencil_fn(state, "greater", function()
					Draw.rect("fill", 0, transition_obj.tween.var, game_width, game_height - transition_obj.tween.var)
				end)	
			end
			transition_obj.tween = Tween(game_width, 0, .5)
		end
		if animation == "wipe-down" then
			transition_obj.transition_fn = function(state)
				stencil_fn(state, "equal", function()
					Draw.rect("fill", 0, transition_obj.tween.var, game_width, game_height - transition_obj.tween.var)
				end)	
			end
			transition_obj.tween = Tween(0, game_width, .5)
		end

		if animation == "clockwise" then
			transition_obj.transition_fn = function(state)
				stencil_fn(state, "greater", function()
					love.graphics.arc("fill", game_width/2, game_height/2, diag_size, math.rad(270), math.rad(transition_obj.tween.var+270))
				end)
			end
			transition_obj.tween = Tween(0, 360, .5)
		end
		if animation == "counter-clockwise" then
			transition_obj.transition_fn = function(state)
				stencil_fn(state, "equal", function()
					love.graphics.arc("fill", game_width/2, game_height/2, diag_size, math.rad(270), math.rad(transition_obj.tween.var+270))
				end)
			end
			transition_obj.tween = Tween(360, 0, .5)
		end

		if animation == "fade" then
			assert(args[1], "Fade transition requires color arg")
			transition_obj.transition_fn = function(state)
				Draw.stack(function()
					Draw.setColor(args[1])
					Draw.setAlpha(transition_obj.tween.var)
					Draw.rect('fill',0,0,game_width,game_height)
				end)
			end
			transition_obj.tween = Tween(0, 1, .5)
		end

		if transition_obj.tween then
			transition_obj.tween.auto_update = false
		end
	end,

	transition = function(next_state, animation, ...)
		if not (transition_obj.enter_state or transition_obj.exit_state) then

			local curr_state = StateManager.current()
			next_state = StateManager.verifyState(next_state)

			resetTransitionObj()

			StateManager._setupTransition(curr_state, next_state, animation, {...})

			transition_obj.tween.onFinish = function()
				local exit_state = transition_obj.exit_state
				resetTransitionObj()
				StateManager.pop(exit_state.classname)

				exit_state.in_transition = false
				StateManager.in_transition = false
			end

			transition_obj.tween:play()
			transition_obj.exit_state.in_transition = true
			StateManager.in_transition = true

			StateManager.push(transition_obj.enter_state)
		end
	end,

    current_state = nil,
	current = function()
		return StateManager.current_state
	end
}

State = Class{
	game = {},
	background_color = nil,
	transition = function(...)
		StateManager.transition(...)
	end,

	switch = function(name)
		StateManager.switch(name)
	end,

	current = function()
		return StateManager.current()
	end,

	_enter = function(self)
		if self.enter then self:enter(prev_state) end
		self._off = false
	end,

	_leave = function(self)
		if self.leave then self:leave() end
		BlankE.clearObjects(true, self)
		self._off = true
	end
}

return State
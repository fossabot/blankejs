let color_vars = {
	r:'red component (0-1 or 0-255) / hex (#ffffff) / string (\'blue\')',
	g:'green component',
	b:'blue component',
	a:'optional alpha'
}

// Group 1: name of class to replace <class_name> in instance_regex
module.exports.class_regex = {
	'state': 	[
		/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"State"\s*\).*/g,
		/.*BlankE\.addState\s*\(\s*"(\w+)"\s*\).*/g,
		/\b(State).*/g
	],
	'entity': 	[
		/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"Entity"\s*\).*/g,
		/.*BlankE\.addEntity\s*\(\s*"(\w+)"\s*\).*/g,
		/\b(Player).*/g
	],
	'blanke': 	/.*(BlankE).*/g,
	'draw': 	/\b(Draw).*/g,
	'asset': 	/\b(Asset).*/g,
	'input': 	/\b(Input).*/g,
	'image': 	/\b(Image).*/g,
	'scene': 	/\b(Scene).*/g
}

// Group 1: name of instance 
module.exports.instance_regex = {
	'entity': 	/\b(\w+)\s*=\s*<class_name>\(\).*/g,
	'input': 	/\bInput\.keys(\[[\'\"]\w+[\'\"]\])/g,
	'image': 	/\b(\w+)\s*=\s*Image\([\'\"][\w\.]+[\'\"]\)\s+?/g,
	'scene': 	/\b(\w+)\s*=\s*Scene\([\'\"][\w\.]+[\'\"]\)\s+?/g
}

// how to treat use of the 'self' keyword when used inside a callback
module.exports.self_reference = {
	'blanke-state': 'class',
	'blanke-entity': 'instance'
}

module.exports.completions = {
	"global":[
		{fn:"Image", vars:{ name:'images/ground.png -> Image(\"ground\")' }}
	],
	"blanke-blanke":[
		{fn:"init", vars:{ first_state:'State the game should start in' }},
		{fn:"addClassType",
		vars:{
			arg1:'MenuState / Player / ...', arg2:'State / Entity / etc.'
		}},
		{fn:"loadPlugin", vars:{ name:'' }},
		{prop:"draw_debug"}
	],
	"blanke-asset":[
		{fn:"add", vars:{ path:'file or folder (ending with \'/\')' }},
		{fn:"list", vars:{ file_type:'script / image / map / file' }}
	],
	"blanke-draw":[
		{fn:"setBackgroundColor", vars:color_vars},
		{fn:"randomColor", vars:{ alpha:'' }},
		{fn:"setColor", vars:color_vars},
		{fn:"resetColor"},
		{fn:"point", vars:{ x:'', y:'' }},
		{fn:"points"},
		{fn:"line"},
		{fn:"rect"},
		{fn:"circle"},
		{fn:"polygon"},
		{fn:"text"},
		{fn:"textf"},
	],
	"blanke-input":[
		{fn:"set", vars:{ label:'', input1:'input to catch</br>- letters: w, a, s, d, ...', etc:'' }}
	],
	"blanke-input-instance":[
		{prop: "can_repeat"},
		{fn: "reset"}
	],
	"blanke-state":[
		{fn:"switch",
		vars:{
			name: "name of state to switch to"
		}},
		{fn:"transition"},
		{fn:"current"},
		{fn:"enter", callback: true,
		vars:{
			prev_state: "state that was active before this one"
		}},
		{fn:"update", callback: true},
		{fn:"draw", callback: true},
		{fn:"leave", callback: true}
	],
	"blanke-entity":[
		{fn:"init", callback: true},
		{fn:"preUpdate", callback: true, vars:{ dt:'' }},
		{fn:"update", callback: true, vars:{ dt:'' }},
		{fn:"preDraw", callback: true},
		{fn:"draw", callback: true},
		{fn:"postDraw", callback: true},
	],
	"blanke-entity-instance":[
		{prop:"x"},
		{prop:"y"},
		{prop:"direction"},
		{prop:"friction"},
		{prop:"gravity"},
		{prop:"gravity_direction", info:"in degrees. 0 = right, 90 = down, default = 90"},
		{prop:"hspeed"},
		{prop:"vspeed"},
		{prop:"speed", info:"best used with 'direction'"},
		{prop:"xprevious"},
		{prop:"yprevious"},
		{prop:"xstart"},
		{prop:"ystart"},

		{prop:"sprite_angle"},
		{prop:"sprite_xscale"},
		{prop:"sprite_yscale"},
		{prop:"sprite_xoffset"},
		{prop:"sprite_yoffset"},
		{prop:"sprite_xshear"},
		{prop:"sprite_yshear"},
		{prop:"sprite_color"},
		{prop:"sprite_alpha"},
		{prop:"sprite_speed"},
		{prop:"sprite_frame"},
		{prop:"sprite_width"},
		{prop:"sprite_height"},

		{prop:"show_debug", info:"debugSprite() and debugCollision() are automatically called"},

		{fn:"addAnimation",named_args:true,vars:{
			name:'', 
			image:'name of asset (ex. bob_stand, bob_walk)', 
			frames:'{\'1-2\', 1} means columns 1-2 and row 1', 
			frame_size:'{32,32} means each frame is 32 by 32', 
			speed:'0.1 smaller = faster'
		}},
		{fn:"drawSprite",vars:{ name:'calls default draw function for given animation name' }},

		{fn:"destroy"},

		{fn:"hadCollision",vars:{self_name:'', other_name:''}},
		{fn:"getCollisions",vars:{shape_name:''}},
		{fn:"debugSprite",vars:{sprite_index:''}},
		{fn:"debugCollision"}
	],
	"blanke-image-instance":[
		{prop:"x"},
		{prop:"y"},
		{fn:"draw"},
		{fn:"crop",vars:{x:"",y:"",width:"",height:""}}
	],
	"blanke-scene-instance":[
		{prop:"draw_hitboxes"},
		{fn:"addHitbox",vars:{ object_name:"", etc:"" }},
		{fn:"addEntity",vars:{ object_name:"", entity_class:"", alignment:"center, left, right, top, bottom, top-left, center-bottom, etc." }},
		{fn:"draw"}
	]
}
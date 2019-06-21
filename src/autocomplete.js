let color_vars = {
	r:'red component (0-1 or 0-255) / hex (#ffffff) / preset (\'blue\')',
	g:'green component',
	b:'blue component',
	a:'optional alpha'
}
let color_prop = '{r,g,b} (0-1 or 0-255) / hex (\'#ffffff\') / preset (\'blue\')';

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#Keywords
// used Array.from(document.querySelectorAll("#Reserved_keywords_as_of_ECMAScript_2015 + .threecolumns code")).map((v)=>"'"+v.innerHTML+"'").join(',')
module.exports.keywords = [
	'break','case','catch','class','const','continue','debugger','default','delete',
	'do','else','export','extends','finally','for','function','if','import','in',
	'instanceof','new','return','super','switch','this','throw','try','typeof',
	'var','void','while','with','yield'
]

// only vars starting with 'local'
// (?:(?:local\s+|,\s*)(?!\.)([a-zA-Z_]\w*)[,\n\r]?\s*)[^\n\r\.\:]+?(?:(?!=\s*function)(?==)|[\n\r])
module.exports.user_words = {
	'var':[
		// single var
		/([a-zA-Z_]\w+?)\s*=\s(?!function|\(\)\s*=>)/g,
		// comma separated var list
		/(?:let|var)\s+(?:[a-zA-Z_]+[\w\s=]+?,\s*)+([a-zA-Z_]\w+)(?!\s*=)/g
	],
	'fn':[
		// var = function
		/([a-zA-Z_]\w+?)\s*=\s(?:function|\(\)\s*=>)/g,
		// function var()
		/function\s+([a-zA-Z_]\w+)\s*\(/g
	]
}

// displays the image in the editor
module.exports.image = [
	/Sprite\(["']([\w\s\/.-]+)["']\)/,
	/self:addSprite[\s\w{(="',]+image[\s=]+['"]([\w\s\/.-]+)/,
	/Sprite[\s\w{(="',]+image[\s=]+['"]([\w\s\/.-]+)/
];

module.exports.class_list = ['Game','Util','Map'];

// Group 1: name of class to replace <class_name> in instance_regex
module.exports.class_regex = {
	'state': 	[
		/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"State"\s*\).*/g,
		/.*BlankE\.addState\s*\(\s*"(\w+)"\s*\).*/g,
		/\b(State).*/g
	],
	'entity': 	[
		/\bclass\s+(\w+)\s+extends\s+Entity/g
	]
}

// Group 1: name of instance 
module.exports.instance_regex = {
	'entity': /\b([a-zA-Z_]\w+?)\s*=\s*new\s+<class_name>\s*\(/g,
	'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)\s+?/g
}
// old group/bezier regex: /\b(?:self.|self:)?(\w+)\s*=\s*Group\(\).*/g

// how to treat use of the 'self' keyword when used inside a callback
module.exports.self_reference = {
	'blanke-state': 'class',
	'blanke-entity': 'instance'
}

/*
	{ fn: "name", info, vars }
	{ prop: "name", info }

	- info: "description"
	- vars: { arg1: 'default', arg2: 'description', etc: '' }
*/
module.exports.completions = {
	"global":[],
	"blanke-game":[
		{ fn: 'end' }
	],
	"blanke-util":[
		{ fn: 'rad', vars: { deg:'' }, info: 'converts degrees to radians' },
		{ fn: 'deg', vars: { rad:'' }, info: 'converts radians to degrees' },
		{ fn: 'direction_x', vars: { angle:'degrees', dist:'' } },
		{ fn: 'direction_y', vars: { angle:'degrees', dist:'' } },
		{ fn: 'distance', vars: { x1:'', y1:'', x2:'', y2:'' } },
		{ fn: 'direction', vars: { x1:'', y1:'', x2:'', y2:'' } },
		{ fn: 'rand_range', vars: { min:'', max:'' } },
		{ fn: 'basename', vars: { path:'', no_ext:'' } }
	],
	"blanke-map":[
		{ fn: 'load', vars: { name:'map asset' } }
	],
	"blanke-map-instance":[
		{ prop: 'debug' },
		{ fn: 'addLayer', vars: { name:'' } },
		{ fn: 'addTile', vars: { name:'image asset', position:'[x, y, x, y, ...]', options:'{ layer }' } },
		{ fn: 'addEntity', vars: { entity_class:'', x:'', y:'', options:'{ layer, align (left, right, top, bottom, center) }' } },
		{ fn: 'addHitbox', vars: { hitbox_args:'' } },
		{ fn: 'removeTile', vars: { name:'image asset', position:'[x, y, x, y, ...]', layer:'' } }
	]
}
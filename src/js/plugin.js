let lua_plugins = [];
let js_plugins = [];
let dir_plugins = [];
let zip_plugins = [];

let pathJoin;
let plugin_watch;

// get a list of .lua and .js files
function refreshPluginList(silent) {
	blanke.cooldownFn('refreshPlugin',500,function(){
		nwFS.readdir(app.settings.plugin_path, (err, files) => {
			let full_path;
			for (let f of files) {
				full_path = pathJoin(app.settings.plugin_path, f);
				if (f.endsWith('.lua')) {
					lua_plugins.push(f);
				}
				if (f.endsWith('.js')) {
					js_plugins.push(f);
				}
				if (f.endsWith('.blex') || f.endsWith('.zip') || f.endsWith('.rar')) {
					zip_plugins.push(f);
				}
				if (nwFS.statSync(full_path).isDirectory()) {
					dir_plugins.push(full_path);
				}
			}
			installPlugins(silent);
		});
	});
}

function installPlugins(silent) {
	// move lua files to <engine_path>/lua/blanke/plugins/
	let eng_plugin_dir = pathJoin(app.settings.engine_path,'lua','blanke','plugins');
	function inspectFolder(folder) {
		let files = nwFS.readdirSync(folder);
		for (let f of files) {
			if (f.endsWith('.md')) {
				Docview.addPlugin(f.split('.')[0], pathJoin(eng_plugin_dir,f.split('.')[0], f));
			}
		}
	}

	nwFS.emptyDir(eng_plugin_dir, err => {
		if (err) return console.error(err);
		// .lua
		for (let f of lua_plugins) {
			nwFS.copyFileSync(pathJoin(app.settings.plugin_path,f), pathJoin(eng_plugin_dir,f));
		}
		// .zip/.rar/.blex
		for (let f of zip_plugins) {
			nwZIP2(pathJoin(app.settings.plugin_path,f)).extractAllTo(pathJoin(eng_plugin_dir,f.split('.')[0]), true);
			inspectFolder(pathJoin(eng_plugin_dir,f.split('.')[0]));
		}
		// dir
		for (let d of dir_plugins) {
			d = nwPATH.basename(d);
			nwFS.copySync(pathJoin(app.settings.plugin_path,d), pathJoin(eng_plugin_dir,d))
			inspectFolder(pathJoin(eng_plugin_dir,d))
		}

		// if (!silent) blanke.toast("Plugins loaded!")
	});

	// add .js files to ide somehow
	// ...
}

document.addEventListener("openProject",function(e){
	refreshPluginList(true);
});


document.addEventListener("ideReady",function(e){
	pathJoin = nwPATH.join;
});

document.addEventListener("appdataSave", (e) => {
	// watch for updates to plugins
	nwFS.ensureDir(app.settings.plugin_path, (err) => {
		if (plugin_watch) 
			plugin_watch.close();
		plugin_watch = nwWATCH(app.settings.plugin_path, {recursive: true}, function(evt_type, file) {
			refreshPluginList();
		});
	});
});
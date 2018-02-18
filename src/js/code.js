class Code extends Editor {
	constructor (...args) {
		super(...args);
		
		this.file = '';
		this.script_folder = "/scripts";

		// create codemirror editor
		this.edit_box = document.createElement("textarea");
		this.edit_box.classList.add("code")
		this.appendChild(this.edit_box)

		var this_ref = this;
		this.codemirror = CodeMirror.fromTextArea(this.edit_box, {
			mode: "javascript",
			theme: "material",
            smartIndent : true,
            lineNumbers : true,
            lineWrapping : false,
            indentUnit : 4,
            extraKeys: {
            	"Ctrl-S": function(cm) {
            		this_ref.save();
            	}
            }
		});
		this.codemirror.setSize("100%", "100%");
		this.codemirror.on('change', function(){
			this_ref.codemirror.refresh();
		});
	}

	onMenuClick (e) {
		var this_ref = this;
		app.contextMenu(e.x, e.y, [
			{label:'rename', click:function(){this_ref.renameModal()}},
			{label:'delete', click:function(){this_ref.deleteModal()}}
		]);
	}

	edit (file_path) {
		var this_ref = this;

		this.file = file_path;
		var text = nwFS.readFileSync(file_path, 'utf-8');

		this.codemirror.setValue(text);
		this.codemirror.clearHistory();
		this_ref.codemirror.refresh();

		this.setTitle(nwPATH.basename(file_path));
	}

	save () {
		nwFS.writeFileSync(this.file, this.codemirror.getValue());
	}

	delete (path) {
		nwFS.unlink(path);

		if (this.file == path) {
			this.close();
		}
	}

	deleteModal () {
		var name = this.file;
		if (name.includes('main.lua')) {
			blanke.showModal(
				"You cannot delete \'"+name+"\'",
			{
				"oops": function() {}
			});
		} else {
			var this_ref = this;
			blanke.showModal(
				"delete \'"+name+"\'",
			{
				"yes": function() { this_ref.delete(name); },
				"no": function() {}
			});
		}
	}

	rename (old_path, new_name) {
		var this_ref = this;
		nwFS.readFile(nwPATH.dirname(this.file)+"/"+new_name, function(err, data){
			if (err) {
				nwFS.rename(old_path, nwPATH.dirname(this_ref.file)+"/"+new_name);
				this_ref.file = nwPATH.dirname(this_ref.file)+"/"+new_name;
				this_ref.setTitle(nwPATH.basename(this_ref.file));
			}
		});
	}

	renameModal () {
		var filename = this.file;

		if (nwPATH.basename(filename) == 'main.lua') {
			blanke.showModal(
				"You cannot rename \'"+nwPATH.basename(filename)+"\'",
			{
				"oh yea I forgot": function() {}
			});
		} else {
			var this_ref = this;
			blanke.showModal(
				"<label>new name: </label>"+
				"<input class='ui-input' id='new-file-name' style='width:100px;' value='"+nwPATH.basename(filename, nwPATH.extname(filename))+"'/>",
			{
				"yes": function() { this_ref.rename(filename, app.getElement('#new-file-name').value+".lua"); },
				"no": function() {}
			});
		}
	}

	onFileChange (evt_type, file) {
		this.app.removeSearchGroup("Code");
		addScripts(this.app.project_path);
	}
}

document.addEventListener("ideReady", function(e){

});

function addScripts(folder_path) {
	nwFS.readdir(folder_path, function(err, files) {
		if (err) return;
		files.forEach(function(file){
			var full_path = nwPATH.join(folder_path, file);
			nwFS.stat(full_path, function(err, file_stat){		
				// iterate through directory			
				if (file_stat.isDirectory())
					addScripts(full_path);

				// add file to search pool
				else if (file.endsWith('.lua')) {
					app.addSearchKey({
						key: file,
						onSelect: function(file_path){
							if (!DragBox.focusDragBox(nwPATH.basename(file_path)))
								(new Code(app)).edit(file_path);
						},
						tags: ['script'],
						args: [full_path],
						group: 'Code'
					});
				}
			});
		});
	});
}

document.addEventListener("openProject", function(e){
	var proj_path = e.detail.path;
	addScripts(proj_path);

	app.addSearchKey({
		key: 'Create script',
		onSelect: function() {
			var script_dir = nwPATH.join(app.project_path,'scripts');
			nwFS.stat(script_dir, function(err, stat) {
				if (!stat.isDirectory()) nwFS.mkdirSync(script_dir);
				// overwrite the file if it exists. fuk it!!
				nwFS.readdir(script_dir, function(err, files){
					nwFS.writeFile(nwPATH.join(script_dir, 'script'+files.length+'.lua'),"\
-- create an Entity: BlankE.addClassType(\"Player\", \"Entity\");\n\n\
-- create a State: BlankE.addClassType(\"houseState\", \"State\");\
					");

					// edit the new script
					(new Code(app)).edit(nwPATH.join(script_dir, 'script'+files.length+'.lua'));
				});
			});
		},
		tags: ['new']
	});
});
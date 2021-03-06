class Editor {
	constructor () {
		var workspace = app.getElement('#workspace');
		this.app = app;
		this.closed = false;

		var this_ref = this;

		// asset list
		this.asset_list = document.createElement("div");
		this.asset_list.classList.add('asset-list');

		// real content area
		this.content_area = document.createElement("div");
		this.content_area.classList.add('editor-content');
	}

	setupDragbox() {
		var this_ref = this;
		this.container_type = 'dragbox';
		// create drag box
		this.container = new DragBox(this.constructor.name)
		this.container.appendTo(workspace);
		this.container.width = 400;
		this.container.height = 300;
		this.container.drag_container.appendChild(this.asset_list);
		this.container.appendChild(this.content_area);
		// menu button click
		this.container.btn_menu.onclick = function(e) {
			this_ref.onMenuClick(e);
		}
		return this;
	}

	setupTab() {
		var this_ref = this;
		this.container_type = 'tab';
		// create tab
		this.container = new Tab(this.constructor.name);
		this.container.appendChild(this.content_area);
		app.setHistoryActive(this.container.history_id, true);
		app.setHistoryContextMenu(this.container.history_id, function(e) {
			this_ref.onMenuClick(e);
		});
		this.container.onClose = this.onClose;
		return this;
	}

	setupFibWindow() {
		var this_ref = this;
		this.container_type = "fibwindow";
		this.container = new FibWindow(this.constructor.name);
		this.container.appendTo(workspace);
		this.container.appendChild(this.content_area);
		this.container.btn_menu.onclick = function(e) {
			this_ref.onMenuClick(e);
		}
		app.setHistoryActive(this.container.history_id, true);
		app.setHistoryContextMenu(this.container.history_id, function(e) {
			this_ref.onMenuClick(e);
		});
		this.container.onClose = this.onClose;
		return this;
	}

	removeHistory() {
		app.removeHistory(this.container.history_id);
	}

	// Tab ONLY	
	setOnClick() {
		if (this.container_type == 'tab')
			this.container.setOnClick.apply(this.container, arguments);
		if (this.container_type == 'fibwindow')
			app.setHistoryClick(this.container.history_id, arguments[0]);
	}

	close(...args) {
		app.setHistoryActive(this.container.history_id, false);
		this.container.close(...args);
		if (this.onClose) this.onClose();
		this.closed = true;
	}

	static closeAll (type) {
		DragBox.closeAll(type);
		Tab.closeAll(type);
		FibWindow.closeAll();
	}

	addCallback(cb_name, new_func) {
		this.container[cb_name] = new_func;
	}

	get width() {
		return this.container.width;
	}

	get height() {
		return this.container.height;
	}

	get bg_width() {
		if (this.container.in_background)
			return app.getElement('#bg-workspace').clientWidth;
		else 
			return this.width;
	}

	get bg_height() {
		if (this.container.in_background)
			return app.getElement('#bg-workspace').clientHeight;
		else 
			return this.height;
	}

	hideMenuButton () {
		if (this.container.btn_menu)
			this.container.btn_menu.style.display = 'none';
	}

	getContent() {
		return this.content_area;
	}

	getContainer() {
		return this.container;
	}

	appendChild (el) {
		this.content_area.appendChild(el);
	}

	isInBackground () {
		return this.container.in_background == true;
	}

	appendBackground (...args) {
		if (this.container_type == 'fibwindow') 
			this.container.appendBackground(...args);
	}

	setTitle (val) {
		this.container.setTitle(val);
		return this;
	}

	setSubtitle (val) {
		if (this.container_type == 'dragbox' || this.container_type == 'fibwindow')
			this.container.setSubtitle(val);
		return this;
	}

	onMenuClick (e) {
		this.toggleMenu();
	}

	toggleMenu () {
		this.asset_list.classList.toggle("open");
	}

	setAssetList (list, context_menu, on_menu_click) {
		var this_ref = this;

		// clear list
		this.asset_list.innerHTML = "";

		// context menu
		var menu = new nwGUI.Menu();
		context_menu.forEach(function(m){
			var item = new nwGUI.MenuItem(m);
			item.click = function() { on_menu_click(this.label, this_ref.list_value); }
			menu.append(item);
		});

		// add asset buttons
		for (var l = 0; l < list.length; l++) {
			let el_asset = this.app.createElement("button", "asset");
			el_asset.innerHTML = list[l];
			el_asset.onclick = function() {
				this_ref.toggleMenu(); 
				if (this_ref.onAssetSelect) this_ref.onAssetSelect(this.innerHTML);
			}
			el_asset.addEventListener('contextmenu', function(ev) { 
				ev.preventDefault();
				menu.popup(ev.x, ev.y);
				this_ref.list_value = ev.target.innerHTML;
				return false;
			});

			this.asset_list.appendChild(el_asset);
		}
	}
}

document.addEventListener("openProject", function(e){
	Editor.closeAll();
});
class DragBox {
	constructor (content_type) {
		this.guid = guid();

		this.drag_container = document.createElement("div");
		this.drag_container.classList.add("drag-container");
		this.drag_container.id = "drag-container-"+this.guid;

		this.drag_handle = document.createElement("div");
		this.drag_handle.classList.add("drag-handle");
		this.drag_container.appendChild(this.drag_handle);

		this.drag_content = document.createElement("div");
		this.drag_content.classList.add("content");
		this.drag_content.dataset.type = content_type;
		this.drag_container.appendChild(this.drag_content);

		interact('#'+this.drag_container.id)
			.draggable({
				allowFrom: '.drag-handle',
				inertia: false,
				restrict: {
					restriction: "parent",
					endOnly: true,
					elementRect: {top:0, left:0, bottom:1, right:1}
				},
				onmove: function(event) {
				    var target = event.target,
			        // keep the dragged position in the data-x/data-y attributes
			        x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx,
			        y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;

				    // translate the element
				    target.style.webkitTransform =
				    target.style.transform =
				      'translate(' + x + 'px, ' + y + 'px)';

				    // update the posiion attributes
				    target.setAttribute('data-x', x);
				    target.setAttribute('data-y', y);
				}
			})
			.resizable({
				allowFrom: '.content',
				edges: {left:false, right:true, bottom:true, top:false},
				restictEdges: {
					outer: 'parent',
					endOnly: true
				}
			})
			.on('resizemove', function (event) {
			    var target = event.target,
			        x = (parseFloat(target.getAttribute('data-x')) || 0),
			        y = (parseFloat(target.getAttribute('data-y')) || 0);

			    // update the element's style
			    target.style.width  = event.rect.width + 'px';
			    target.style.height = event.rect.height + 'px';

			    // translate when resizing from top or left edges
			    x += event.deltaRect.left;
			    y += event.deltaRect.top;

			    target.style.webkitTransform = target.style.transform =
			        'translate(' + x + 'px,' + y + 'px)';

			    target.setAttribute('data-x', x);
			    target.setAttribute('data-y', y);
			});
	}

	appendTo (element) {
		element.appendChild(this.drag_container);
	}

	set width(w) {
		this.drag_container.style.width = w.toString()+"px";
	}

	set height(h) {
		this.drag_container.style.height = h.toString()+"px";
	}

	setContent (element) {
		this.drag_content.innerHTML = "";
		this.drag_content.appendChild(element);
	}
}
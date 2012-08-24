component extends="Events" {
	// Create a new Backbone.View
	this.new = function (struct options = {}) {
		var BackboneView = new View().extend();
		return BackboneView(options);
	};
	// Returns a function that creates new instances of this view
	this.extend = function (struct obj = {}) {
		return function (struct options = {}) {
			var View = new Backbone.View();

			_.extend(options, obj);

			_.extend(View, obj);

			// _.extend(View, duplicate(Backbone.Events));

			// apply special options directly to View
			var specialOptions = ['model','collection','el','id','className','tagName','attributes'];
			_.each(specialOptions, function (option) {
				if (_.has(options, option)) {
					View[option] = _.result(options, option);
					// structDelete(options, option);
				}
			});

			View.options = options;

			_.bindAll(View);

			if (structKeyExists(View, 'initialize')) {
				View.initialize(argumentCollection = arguments);
			}

			View._ensureElement();

			View.cid = _.uniqueId('view');

			// TODO: write Underscore.cfc proxies

			return View;
		};
	};
    // The default `tagName` of a View's element is `"div"`.
	this.tagName = 'div';
	// For small amounts of elements, where a full-blown template isn't
	// needed, use **make** to manufacture elements, one at a time.
	//
	//     var el = this.make('li', {'class': 'row'}, this.model.escape('title'));
	//
	this.make = function(required string tagName, struct attributes = {}, string content = '') {
		var htmlTag = "<#tagName#";
		if (!_.isEmpty(attributes)) {
			_.each(attributes, function(val, key){
				htmlTag = htmlTag & " #key#='#val#'";
			});
		}
		htmlTag = htmlTag & ">#content#</#tagName#>";
		return htmlTag;
	};
	// Change the view's element (`this.el` property), including event re-delegation.
	this.setElement = function(element, delegate) {
		this.el = element;
		// TODO: something with delegate? or $el?
	};
	// Ensure that the View has an element to render into. Create
	// an element from the `id`, `className` and `tagName` properties.
	variables._ensureElement = function() {
		if (!_.has(this, 'el')) {
			var attrs = _.has(this, 'attributes') ? this.attributes : {};
			if (_.has(this, 'id'))
				attrs.id = this.id;
			if (_.has(this, 'className'))
				attrs.class = this.className;
			this.setElement(this.make(this.tagName, attrs), false);
		}
		else {
			this.setElement(this.el, false);
		}
	};
}
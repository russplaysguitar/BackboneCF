component {
		
	_ = new github.UnderscoreCF.Underscore();

	public struct function init() {
		return Backbone;
	}

	Backbone = {};
	Backbone.Events = {
		on: function (required string eventName, required callback, context = {}) {
			var event = listFirst(eventName, ":");
			var attribute = listLast(eventName, ":");

			if (!_.has(this.listeners, eventName))
				this.listeners[eventName] = [];

			if (!_.isEmpty(context))
				callback = _.bind(callback, context);

			// TODO: allow callback to be referenced by name or something so off() can remove it specifically
			ArrayAppend(this.listeners[eventName], callback);
		},
		off: function (eventName, callback, context) {
			if (_.has(this.listeners, eventName)) {
				structDelete(this.listeners, eventName);
			}
		},
		trigger: function (eventName, model, val, changedAttributes) {
			// TODO: handle list of events
			if (_.has(this.listeners, eventName)) {
				var funcsArray = this.listeners[eventName];
				_.each(funcsArray, function (func) {
					func(model, val, changedAttributes);
				});
			}
		}
	};
	Backbone.Model = {
		attributes: {},
		defaults: {},
		changedAttributes: {
			changes: {}
		},
		listeners: {},
		extend: function (obj = {}) {
			return function (attributes = {}) {
				var Model = duplicate(Backbone.Model);

				_.extend(Model, obj);

				if (_.has(obj, 'defaults')) {
					Model.attributes = Model.defaults;
				}

				_.extend(Model, Backbone.Events);

				_.bindAll(Model);

				if (_.has(attributes, 'id')) {
					Model.id = attributes.id;
					structDelete(attributes, 'id');
				}

				if (_.has(Model, 'idAttribute') && _.has(attributes, Model.idAttribute)) {
					Model.id = attributes[Model.idAttribute];
				}				

				_.extend(Model.attributes, arguments.attributes);

				if (structKeyExists(Model, 'initialize')) {
					Model.initialize(attributes);
				}

				Model.cid = _.uniqueId('c');

				return Model;
			};
		},
		get: function (required string key) {
			if (this.has(key))
				return this.attributes[key];
		},
		escape: function (key) {
			return _.escape(key);
		},
		set: function (required string key, val, options = {}) {
			// TODO: handle collection
			// TODO: handle silent option
			// TODO: set up "changed" struct (see backbone.js Model.changed)
			var newAttributes = duplicate(this.attributes);
			newAttributes[key] = val;
			var isValid = this.validate(newAttributes);
			if (!isValid) {
				return;
			}
			this.changedAttributes.changes[key] = true;
			this.change(this, val, this.changedAttributes);
			this.attributes[key] = val;
		},
		has: function (required string key) {
			return _.has(this.attributes, key);
		},
		unset: function (required string key, options = { silent: false }) {
			if (!this.has(key)) 
				return;
			this.changedAttributes.changes[key] = true;
			var val = this.attributes[key];
			structDelete(this.attributes, key);
			if (!options.silent) 
				this.change(this, val, this.changedAttributes);
		},
		clear: function (options = { silent: false }) {
			_.each(this.attributes, function (val, key) {
				this.unset(key, options);
			});
		},
		validate: function (attributes) {
			return true;
		},
		isValid: function () {
			return this.validate();
		},
		change: function (model, val, changedAttributes) {
			_.each(changedAttributes.changes, function (v, k) {
				var eventName = 'change:' & k;
				this.trigger(eventName, model, val, changedAttributes);
			});
		},
		toJSON: function () {
			return serializeJSON(this.attributes);
		},
		clone: function () {
			var newModel = duplicate(this);
			newModel.cid = _.uniqueId('c');
			return newModel;
		}
	};
	Backbone.Collection = {
		Model: Backbone.Model.extend(),
		models: [],
		extend: function (obj = {}) {
			return function (models = [], options = {}) {
				var Collection = duplicate(Backbone.Collection);

				_.extend(Collection, obj);

				_.extend(Collection, Backbone.Events);

				_.bindAll(Collection);

				Collection.models = models;

				if (structKeyExists(Collection, 'initialize')) {
					Collection.initialize(argumentCollection = arguments);
				}

				// TODO: write Underscore.cfc proxies

				return Collection;
			};
		},
		toJSON: function () {
			var result = _.map(this.models, function(model) {
				return model.toJSON();
			});
			return result;
		},
		add: function (models = [], options = {}) {
			_.each(models, function(model) {
				if (_.has(model, 'cid')) {
					// model is already a Backbone Model
					this.push(model);
				}
				else {
					var newModel = this.Model(model);
					this.push(newModel);
				}
				// TODO: handle options and events
			});
		},
		remove: function (models = [], options = {}) {
			this.models = _.without(this.models, models);
			// TODO: events
		},
		get: function (required id) {
			return _.find(this.models, function(model) {
				return _.has(model, 'id') && model.id == id;
			});
		},
		getByCid: function (required cid) {
			return _.find(this.models, function(model) {
				return model.cid == cid;
			});
		},
		at: function (required index) {
			return this.models[index];
		},
		push: function (required model, options = {}) {
			ArrayAppend(this.models, model);
			// TODO: trigger event, handle options
		},
		pop: function (options = {}) {
			var result = _.last(this.models);
			this.remove([result]);
			return result;
		},
		unshift: function (required model, options = {}) {
			ArrayPrepend(this.models, model);
			// TODO: events and options
		},
		shift: function (options = {}) {
			var result = _.first(this.models);
			this.remove([result]);
			return result;
			// TODO: options
		},
		length: function () {
			return _.size(this.models);
		},
		sort: function (options = {}) {
			if (_.has(this, 'comparator'))
				this.models = _.sortBy(this.models, this.comparator);
			else 
				throw('Cannot sort a set without a comparator', 'Backbone');
			// TODO: options and "reset" event
		},
		pluck: function (required attribute) {
			return _.map(this.models, function(model) {
				return model.get(attribute);				
			});
		},
		where: function (required attributes) {
			return _.filter(this.models, function(model) {
				var result = true;
				_.each(attributes, function(val, key){
					if(!model.get(key) == val) 
						result = false;
				});
				return result;
			});
		},
		reset: function (models = [], options = {}) {
			this.models = models;
			// TODO: options and events
		},
		create: function (attributes = {}, options = {}) {
			var newModel = this.Model(argumentCollection = arguments);
			this.add([newModel]);
			// TODO: options and events
		}
	};
	Backbone.View = {
		extend: function (obj = {}) {
			return function (options = {}) {
				var View = duplicate(Backbone.View);

				_.extend(View, obj);

				_.extend(View, Backbone.Events);

				// apply special options directly to View
				var specialOptions = ['model','collection','el','id','className','tagName','attributes'];
				_.each(specialOptions, function (option) {
					if (_.has(options, option)) {
						View[option] = options[option];
						structDelete(options, option);
					}
				});

				View.options = options;

				_.bindAll(View);

				if (structKeyExists(View, 'initialize')) {
					View.initialize(argumentCollection = arguments);
				}

				View._ensureElement();

				View.cid = _.uniqueId('c');

				// TODO: write Underscore.cfc proxies

				return View;
			};
		},
		tagName: 'div',
		make: function(required tagName, attributes = {}, content = '') {
			var htmlTag = "<#tagName#";
			if (!_.isEmpty(attributes)) {
				_.each(attributes, function(val, key){
					htmlTag = htmlTag & " #key#='#val#'";
				});
			}
			htmlTag = htmlTag & ">#content#</#tagName#>";
			return htmlTag;			
		},
		setElement: function(element, delegate) {
			this.el = element;
			// TODO: something with delegate? or $el?
		},
		_ensureElement: function() {
			if (!_.has(this, 'el')) {
				var attrs = duplicate(this.attributes);
				if (_.has(this, 'id')) 
					attrs.id = this.id;
				if (_.has(this, 'className'))
					attrs.class = this.className;
				this.setElement(this.make(this.tagName, attrs), false);
			} 
			else {
				this.setElement(this.el, false);
			}
		}
	};
}
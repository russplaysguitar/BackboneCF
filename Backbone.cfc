component {
		
	_ = new github.UnderscoreCF.Underscore();

	public struct function init() {
		return Backbone;
	}

	// convenience function?
	public struct function Model(attributes = {}) {
		var NewModel = Backbone.Model.extend();
		return NewModel(attributes);
	} 

	Backbone = {
		cidCounter: 1,
		Model: {
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

					Model.cid = 'c' & Backbone.cidCounter;
					Backbone.cidCounter++;

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
			set: function (required string key, required val) {
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
			},
			toJSON: function () {
				return serializeJSON(this.attributes);
			},
			clone: function () {
				var newModel = duplicate(this);
				newModel.cid = Backbone.cidCounter;
				Backbone.cidCounter++;
				return newModel;
			}
		}
	};
	Backbone.Collection = {
		model: Backbone.Model.extend(),
		models: [],
		extend: function (obj = {}) {
			return function (models = [], options = {}) {
				var Collection = duplicate(Backbone.Collection);

				_.extend(Collection, obj);

				_.bindAll(Collection);

				Collection.models = models;

				if (structKeyExists(Collection, 'initialize')) {
					Collection.initialize(argumentCollection = arguments);
				}

				return Collection;
			};
		}
	};	
}
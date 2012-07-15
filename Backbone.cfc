component {
		
	_ = new github.UnderscoreCF.Underscore();

	public any function init() {
		
		return Backbone;
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
					var newModel = duplicate(Backbone.Model);

					_.extend(newModel, obj);

					if (_.has(obj, 'defaults')) {
						newModel.attributes = newModel.defaults;
					}

					_.bindAll(newModel);

					if (_.has(attributes, 'id')) {
						newModel.id = attributes.id;
						structDelete(attributes, 'id');
					}

					if (_.has(newModel, 'idAttribute') && _.has(attributes, newModel.idAttribute)) {
						newModel.id = attributes[newModel.idAttribute];
					}				

					_.extend(newModel.attributes, arguments.attributes);

					if (structKeyExists(newModel, 'initialize')) {
						newModel.initialize(attributes);
					}

					newModel.cid = 'c' & Backbone.cidCounter;
					Backbone.cidCounter++;

					return newModel;
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
}
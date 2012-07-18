component {

	public struct function init() {
		variables._ = new github.UnderscoreCF.Underscore();

		variables.httpCFC = new Http();

		return Backbone;
	}

	Backbone = {
		emulateJSON: false,
		emulateHTTP: false
	};

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
		off: function (required string eventName, callback, context) {
			if (_.has(this.listeners, eventName)) {
				structDelete(this.listeners, eventName);
			}
		},
		trigger: function (required string eventName, struct model, val, struct changedAttributes) {
			// TODO: handle list of events
			if (_.has(this.listeners, eventName)) {
				var funcsArray = this.listeners[eventName];
				_.each(funcsArray, function (func) {
					func(model, val, changedAttributes);
				});
			}
		}
	};

	variables.methodMap = {
		'create': 'POST',
		'update': 'PUT',
		'delete': 'DELETE',
		'read':   'GET'
	};

	Backbone.Sync = function (required string method, struct model, struct options = {}) {
		var type = methodMap[method];
		var params = {type: type, dataType: 'json'};

		if (!_.has(options, 'url')) {
			if (!_.has(model, 'url'))
				throw('A "url" property or function must be specified', 'Backbone');
			params.url = _.result(model, 'url');
	    }
	    if (!_.has(options, 'data') && _.has(arguments, 'model') && (method == 'create' || method == 'update')) {
			params.contentType = 'application/json';
			params.data = model.toJSON();
		}
		if (Backbone.emulateJSON) {
			params.contentType = 'application/x-www-form-urlencoded';
			if (_.has(params, 'data'))
				params.data = {model: params.data};
			else
				params.data = {};
	    }
	    if (Backbone.emulateHTTP) {
			if (type == 'PUT' || type == 'DELETE') {
				if (Backbone.emulateJSON)
					params.data._method = type;
				params.type = 'POST';
				params.headers = {
					'X-HTTP-Method-Override': type
				};
			}
		}
		return httpCFC.request(argumentCollection = _.extend(params, options)); 
	};

	Backbone.Model = {
		initialize: function () {},
		attributes: {},
		defaults: {},
		changedAttributes: {
			changes: {}
		},
		_silent: {},
		_pending: {},
		changed: {},
		listeners: {},
		idAttribute: 'id',
		extend: function (struct properties = {}) {
			return function (struct attributes = {}, struct options = {}) {
				var Model = duplicate(Backbone.Model);

				_.extend(Model, properties);

				if (_.has(properties, 'defaults')) {
					arguments.attributes = _.extend({}, properties.defaults, arguments.attributes);
				}
			
			    if (_.has(options, 'collection')) 
			   		Model.collection = options.collection;

				_.extend(Model, Backbone.Events);

				_.bindAll(Model);

				if (_.has(attributes, 'id')) {
					Model.id = attributes.id;
					structDelete(attributes, 'id');
				}

				if (_.has(attributes, Model.idAttribute)) {
					Model.id = attributes[Model.idAttribute];
				}				

				Model.setMultiple(arguments.attributes, {silent: true});

				Model._previousAttributes = _.clone(arguments.attributes);

				Model.initialize(attributes);

				Model.cid = _.uniqueId('c');

				return Model;
			};
		},
		get: function (required string key) {
			if (this.has(key))
				return this.attributes[key];
		},
		escape: function (attr) {
			return _.escape(this.get(attr));
		},
		setMultiple: function (required struct attributes, struct options = {}) {
			// TODO: use Set() instead
			// TODO: handle options

			if (!this._validate(attributes, options))
				return false;

			_.each(attributes, function(val, key) {
				this.set(key, val, options);
			});

			return true;
		},
		set: function (required string key, required val, struct options = {}) {
			// TODO: handle collection
			// TODO: handle silent option
			// TODO: set up "changed" struct (see backbone.js Model.changed)
			var newAttributes = duplicate(this.attributes);
			newAttributes[key] = val;
			var isValid = this._validate(newAttributes, options);
			if (!isValid) {
				return false;
			}
			this.changedAttributes.changes[key] = true;
			this.change(this, val, this.changedAttributes);
			this.attributes[key] = val;
			return true;
		},
		has: function (required string attribute) {
			return _.has(this.attributes, attribute);
		},
		unset: function (required string key, struct options = { silent: false }) {
			if (!this.has(key)) 
				return;
			this.changedAttributes.changes[key] = true;
			var val = this.attributes[key];
			structDelete(this.attributes, key);
			if (!options.silent) 
				this.change(this, val, this.changedAttributes);
		},
		clear: function (struct options = { silent: false }) {
			_.each(this.attributes, function (val, key) {
				this.unset(key, options);
			});
		},
		_validate: function (struct attributes, struct options = { silent:false }) {
			var silent = _.has(options, 'silent') && options.silent;
			if (silent || !_.has(this, 'validate'))
				return true;
			var attrs = _.extend({}, this.attributes, arguments.attributes);
			var error = this.validate(attrs, options);
			if (!error) 
				return true;
			if (_.has(options, 'error')) {
				options.error(this, error, options);
			} 
			else {
				this.trigger('error', this, error, options);
			}
			return false;
		},
		isValid: function () {
			return isNull(this.validate(this.attributes));
		},
		previous: function(required attr) {
			if (!_.has(this._previousAttributes, attr))
				return;
			else
				return this._previousAttributes[attr];
		},
		previousAttributes: function() {
			return _.clone(this._previousAttributes);
	    },
		change: function (required struct model, required val, struct changedAttributes) {
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
		},
		fetch: function (struct options = {}) {
			if (!_.has(options, 'parse'))
				options.parse = true;
			var model = this;
			if (!_.has(options, 'success'))
				options.success = function () {};
			var success = options.success;
			options.success = function(resp, status, xhr) {
				if (!model.setMultiple(model.parse(resp, xhr), options)) 
					return false;
				success(model, resp);
			};
			var result = Backbone.Sync('read', model, options);
		},
		parse: function(resp, xhr) {
			return resp;
	    },
	    url: function() {
	    	if (_.has(this, 'urlRoot'))
	    		var base = _.result(this, 'urlRoot');
	    	else if (_.has(this, 'collection') && _.has(this.collection, 'url'))
	    		var base = _.result(this.collection, 'url');
	    	else
				throw('A "url" property or function must be specified', 'Backbone');
			if (this.isNew()) 
				return base;
			return base & (right(base, 1) == '/' ? '' : '/') & urlEncodedFormat(this.id);
		},
		isNew: function () {
			// TODO: implement this
			return false;
		}
	};

	Backbone.Collection = {
		initialize: function () {},
		Model: Backbone.Model.extend(),
		models: [],
		extend: function (struct properties = {}) {
			return function (models = [], options = {}) {
				var Collection = duplicate(Backbone.Collection);

				_.extend(Collection, properties);

				_.extend(Collection, Backbone.Events);

				if (_.has(options, 'comparator')) 
					Collection.comparator = options.comparator;


				// methods we want to implement from Underscore
				var methods = ['forEach', 'each', 'map', 'reduce', 'reduceRight', 'find',
				    'detect', 'filter', 'select', 'reject', 'every', 'all', 'some', 'any',
				    'include', 'invoke', 'max', 'min', 'sortBy', 'sortedIndex',
				    'toArray', 'size', 'first', 'initial', 'rest', 'last', 'without', 'indexOf',
				    'shuffle', 'lastIndexOf', 'isEmpty', 'groupBy'];
				_.each(methods, function(method) {
					Collection[method] = function () {
						var Underscore = new github.UnderscoreCF.Underscore(this.models);
						var func = _.bind(Underscore[method], Underscore);
						return func(argumentCollection = arguments);
					};
				});

				_.bindAll(Collection);

				Collection._reset();

				Collection.models = models;

				Collection.initialize(argumentCollection = arguments);

				if (_.size(models) > 0) {
					options.parse = _.has(options, 'parse') ? options.parse : Collection.parse;
					Collection.reset(models, {silent: true, parse: options.parse});
				}

				return Collection;
			};
		},
		toJSON: function () {
			var result = _.map(this.models, function(model) {
				return model.toJSON();
			});
			return result;
		},
		add: function (array models = [], struct options = {}) {
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
		remove: function (array models = [], struct options = {}) {
			this.models = _.without(this.models, models);
			// TODO: events
		},
		get: function (required string id) {
			return _.find(this.models, function(model) {
				return _.has(model, 'id') && model.id == id;
			});
		},
		getByCid: function (required string cid) {
			return _.find(this.models, function(model) {
				return model.cid == cid;
			});
		},
		at: function (required numeric index) {
			return this.models[index];
		},
		push: function (required struct model, struct options = {}) {
			ArrayAppend(this.models, model);
			// TODO: trigger event, handle options
		},
		pop: function (struct options = {}) {
			var result = _.last(this.models);
			this.remove([result]);
			return result;
		},
		unshift: function (required struct model, struct options = {}) {
			ArrayPrepend(this.models, model);
			// TODO: events and options
		},
		shift: function (struct options = {}) {
			var result = _.first(this.models);
			this.remove([result]);
			return result;
			// TODO: options
		},
		length: function () {
			return _.size(this.models);
		},
		sort: function (struct options = {}) {
			if (_.has(this, 'comparator'))
				this.models = _.sortBy(this.models, this.comparator);
			else 
				throw('Cannot sort a set without a comparator', 'Backbone');
			// TODO: options and "reset" event
		},
		pluck: function (required struct attribute) {
			return _.map(this.models, function(model) {
				return model.get(attribute);				
			});
		},
		where: function (required struct attributes) {
			return _.filter(this.models, function(model) {
				var result = true;
				_.each(attributes, function(val, key){
					if(!model.get(key) == val) 
						result = false;
				});
				return result;
			});
		},
		fetch: function (struct options = {}) {
			if (!_.has(options, 'parse'))
				options.parse = true;
			var collection = this;
			if (!_.has(options, 'success'))
				options.success = function () {};
			var success = options.success;
			options.success = function(resp, status, xhr) {
				var func = collection[_.has(options, 'add') ? 'add' : 'reset'];
				func(collection.parse(resp, xhr), options);
				success(collection, resp);
			};
			var result = Backbone.Sync('read', collection, options);
		},
		reset: function (array models = [], struct options = {}) {
			this._reset();
			this.add(models);
			// TODO: options and events
		},
		_reset: function(struct options = {}) {
			this.models = [];
			this._byId  = {};
			this._byCid = {};
		},
		create: function (struct attributes = {}, struct options = {}) {
			var newModel = this.Model(argumentCollection = arguments);
			this.add([newModel]);
			return newModel;
			// TODO: options and events
		},
		parse: function(resp, xhr) {
			return resp;
		},
		length: function () {
			return _.size(this.models);
		}
	};

	Backbone.View = {
		extend: function (struct obj = {}) {
			return function (struct options = {}) {
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
		make: function(required string tagName, struct attributes = {}, string content = '') {
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
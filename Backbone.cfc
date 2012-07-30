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
		_callbacks: {},
		on: function (required string eventName, required callback, context = {}) {
			var event = listFirst(eventName, ":");
			var attribute = listLast(eventName, ":");

			if (!_.has(this._callbacks, eventName))
				this._callbacks[eventName] = [];

			if (!_.isEmpty(context))
				callback = _.bind(callback, context);

			// TODO: allow callback to be referenced by name or something so off() can remove it specifically
			ArrayAppend(this._callbacks[eventName], callback);

			return this;
		},
		off: function (required string eventName, callback, context) {
			if (_.has(this._callbacks, eventName)) {
				structDelete(this._callbacks, eventName);
			}
			return this;
		},
		trigger: function (required string eventName, struct model, val, struct changedAttributes) {
			// TODO: handle list of events
			if (_.has(this._callbacks, eventName)) {
				var funcsArray = this._callbacks[eventName];
				_.each(funcsArray, function (func) {
					func(model, val, changedAttributes);
				});
			}
			return this;
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
		idAttribute: 'id',
		new: function (struct attributes = {}, struct options = {}) {
			// convenience method. equivalent to: new Backbone.Model(); in BackboneJS
			var BackboneModel = Backbone.Model.extend();
			return BackboneModel(attributes, options);
		},
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
			if (this.idAttribute == key) {
				if (_.has(this, 'collection')) {
					// update collection
					var oldKey = this[key];
					var collection = this.collection();
					if (_.has(collection, '_byId')) {
						StructDelete(collection._byId, oldKey);
						collection._byId[val] = this;
					}
				}
				this[key] = val;
			}
			else {
				this.attributes[key] = val;
			}
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
		length: 0,
		new: function (array models = [], options = {}) {
			// convenience method, equivalent to: new Backbone.Collection(models, options) in BackboneJS
			var NewCollection = Backbone.Collection.extend();
			return NewCollection(models, options);
		},
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
		add: function (any models = [], struct options = {}) {
			// TODO test this method
			var dups = [];
			var cids = {};
			var ids = {};
			if (isStruct(models)) {
				// wrap non-array model input in an array
				arguments.models = [arguments.models];
			}
			if (_.isFunction(models)) {
				arguments.models = [models()];
			}
			if (!isArray(arguments.models)) {
				arguments.models = _.toArray(models);
			}
			for (var i = 1; i <= arrayLen(models); i++) {
				model = models[i];
				var model = this._prepareModel(model);
				if (!isStruct(model)) {
					throw("Can't add an invalid model to a collection", "Backbone");
				}
				models[i] = model;
				var cid = model.cid;
				if (_.has(model, 'id')) 
					var id = model.id;
 		        if (_.has(cids, cid) || _.has(this._byCid, cid) || (
		        	(!isNull(id) && (_.has(ids, id) || _.has(this._byId, id))))) {
					ArrayAppend(dups, i);
					continue;
		        }
		        cids[cid] = model;
		        if (!isNull(id))
			        ids[id] = model;
			}

			// Remove duplicates.
			var i = ArrayLen(dups);
			while (i--) {
				ArrayDeleteAt(models, dups[i]);
			}

			// Listen to added models' events, and index models for lookup by id and by cid.
			for (i = 1; i <= arrayLen(models); i++) {
				var model = models[i];
				model.on('all', this._onModelEvent, this);
				this._byCid[model.cid] = model;
				if (_.has(model, 'id')) 
					this._byId[model.id] = model;
			}

			// Insert models into the collection, re-sorting if needed, and triggering add events unless silenced.
			this.length += arrayLen(models);
			var index = _.has(options, 'at') ? options.at : arrayLen(this.models) + 1;
			this.models = _.splice(this.models, index, 0, models);
			if (_.has(this, 'comparator')) 
				this.sort({silent: true});
			if (_.has(options, 'silent') && options.silent) 
				return this;
			for (i = 1; i <= arrayLen(this.models); i++) {
				var model = this.models[i];
				if (!_.has(cids, model.cid)) 
					continue;
				options.index = i;
				model.trigger('add', model, this, options);
			}
			return this;			
			// ArrayAppend(this.models, backboneModel);
		},
		remove: function(any models = [], struct options = {}) {
			arguments.models = _.isArray(models) ? models : [models];
			for (var i = 1; i <= ArrayLen(models); i++) {
				if (!isNull(this.getByCid(models[i])))
					var model = this.getByCid(models[i]);
				else if (!isNull(this.get(models[i])))
					var model = this.get(models[i]);
				if (isNull(model)) 
					continue;
				if (_.has(model, 'id'))
					StructDelete(this._byId, model.id);	
				this.length--;
				if (_.has(options, 'silent') && options.silent) {
					options.index = this.indexOf(model);
					model.trigger('remove', model, this, options);
				}
				this._removeReference(model);
			}
			return this;
		},
		get: function (required any id) {
			if (isStruct(arguments.id) && _.has(arguments.id, 'id')) {
				return this._byId[arguments.id.id];
			}
			else if (isSimpleValue(arguments.id) && _.has(this._byId, arguments.id)) {
				// writeDump(this._byId[arguments.id]);
				return this._byId[arguments.id];
			}
			else {
				writeDump(arguments);
				throw("Collection does not have model with specified ID " & id, "Backbone");
			}
		},
		getByCid: function (required any cid) {
			if (isStruct(arguments.cid) && _.has(cid, 'cid')) {
				return this._byCid[arguments.cid.cid];
			}
			else if (isSimpleValue(arguments.cid) && _.has(this._byCid, arguments.cid)) {
				return this._byCid[arguments.cid];
			}
			else {
				throw("getByCid() requires either a struct with a cid attribute or a cid string.", "Backbone");
			}
		},
		at: function (required numeric index) {
			return this.models[index];
		},
		push: function (required struct model, struct options = {}) {
			arguments.model = this._prepareModel(arguments.model, options);
			this.add([arguments.model], options);
			return arguments.model;
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
		sort: function (struct options = {}) {
			if (_.has(this, 'comparator')) {
				var Underscore = duplicate(_);
				Underscore.comparison = this.comparator;
				this.models = Underscore.sortBy(this.models);
			}
			else 
				throw('Cannot sort a set without a comparator', 'Backbone');
			// TODO: options and "reset" event
		},
		pluck: function (required string attribute) {
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
			for (var i = 1; i <= ArrayLen(this.models); i++) {
				this._removeReference(this.models[i]);
			}
			this._reset();
			this.add(models, _.extend({silent: true}, options));
			if (_.has(options, 'silent') && !options.silent) 
				this.trigger('reset', this, options);
			return this;
		},
		_reset: function(struct options = {}) {
			this.models = [];
			this._byId  = {};
			this._byCid = {};
		},
		_prepareModel: function(required struct model, struct options = {}) {
			// TODO: fix circular reference to collection (maybe write getCollection() ?)
			// TODO: improve model check to ensure correct type of model
			if (!(_.has(model, 'cid'))) {
				var attrs = model;
				options.collection = _.bind(function () { return this; }, this);
				model = this.Model(attrs, options);
				if (!model._validate(model.attributes, options)) 
					model = false;
			} 
			else if (!_.has(model, 'collection')) {
				model.collection = _.bind(function () { return this; }, this);
			}
			return model;
	    },
	    // Internal method to remove a model's ties to a collection.
	    _removeReference: function(required model) {
			if (_.has(model, 'collection') && _.isEqual(this, model.collection)) {
				structDelete(model, 'collection');
			}
			if (_.has(model, 'off'))
				model.off('all', this._onModelEvent, this);
		},
		// Internal method called every time a model in the set fires an event. Sets need to update their indexes when models change ids. All other events simply proxy through. "add" and "remove" events that originate in other collections are ignored.
		_onModelEvent: function(required string event, required struct model, required struct collection, options = {}) {
			if ((event == 'add' || event == 'remove') && !_.isEqual(collection, this)) 
				return;
			if (event == 'destroy') {
				this.remove(model, options);
			}
			if (model && event == 'change:' + model.idAttribute) {
				StructDelete(this._byId, model.previous(model.idAttribute));
				this._byId[model.id] = model;
			}
			this.trigger.apply(this, arguments);
		},
		create: function (struct attributes = {}, struct options = {}) {
			var newModel = this.Model(argumentCollection = arguments);
			this.add([newModel]);
			return newModel;
			// TODO: options and events
		},
		parse: function(resp, xhr) {
			return resp;
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
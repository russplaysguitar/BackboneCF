component {

	public struct function init() {
		// requires the Underscore.cfc library
		variables._ = new github.UnderscoreCF.Underscore();

		// handles basic http requests
		variables.httpCFC = new Http();

		return Backbone;
	}

	Backbone = {
		// Turn on `emulateJSON` to support legacy servers that can't deal with direct
		// `application/json` requests ... will encode the body as
		// `application/x-www-form-urlencoded` instead and will send the model in a
		// form param named `model`.
		emulateJSON: false,
		// Turn on `emulateHTTP` to support legacy HTTP servers. Setting this option
		// will fake `"PUT"` and `"DELETE"` requests via the `_method` parameter and
		// set a `X-Http-Method-Override` header.
		emulateHTTP: false
	};

	// Wrap an optional error callback with a fallback error event.
	Backbone.wrapError = function(onError, required struct originalModel, struct options = {}) {
		var args = arguments;
		return function(required struct model, resp) {
			arguments.resp = _.isEqual(arguments.model, originalModel) && _.has(arguments, 'resp') ? arguments.resp : arguments.model;
			if (_.has(args, 'onError') && _.isFunction(args.onError)) {
				onError(originalModel, arguments.resp, args.options);
			} else {
				args.originalModel.trigger('error', args.originalModel, arguments.resp, args.options);
			}
		};
	};

	// Backbone.Events
	// A module that can be mixed in to *any object or struct* in order to provide it with
	// custom events. You may bind with `on` or remove with `off` callback functions
	// to an event; `trigger`-ing an event fires all callbacks in succession.
	//
	//     var object = {};
	//     _.extend(object, Backbone.Events);
	//     object.on('expand', function(){ writeOutput('expanded'); });
	//     object.trigger('expand');
	//
	Backbone.Events = {
		// Bind one or more space separated events, events, to a callback function. Passing "all" will bind the callback to all events fired.
		on: function (required string eventName, callback, context = {}) {

			if (!_.has(arguments, 'callback')) return this;

			// init _callbacks
			if (!_.has(this, '_callbacks')) {
				this._callbacks = {};
			}

			// handle multiple events
			var events = listToArray(eventName, " ");

			for (eventName in events) {
				if (!_.has(this._callbacks, eventName))
					this._callbacks[eventName] = [];

				var event = {
					callback: callback,
					ctx: function () { return context; }
				};

				ArrayAppend(this._callbacks[eventName], event);
			}

			return this;
		},
		// Remove one or many callbacks. If context is null, removes all callbacks with that function. If callback is null, removes all callbacks for the event. If events is null, removes all bound callbacks for all events.
		off: function (string eventName, callback, struct context) {

			// no callbacks defined
			if (!_.has(this, '_callbacks')) return this;

			// no arguments, delete all callbacks for this object
			if (!(_.has(arguments, 'eventName') || _.has(arguments, 'callback') || _.has(arguments, 'context'))) {
				structDelete(this, '_callbacks');
				return this;
			}

			// handle multiple events
			var events = _.has(arguments, 'eventName') ? listToArray(eventName, " ") : [];
			for (eventName in events) {
				if (_.has(this._callbacks, eventName)) {
					if (_.has(arguments, 'callback')) {
						// remove specific callback for event
						var args = arguments;
						var result = _.reject(this._callbacks[eventName], function (event) {
							if (_.has(args, 'context')) {
								var ctx = event.ctx();
								return event.callback.Equals(callback) && ctx.Equals(context);
							}
							else {
								return event.callback.Equals(callback);
							}
						});
						this._callbacks[eventName] = result;
					}
					else {
						// remove all callbacks for event
						structDelete(this._callbacks, eventName);
					}
				}
			}

			// remove all callbacks for context
			if (arrayLen(events) == 0 && _.has(arguments, 'context')) {
				var con = arguments.context;
				var result = _.map(this._callbacks, function(events) {
					return _.reject(events, function (event) {
						var ctx = event.ctx();
						return ctx.equals(con);
					});
				});
				this._callbacks = result;
			}

			// remove all matching callbacks
			if (arrayLen(events) == 0 && _.has(arguments, 'callback')) {
				var cb = arguments.callback;
				var result = _.map(this._callbacks, function(events) {
					return _.reject(events, function (event) {
						var callback = event.callback;
						return callback.equals(cb);
					});
				});
				this._callbacks = result;
			}

			return this;
		},
		// Trigger one or many events, firing all bound callbacks. Callbacks are passed the same arguments as trigger is, apart from the event name (unless you're listening on "all", which will cause your callback to receive the true name of the event as the first argument).
		trigger: function (required string eventName, struct model = this, val = '', struct changedAttributes = {}) {

			// no callbacks defined
			if (!_.has(this, '_callbacks')) return this;

			// handle multiple events
			var events = listToArray(eventName, " ");

			for (eventName in events) {
				var callbacks = duplicate(this._callbacks);

				if (_.has(callbacks, eventName) && eventName != 'all') {
					var evts = callbacks[eventName];
					_.each(evts, function (event) {
						var func = _.bind(event.callback, event.ctx());
						func(model, val, changedAttributes);
					});
				}
				if (_.has(callbacks, 'all') && eventName != 'all') {
					var evts = callbacks['all'];
					_.each(evts, function (event) {
						var func = _.bind(event.callback, event.ctx());
						func(eventName, model, val, changedAttributes);
					});
				}
			}

			return this;
		}
	};

	// Map from CRUD to HTTP for our default `Backbone.sync` implementation.
	variables.methodMap = {
		'create': 'POST',
		'update': 'PUT',
		'delete': 'DELETE',
		'read':   'GET'
	};
	// Override this function to change the manner in which Backbone persists
	// models to the server. You will be passed the type of request, and the
	// model in question. By default, makes a RESTful HTTP request
	// to the model's `url()`. 
	//
	// Turn on `Backbone.emulateHTTP` in order to send `PUT` and `DELETE` requests
	// as `POST`, with a `_method` parameter containing the true HTTP method,
	// as well as all requests with the body as `application/x-www-form-urlencoded`
	// instead of `application/json` with the model in a param named `model`.
	// Useful when interfacing with server-side languages like **PHP** that make
	// it difficult to read the body of `PUT` requests.
	Backbone.Sync = function (required string method, struct model, struct options = {}) {
		var type = methodMap[method];
	    // Default JSON-request options.
		var params = {type: type, dataType: 'json'};

		// Ensure that we have a URL.
		if (!_.has(options, 'url')) {
			if (!_.has(model, 'url'))
				throw('A "url" property or function must be specified', 'Backbone');
			params.url = _.result(model, 'url');
		}
	    // Ensure that we have the appropriate request data.
		if (!_.has(options, 'data') && _.has(arguments, 'model') && (method == 'create' || method == 'update')) {
			params.contentType = 'application/json';
			params.data = model.toJSON();
		}
	    // For older servers, emulate JSON by encoding the request into an HTML-form.
		if (Backbone.emulateJSON) {
			params.contentType = 'application/x-www-form-urlencoded';
			if (_.has(params, 'data'))
				params.data = {model: params.data};
			else
				params.data = {};
		}
		// For older servers, emulate HTTP by mimicking the HTTP method with `_method`
		// And an `X-HTTP-Method-Override` header.
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

		// ensure data parameter is at least an empty struct
		if (!_.has(params, 'data')) params.data = {};

		// Don't process data on a non-GET request.
		if (params.type != 'GET' && !Backbone.emulateJSON) {
			params.processData = false;
		}

		// Make the request, allowing the user to override any http request options.
		return Backbone.ajax(argumentCollection = _.extend(params, options));
	};

	// default implementation uses HTTP.cfc to make RESTful requests
	Backbone.ajax = function () {
		return httpCFC.request(argumentCollection = arguments);
	};

	Backbone.Model = {
		initialize: function () {},// Initialize is an empty function by default. Override it with your own initialization logic.
		attributes: {},
		defaults: {},
		_escapedAttributes: {},
		_silent: {},// A hash of attributes that have silently changed since the last time `change` was called.  Will become pending attributes on the next call.
		_pending: {},// A hash of attributes that have changed since the last `'change'` event began.
		_changing: false,
		changed: {},// A hash of attributes whose current and previous value differ.
		idAttribute: 'id',// The default name for the JSON `id` attribute is `"id"`. MongoDB and CouchDB users may want to set this to `"_id"`.
		// Create a new model, with defined attributes. A client id (`cid`) is automatically generated and assigned for you. Equivalent to: new Backbone.Model(); in BackboneJS
		new: function (struct attributes = {}, struct options = {}) {
			var BackboneModel = Backbone.Model.extend();
			return BackboneModel(attributes, options);
		},
		// Returns a function that generates a new instance of the Model. 
		extend: function (struct properties = {}) {
			return function (struct attributes = {}, struct options = {}) {
				var Model = duplicate(Backbone.Model);

				_.extend(Model, properties);

				if (_.has(options, 'collection')) Model.collection = options.collection;
			   		// Model.collection = function () { return options.collection; };

			   	if (_.has(options, 'parse'))
			   		arguments.attributes = Model.parse(arguments.attributes);

				if (_.has(properties, 'defaults')) {
					var defaults = _.result(properties, 'defaults');
					arguments.attributes = _.extend({}, defaults, arguments.attributes);
				}

				_.extend(Model, duplicate(Backbone.Events));

				_.bindAll(Model);

				Model.set(arguments.attributes, {silent: true});

				// Reset change tracking.
				Model.changed = {};
				Model._silent = {};
				Model._pending = {};

				Model._previousAttributes = _.clone(arguments.attributes);

				Model.initialize(attributes, options);

				Model.cid = _.uniqueId('c');
				return Model;
			};
		},
	    // Get the value of an attribute, if it exists.
		get: function (required string attr) {
			if (this.has(attr)) return this.attributes[attr];
		},
	    // Get the HTML-escaped value of an attribute.
		escape: function (required string attr) {
			if (!this.has(attr)) return '';
			var result = _.escape(this.get(attr));
			this._escapedAttributes[attr] = result;
			return result;
		},
	    // Set a hash of model attributes on the object, firing `"change"` unless you choose to silence it.
		set: function (required any key, value = '', struct options = {}) {
			// Handle both "key", value and {key: value} -style arguments.
			if (isStruct(key)) {
				var attrs = key;
				if (isStruct(arguments.value))
					arguments.options = arguments.value;
			} else {
				var attrs = {};
				attrs[key] = arguments.value;
			}

			// Extract attributes and options.
			options.unset = _.has(arguments.options, 'unset') ? options.unset : false;
			options.silent = _.has(arguments.options, 'silent') ? options.silent : false;
			if (_.has(attrs, 'cid')) attrs = attrs.attributes;// attrs is a Backbone Model already

			// Run validation
			if (options.unset) for (attr in attrs) attrs[attr] = '';
			if (!this._validate(attrs, options)) return false;

			// Check for changes of id.
			if (_.has(attrs, this.idAttribute)) { this.id = attrs[this.idAttribute]; }

			options.changes = _.has(options, 'changes') ? options.changes : {};
			var now = this.attributes;
			var escaped = this._escapedAttributes;
			var prev = _.has(this, '_previousAttributes') ? this._previousAttributes : {};

			// For each `set` attribute...
			for (attr in attrs) {
				var val = attrs[attr];

				// If the new and current value differ, record the change.
				var nowAttr = _.has(now, attr) ? now[attr] : '';
				if ((!_.isEqual(nowAttr, val))
					|| (options.unset && _.has(now, attr))) {
					structDelete(escaped, attr);
					if (options.silent)
						this._silent[attr] = true;
					else
						options.changes[attr] = true;
				}

				// Update or delete the current value.
				if (options.unset)
					structDelete(now, attr);
				else
					now[attr] = val;

				// If the new and previous value differ, record the change. If not, then remove changes for this attribute.
				if ((_.has(prev, attr) && !_.isEqual(prev[attr], val)) ||
					(_.has(now, attr) != _.has(prev, attr))) {
					this.changed[attr] = val;
					if (!options.silent) this._pending[attr] = true;
				} else {
					structDelete(this.changed, attr);
					structDelete(this._pending, attr);
				}
			}

			// Fire the "change" events.
			if (!options.silent) this.change(options);

			return this;
		},
	    // Returns `true` if the attribute structKeyExists.
		has: function (required string attribute) {
			return _.has(this.attributes, attribute);
		},
	    // Remove an attribute from the model, firing `"change"` unless you choose to silence it. `unset` is a noop if the attribute doesn't exist.
		unset: function (required string key, struct options = {}) {
			var opts = _.extend({}, arguments.options, { unset: true });
			return this.set(key = arguments.key, options = opts);
		},
		// Clear all attributes on the model, firing `"change"` unless you choose to silence it.
		clear: function (struct options = {}) {
			arguments.options = _.extend({}, arguments.options, {unset: true});
			return this.set(_.clone(this.attributes), options);
		},
		// Destroy this model on the server if it was already persisted.
		// Optimistically removes the model from its collection, if it has one.
		// If `wait: true` is passed, waits for the server to respond before removal.
		destroy: function (struct options = {}) {
			var model = this;
			var nullFunction = function () {};
			var success = _.has(options, 'success') ? options.success : nullFunction;

			var destroy = function() {
				var collection = _.has(model, 'collection') ? model.collection() : {};
				model.trigger('destroy', model, collection, options);
			};

			options.wait = _.has(options, 'wait') ? options.wait : false;
			options.error = _.has(options, 'error') ? options.error : false;

			options.success = function(resp = '') {
				if (options.wait || model.isNew()) destroy();
				success(model, resp, options);
				if (!model.isNew()) model.trigger('sync', model, resp, options);
			};

			if (this.isNew()) {
				options.success();
				return false;
			}

			options.error = Backbone.wrapError(options.error, model, options);
			var xhr = this.sync('delete', this, options);
			if (!options.wait) destroy();
			if (!isNull(xhr)) return xhr;
		},
	    // Run validation against the next complete set of model attributes,
		// returning `true` if all is well. If a specific `error` callback has
		// been passed, call that instead of firing the general `"error"` event.
		_validate: function (required struct attributes, struct options = { silent:false }) {
			var silent = _.has(options, 'silent') && options.silent;
			if (silent || !_.has(this, 'validate'))
				return true;
			var attrs = _.extend({}, this.attributes, arguments.attributes);
			var error = this.validate(argumentCollection = {attrs: attrs, options: options, this: this});
			if (isNull(error))
				return true;
			if (_.has(options, 'error')) {
				options.error(this, error, options);
			}
			else {
				this.trigger('error', this, error, options);
			}
			return false;
		},
		// Check if the model is currently in a valid state. It's only possible to get into an *invalid* state if you're using silent changes.
		isValid: function () {
			if (!_.has(this, 'validate')) return true;
			return isNull(this.validate(argumentCollection = {attrs: this.attributes, this: this}));
		},
	    // Get the previous value of an attribute, recorded at the time the last `"change"` event was fired.
		previous: function(required string attr) {
			if (!_.has(this._previousAttributes, attr))
				return;
			else
				return this._previousAttributes[attr];
		},
	    // Get all of the attributes of the model at the time of the previous `"change"` event.
		previousAttributes: function() {
			return _.clone(this._previousAttributes);
		},
		// Call this method to manually fire a "change" event for this model and a "change:attribute"
		//  event for each changed attribute. Calling this will cause all objects observing the model to update.
		change: function (options = {}) {
			var changing = this._changing;
			this._changing = true;

			options.changes = _.has(options, 'changes') ? options.changes : {};

			// Silent changes become pending changes.
			for (var attr in this._silent) this._pending[attr] = true;

			// Silent changes are triggered.
			var changes = _.extend({}, options.changes, this._silent);
			this._silent = {};
			for (var attr in changes) {
				if (!isNull(this.get(attr)))
					var val = this.get(attr);
				else
					var val = '';
				this.trigger('change:' & attr, this, val, options);
			}
			if (changing) return this;

			// Continue firing "change" events while there are pending changes.
			while (!_.isEmpty(this._pending)) {
				this._pending = {};
				this.trigger('change', this, options);

				// Pending and silent changes still remain.
				for (var attr in this.changed) {
					if (_.has(this._pending, attr) || _.has(this._silent, attr)) continue;
					structDelete(this.changed, attr);
				}
				this._previousAttributes = _.clone(this.attributes);
			}

			this._changing = false;
			return this;
		},
		// Determine if the model has changed since the last `"change"` event.
		// If you specify an attribute name, determine if that attribute has changed.
		hasChanged: function(attr) {
			if (!structKeyExists(arguments, 'attr')) return !_.isEmpty(this.changed);
			return _.has(this.changed, attr);
		},
		// Return an object containing all the attributes that have changed, or
		// false if there are no changed attributes. Useful for determining what
		// parts of a view need to be updated and/or what attributes need to be
		// persisted to the server. Unset attributes will be set to undefined.
		// You can also pass an attributes object to diff against the model,
		// determining if there *would be* a change.
		changedAttributes: function(diff) {
			if (!structKeyExists(arguments, 'diff')) return this.hasChanged() ? _.clone(this.changed) : false;
			var val = '';
			var changed = {};
			var old = this._previousAttributes;
			for (var attr in diff) {
				val = diff[attr];
				if (_.isEqual(old[attr], val)) continue;
				changed[attr] = val;
			}
			return changed;
		},
	    // Return a JSON-serialized string of the model's `attributes` object.
		toJSON: function () {
			return serializeJSON(this.attributes);
		},
		// Proxy `Backbone.sync` by default.
		sync: function() {
			return Backbone.sync(argumentCollection = arguments);
		},
	    // Create a new model with identical attributes to this one.
		clone: function () {
			return this.new(this.attributes);
		},
		// Fetch the model from the server. If the server's representation of the
		// model differs from its current attributes, they will be overriden,
		// triggering a `"change"` event.
		fetch: function (struct options = {}) {
			if (!_.has(options, 'parse'))
				options.parse = true;
			var model = this;
			if (!_.has(options, 'success'))
				options.success = function () {};
			var success = options.success;
			options.success = function(resp = '', status, xhr = '') {
				var setResult = model.set(model.parse(resp, xhr), options);
				if (isBoolean(setResult) && !setResult)
					return false;
				success(model, resp, options);
				model.trigger('sync', model, resp, options);
			};
			var result = this.Sync('read', model, options);
			if (!isNull(result)) return result;
		},
		// Set a hash of model attributes, and sync the model to the server.
		// If the server returns an attributes hash that differs, the model's
		// state will be `set` again.
		save: function(key = '', value = '', struct options) {
			var done = false;

			// Handle both `("key", value)` and `({key: value})` -style calls.
			if (!_.isString(key)) {
				var attrs = key;
				arguments.options = isStruct(value) ? value : {};
			} else {
				var attrs = {};
				if (key != '' && !isNull(value))
					attrs[key] = value;
			}
			arguments.options = _.has(arguments, 'options') ? _.clone(options) : {};
			arguments.options.wait = _.has(arguments.options, 'wait') ? arguments.options.wait : false;

			// If we're "wait"-ing to set changed attributes, validate early.
			if (options.wait) {
				if (!this._validate(attrs, options)) return false;
				var current = _.clone(this.attributes);
			}

			// Regular saves `set` attributes before persisting to the server.
			var silentOptions = _.extend({}, options, {silent: true});
			var attrsIsntNull = !_.isEmpty(attrs);
			var opts = options.wait ? silentOptions : options;
			if (attrsIsntNull && !isStruct(this.set(attrs, opts))) {
				return false;
			}

			// Do not persist invalid models.
			if (!attrsIsntNull && !this.isValid()) return false;

			// After a successful server-side save, the client is (optionally)
			// updated with the server-side state.
			var model = this;
			var nullSuccess = function () {};
			var success = _.has(options, 'success') ? options.success : nullSuccess;
			options.success = function(resp = '', status, xhr = '') {
				done = true;
				var serverAttrs = model.parse(resp, xhr);
				var atts = isStruct(attrs) ? attrs : {};
				if (options.wait) serverAttrs = _.extend(atts, serverAttrs);
				var setResult = model.set(serverAttrs, options);
				if (isBoolean(setResult) && !setResult) return false;
				success(model, resp, options);
				model.trigger('sync', model, resp, options);
			};

			// Finish configuring and sending the http request.
			options.error = _.has(options, 'error') ? options.error : false;
			options.error = Backbone.wrapError(options.error, model, options);
			var method = this.isNew() ? 'create' : 'update';
			var xhr = this.sync(method, model, options);

			// When using `wait`, reset attributes to original values unless
			// `success` has been called already.
			if (!done && options.wait) {
				this.clear(silentOptions);
				if (!isNull(current)) this.set(current, silentOptions);
			}

			if (!isNull(xhr)) return xhr;
		},
		// **parse** converts a response into the hash of attributes to be `set` on
		// the model. The default implementation is just to pass the response along.
		parse: function(resp, xhr) {
			return resp;
		},
		// Default URL for the model's representation on the server -- if you're
		// using Backbone's restful methods, override this to change the endpoint
		// that will be called.
		url: function() {
			if (_.has(this, 'urlRoot'))
				var base = _.result(this, 'urlRoot');
			else if (_.has(this, 'collection') && _.has(this.collection(), 'url'))
				var base = _.result(this.collection(), 'url');
			else
				throw('A "url" property or function must be specified', 'Backbone');
			if (this.isNew())
				return base;
			return base & (right(base, 1) == '/' ? '' : '/') & urlEncodedFormat(this.id);
		},
		// A model is new if it has never been saved to the server, and lacks an id.
		isNew: function () {
			return isNull(this.id) || this.id == '';
		}
	};
	// Backbone.Collection
	// Provides a standard collection class for our sets of models, ordered
	// or unordered. If a `comparator` is specified, the Collection will maintain
	// its models in sort order, as they're added and removed.
	Backbone.Collection = {
		initialize: function () {},// Initialize is an empty function by default. Override it with your own initialization logic.
		Model: Backbone.Model.extend(),// The default model for a collection is just a **Backbone.Model**. This should be overridden in most cases.
		models: [],
		length: function () {
			return arrayLen(this.models);
		},
		// Returns a new Collection. Equivalent to: new Backbone.Collection(models, options) in BackboneJS
		new: function (array models = [], options = {}) {
			var NewCollection = Backbone.Collection.extend();
			return NewCollection(models, options);
		},
		// Returns a function that creates new instances of this Collection.
		extend: function (struct properties = {}) {
			return function (models = [], options = {}) {
				var Collection = duplicate(Backbone.Collection);

				_.extend(Collection, duplicate(Backbone.Events));

				// TODO: make these work better, possibly by using proxies
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

				_.extend(Collection, properties);

				if (_.has(options, 'model')) Collection.model = options.model;

				if (_.has(options, 'comparator')) Collection.comparator = options.comparator;

				if (_.has(Collection, 'comparator'))
					Collection.comparatorMetaData = getMetaData(Collection.comparator);

				_.bindAll(Collection);

				Collection._reset();

				Collection.models = models;

				Collection.initialize(argumentCollection = arguments);

				Collection.cid = _.uniqueId('c');// not in Backbone.js, but useful for equality testing

				if (_.size(models) > 0) {
					options.parse = _.has(options, 'parse') ? options.parse : Collection.parse;
					Collection.reset(models, {silent: true, parse: options.parse});
				}


				return Collection;
			};
		},
	    // The JSON representation of a Collection is an array of the models' attributes.
		toJSON: function () {
			var result = '[';
			_.each(this.models, function(model, i) {
				result &= model.toJSON();
				if (i < arrayLen(this.models))
					result &= ',';
			});
			result &= ']';
			return result;
		},
		// Add a model, or list of models to the set. Pass **silent** to avoid
		// firing the `add` event for every new model.
		add: function (any models = [], struct options = {}) {
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
			// Begin by turning bare objects into model references, and preventing invalid models or duplicate models from being added.
			for (var i = 1; i <= arrayLen(models); i++) {
				model = models[i];
				var model = this._prepareModel(model, options);
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
			var i = ArrayLen(dups) + 1;
			while (i-- > 1) {
				var idx = dups[i];
				dups[i] = models[dups[i]];// replace index with model for duplicate merge
				models = _.splice(models, idx, 1);
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
			var index = _.has(options, 'at') ? options.at : arrayLen(this.models) + 1;
			this.models = _.splice(this.models, index, 0, models);

			// Merge in duplicate models.
			if (_.has(options, 'merge') && options.merge) {
				for (var i = 1; i <= arraylen(dups); i++) {
					if (_.has(dups[i], 'id') && _.has(this._byId, dups[i].id)) {
						var model = this._byId[dups[i].id];
						model.set(dups[i], options);
					}
				}
			}

			if (_.has(this, 'comparator') && !_.has(options, 'at'))
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
		},
	    // Remove a model, or a list of models from the set. Pass silent to avoid firing the `remove` event for every model removed.
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
				StructDelete(this._byCid, model.cid);
				var index = this.indexOf(item = model);
				this.models = _.splice(this.models, index, 1);
				if (!_.has(options, 'silent') || !options.silent) {
					options.index = index;
					model.trigger('remove', model, this, options);
				}
				this._removeReference(model);
			}
			return this;
		},
	    // Get a model from the set by id.
		get: function (required any id) {
			// arguments.id can either be an id or a structure with an id (confusing, I know)
			if (isStruct(arguments.id) && _.has(arguments.id, 'id')) {
				return this._byId[arguments.id.id];
			}
			else if (isSimpleValue(arguments.id) && _.has(this._byId, arguments.id)) {
				return this._byId[arguments.id];
			}
		},
		// Get a model from the set by client id.
		getByCid: function (required any cid) {
			// arguments.cid can either be a cid or a structure with a cid (confusing, I know)
			if (isStruct(arguments.cid) && _.has(cid, 'cid') && _.has(this._byCid, arguments.cid.cid)) {
				return this._byCid[arguments.cid.cid];
			}
			else if (isSimpleValue(arguments.cid) && _.has(this._byCid, arguments.cid)) {
				return this._byCid[arguments.cid];
			}
		},
	    // Get the model at the given index.
		at: function (required numeric index) {
			return this.models[index];
		},
	    // Add a model to the end of the collection.
		push: function (required struct model, struct options = {}) {
			this.add(arguments.model, options);
			return arguments.model;
		},
	    // Remove a model from the end of the collection.
		pop: function (struct options = {}) {
			var result = _.last(this.models);
			this.remove([result], options);
			return result;
		},
	    // Add a model to the beginning of the collection.
		unshift: function (required struct model, struct options = {}) {
			arguments.model = this._prepareModel(arguments.model, options);
			this.add(arguments.model, _.extend({at: 1}, options));
			return model;
		},
	    // Remove a model from the beginning of the collection.
		shift: function (struct options = {}) {
			var result = _.first(this.models);
			this.remove([result], options);
			return result;
		},
		// Slice out a sub-array of models from the collection.
		slice: function(required numeric begin, required numeric end) {
			return _.slice(this.models, begin, end);
		},
		// Force the collection to re-sort itself. You don't need to call this under
		// normal circumstances, as the set will maintain sort order as each item
		// is added.
		sort: function (struct options = {}) {
			if (!_.has(this, 'comparator'))
				throw('Cannot sort a set without a comparator', 'Backbone');

			// TODO: make this cooler. this is kindof a lame hack.
			if (!_.has(this, 'comparatorMetaData'))
				this.comparatorMetaData = getMetaData(this.comparator);

			var boundComparator = _.bind(this.comparator, this);

			if (arrayLen(this.comparatorMetaData.parameters) == 1)
				this.models = _.sortBy(this.models, boundComparator);
			else
				arraySort(this.models, boundComparator);

			if (!_.has(options, 'silent') || !options.silent) this.trigger('reset', this, options);

			return this;
		},
		// Pluck an attribute from each model in the collection.
		pluck: function (required string attribute) {
			return _.map(this.models, function(model) {
				return model.get(attribute);
			});
		},
	    // Return models with matching attributes. Useful for simple cases of `filter`.
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
		// Fetch the default set of models for this collection, resetting the
		// collection when they arrive. If `add: true` is passed, appends the
		// models to the collection instead of resetting.
		fetch: function (struct options = {}) {
			if (!_.has(options, 'parse'))
				options.parse = true;
			var collection = this;
			var nullFunc = function () {};
			options.success = _.has(options, 'success') ? options.success: nullFunc;
			var success = options.success;
			options.success = function(resp, status, xhr) {
				var addOrReset = collection[_.has(options, 'add') ? 'add' : 'reset'];
				addOrReset(collection.parse(resp, xhr), options);
				success(collection, resp, options);
				collection.trigger('sync', collection, resp, options);
			};
			options.error = _.has(options, 'error') ? options.error : false;
			options.error = Backbone.wrapError(options.error, collection, options);
			var result = Backbone.Sync('read', collection, options);
		},
		// When you have more items than you want to add or remove individually,
		// you can reset the entire set with a new list of models, without firing
		// any `add` or `remove` events. Fires `reset` when finished.
		reset: function (models = [], struct options = {}) {
			for (var i = 1; i <= ArrayLen(this.models); i++) {
				this._removeReference(this.models[i]);
			}
			this._reset();
			this.add(models, _.extend({silent: true}, options));
			if (!_.has(options, 'silent') || !options.silent)
				this.trigger('reset', this, options);
			return this;
		},
	    // Reset all internal state. Called when the collection is reset.
		_reset: function(struct options = {}) {
			this.models = [];
			this._byId  = {};
			this._byCid = {};
		},
	    // Prepare a model or hash of attributes to be added to this collection.
		_prepareModel: function(required struct model, struct options = {}) {
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
			if (_.has(model, 'collection') && this.cid == model.collection().cid) {
				structDelete(model, 'collection');
			}
			if (_.has(model, 'off')) {
				model.off('all', this._onModelEvent, this);
			}
		},
		// Internal method called every time a model in the set fires an event. Sets need to update their indexes when models change ids. All other events simply proxy through. "add" and "remove" events that originate in other collections are ignored.
		_onModelEvent: function(required string eventName, required struct model, collection, options = {}) {
			if ((eventName == 'add' || eventName == 'remove')) {
				var isEq = _.has(arguments, 'collection') && collection.cid == this.cid;
				if (!isEq)
					return;
			}
			if (eventName == 'destroy') {
				this.remove(model, options);
			}
			if (eventName == 'change:' & model.idAttribute) {
				StructDelete(this._byId, model.previous(model.idAttribute));
				this._byId[model.id] = model;
			}
			this.trigger(argumentCollection = {eventName: eventName, model:model, val: collection, changedAttributes: options});
		},
		// Create a new instance of a model in this collection. Add the model to the
		// collection immediately, unless `wait: true` is passed, in which case we
		// wait for the server to agree.
		create: function (struct attributes = {}, struct options = {}) {
			var coll = this;
			var model = this._prepareModel(attributes, options);
			if (!isStruct(model)) return false;
			if (!_.has(options, 'wait') || !options.wait) this.add(model, options);
			var success = _.has(options, 'success') ? options.success : false;
			options.success = function(model, resp, options) {
				if (_.has(options, 'wait') && options.wait) coll.add(model, options);
				if (_.isFunction(success)) success(model, resp, options);
			};
			model.save(options = options);
			return model;
		},
		// **parse** converts a response into the hash of attributes to be `set` on
		// the model. The default implementation is just to pass the response along.
		parse: function(resp, xhr) {
			return resp;
		}
	};


	Backbone.View = {
		// Create a new Backbone.View. Equivalent to: new Backbone.View(); in BackboneJS
		new: function (struct options = {}) {
			var BackboneView = Backbone.View.extend();
			return BackboneView(options);
		},
		// Returns a function that creates new instances of this view
		extend: function (struct obj = {}) {
			return function (struct options = {}) {
				var View = duplicate(Backbone.View);

				_.extend(options, obj);

				_.extend(View, obj);

				_.extend(View, duplicate(Backbone.Events));

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
		},
	    // The default `tagName` of a View's element is `"div"`.
		tagName: 'div',
		// For small amounts of elements, where a full-blown template isn't
		// needed, use **make** to manufacture elements, one at a time.
		//
		//     var el = this.make('li', {'class': 'row'}, this.model.escape('title'));
		//
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
		// Change the view's element (`this.el` property), including event re-delegation.
		setElement: function(element, delegate) {
			this.el = element;
			// TODO: something with delegate? or $el?
		},
		// Ensure that the View has an element to render into. Create
		// an element from the `id`, `className` and `tagName` properties.
		_ensureElement: function() {
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
		}
	};
}
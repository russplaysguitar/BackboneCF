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

	// Wrap an optional error callback with a fallback error event.
	Backbone.wrapError = function(onError, originalModel, options) {
		var args = arguments;
		return function(model, resp) {
			resp = _.isEqual(model, originalModel) ? resp : model;
			if (_.has(args, 'onError') && onError != '') {
				onError(originalModel, resp, options);
			} else {
				originalModel.trigger('error', originalModel, resp, options);
			}
		};
	};

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

		if (!_.has(params, 'data')) params.data = '';

		// Make the request, allowing the user to override any http request options.
		return Backbone.ajax(argumentCollection = _.extend(params, options));
	};

	Backbone.ajax = function () {
		return httpCFC.request(argumentCollection = arguments);
	};

	Backbone.Model = {
		initialize: function () {},
		attributes: {},
		defaults: {},
		_escapedAttributes: {},
		_silent: {},
		_pending: {},
		_changing: false,
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
		get: function (required string key) {
			if (this.has(key)) return this.attributes[key];
		},
		escape: function (attr) {
			var result = _.escape(this.get(attr));
			this._escapedAttributes[attr] = result;
			return result;
		},
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
		has: function (required string attribute) {
			return _.has(this.attributes, attribute);
		},
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
		destroy: function (options) {
			arguments.options = _.has(arguments, 'options') ? _.clone(arguments.options) : {};
			var model = this;
			var nullFunction = function () {};
			var success = _.has(options, 'success') ? options.success : nullFunction;

			var destroy = function() {
				var collection = _.has(model, 'collection') ? model.collection() : {};
				model.trigger('destroy', model, collection, options);
			};

			options.wait = _.has(options, 'wait') ? options.wait : false;
			options.error = _.has(options, 'error') ? options.error : '';

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
		_validate: function (struct attributes, struct options = { silent:false }) {
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
		isValid: function () {
			if (!_.has(this, 'validate')) return true;
			return isNull(this.validate(argumentCollection = {attrs: this.attributes, this: this}));
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
		toJSON: function () {
			return serializeJSON(this.attributes);
		},
		// Proxy `Backbone.sync` by default.
		sync: function() {
			return Backbone.sync(argumentCollection = arguments);
		},
		clone: function () {
			return this.new(this.attributes);
		},
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
			var defaultOnError = function () {};
			var err = _.has(options, 'error') ? options.error : defaultOnError;
			options.error = Backbone.wrapError(err, model, options);
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

	Backbone.Collection = {
		initialize: function () {},
		Model: Backbone.Model.extend(),
		models: [],
		length: function () {
			return arrayLen(this.models);
		},
		new: function (array models = [], options = {}) {
			// convenience method, equivalent to: new Backbone.Collection(models, options) in BackboneJS
			var NewCollection = Backbone.Collection.extend();
			return NewCollection(models, options);
		},
		extend: function (struct properties = {}) {
			return function (models = [], options = {}) {
				var Collection = duplicate(Backbone.Collection);

				_.extend(Collection, duplicate(Backbone.Events));

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
		get: function (required any id) {
			if (isStruct(arguments.id) && _.has(arguments.id, 'id')) {
				return this._byId[arguments.id.id];
			}
			else if (isSimpleValue(arguments.id) && _.has(this._byId, arguments.id)) {
				return this._byId[arguments.id];
			}
		},
		getByCid: function (required any cid) {
			// arguments.cid can either be a cid or a structure with a cid (confusing, I know)
			if (isStruct(arguments.cid) && _.has(cid, 'cid') && _.has(this._byCid, arguments.cid.cid)) {
				return this._byCid[arguments.cid.cid];
			}
			else if (isSimpleValue(arguments.cid) && _.has(this._byCid, arguments.cid)) {
				return this._byCid[arguments.cid];
			}
		},
		at: function (required numeric index) {
			return this.models[index];
		},
		push: function (required struct model, struct options = {}) {
			this.add(arguments.model, options);
			return arguments.model;
		},
		pop: function (struct options = {}) {
			var result = _.last(this.models);
			this.remove([result]);
			return result;
		},
		unshift: function (required struct model, struct options = {}) {
			arguments.model = this._prepareModel(arguments.model, options);
			this.add(arguments.model, _.extend({at: 1}, options));
			return model;
		},
		shift: function (struct options = {}) {
			var result = _.first(this.models);
			this.remove([result]);
			return result;
			// TODO: options
		},
		// Slice out a sub-array of models from the collection.
		slice: function(begin, end) {
			return _.slice(this.models, begin, end);
		},
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
		// Fetch the default set of models for this collection, resetting the
		// collection when they arrive. If `add: true` is passed, appends the
		// models to the collection instead of resetting.
		fetch: function (struct options = {}) {
			if (!_.has(options, 'parse'))
				options.parse = true;
			var collection = this;
			var nullFunc = function () {};
			if (!_.has(options, 'success'))
				options.success = nullFunc;
			var success = options.success;
			options.success = function(resp, status, xhr) {
				var func = collection[_.has(options, 'add') ? 'add' : 'reset'];
				func(collection.parse(resp, xhr), options);
				success(collection, resp, options);
				collection.trigger('sync', collection, resp, options);
			};
			options.error = _.has(options, 'error') ? options.error : nullFunc;
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
		_reset: function(struct options = {}) {
			this.models = [];
			this._byId  = {};
			this._byCid = {};
		},
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
		extend: function (struct obj = {}) {
			return function (struct options = {}) {
				var View = duplicate(Backbone.View);

				_.extend(View, obj);

				_.extend(View, duplicate(Backbone.Events));

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
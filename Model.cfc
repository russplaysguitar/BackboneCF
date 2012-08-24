component extends="Events" {
    this.initialize = function () {};// Initialize is an empty function by default. Override it with your own initialization logic.
    this.attributes = {};
    this.defaults = {};
    variables._escapedAttributes = {};
    variables._silent = {};// A hash of attributes that have silently changed since the last time `change` was called.  Will become pending attributes on the next call.
    variables._pending = {};// A hash of attributes that have changed since the last `'change'` event began.
    variables._changing = false;
    this.changed = {};// A hash of attributes whose current and previous value differ.
    this.idAttribute = 'id';// The default name for the JSON `id` attribute is `"id"`. MongoDB and CouchDB users may want to set this to `"_id"`.
	// Create a new model, with defined attributes. A client id (`cid`) is automatically generated and assigned for you. Equivalent to: new Backbone.Model(); in BackboneJS
    this.new = function (struct attributes = {}, struct options = {}) {
		var BackboneModel = new Model().extend();
		return BackboneModel(attributes, options);
	};
	// Returns a function that generates a new instance of the Model. 
    this.extend = function (struct properties = {}) {
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
	};
    // Get the value of an attribute, if it exists.
    this.get = function (required string attr) {
		if (this.has(attr)) return this.attributes[attr];
	};
    // Get the HTML-escaped value of an attribute.
    this.escape = function (required string attr) {
		if (!this.has(attr)) return '';
		var result = _.escape(this.get(attr));
		this._escapedAttributes[attr] = result;
		return result;
	};
    // Set a hash of model attributes on the object, firing `"change"` unless you choose to silence it.
    this.set = function (required any key, value = '', struct options = {}) {
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
	};
    // Returns `true` if the attribute structKeyExists.
    this.has = function (required string attribute) {
		return _.has(this.attributes, attribute);
	};
    // Remove an attribute from the model, firing `"change"` unless you choose to silence it. `unset` is a noop if the attribute doesn't exist.
    this.unset = function (required string key, struct options = {}) {
		var opts = _.extend({}, arguments.options, { unset: true });
		return this.set(key = arguments.key, options = opts);
	};
	// Clear all attributes on the model, firing `"change"` unless you choose to silence it.
    this.clear = function (struct options = {}) {
		arguments.options = _.extend({}, arguments.options, {unset: true});
		return this.set(_.clone(this.attributes), options);
	};
	// Destroy this model on the server if it was already persisted.
	// Optimistically removes the model from its collection, if it has one.
	// If `wait: true` is passed, waits for the server to respond before removal.
    this.destroy = function (struct options = {}) {
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
	};
    // Run validation against the next complete set of model attributes,
	// returning `true` if all is well. If a specific `error` callback has
	// been passed, call that instead of firing the general `"error"` event.
    variables._validate = function (required struct attributes, struct options = { silent:false }) {
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
	};
	// Check if the model is currently in a valid state. It's only possible to get into an *invalid* state if you're using silent changes.
    this.isValid = function () {
		if (!_.has(this, 'validate')) return true;
		return isNull(this.validate(argumentCollection = {attrs: this.attributes, this: this}));
	};
    // Get the previous value of an attribute, recorded at the time the last `"change"` event was fired.
    this.previous = function(required string attr) {
		if (!_.has(this._previousAttributes, attr))
			return;
		else
			return this._previousAttributes[attr];
	};
    // Get all of the attributes of the model at the time of the previous `"change"` event.
    this.previousAttributes = function() {
		return _.clone(this._previousAttributes);
	};
	// Call this method to manually fire a "change" event for this model and a "change:attribute"
	//  event for each changed attribute. Calling this will cause all objects observing the model to update.
    this.change = function (options = {}) {
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
	};
	// Determine if the model has changed since the last `"change"` event.
	// If you specify an attribute name, determine if that attribute has changed.
    this.hasChanged = function(attr) {
		if (!structKeyExists(arguments, 'attr')) return !_.isEmpty(this.changed);
		return _.has(this.changed, attr);
	};
	// Return an object containing all the attributes that have changed, or
	// false if there are no changed attributes. Useful for determining what
	// parts of a view need to be updated and/or what attributes need to be
	// persisted to the server. Unset attributes will be set to undefined.
	// You can also pass an attributes object to diff against the model,
	// determining if there *would be* a change.
    this.changedAttributes = function(diff) {
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
	};
    // Return a JSON-serialized string of the model's `attributes` object.
    this.toJSON = function () {
		return serializeJSON(this.attributes);
	};
	// Proxy `Backbone.sync` by default.
    this.sync = function() {
		return Backbone.sync(argumentCollection = arguments);
	};
    // Create a new model with identical attributes to this one.
    this.clone = function () {
		return this.new(this.attributes);
	};
	// Fetch the model from the server. If the server's representation of the
	// model differs from its current attributes, they will be overriden,
	// triggering a `"change"` event.
    this.fetch = function (struct options = {}) {
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
	};
	// Set a hash of model attributes, and sync the model to the server.
	// If the server returns an attributes hash that differs, the model's
	// state will be `set` again.
    this.save = function(key = '', value = '', struct options) {
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
	};
	// **parse** converts a response into the hash of attributes to be `set` on
	// the model. The default implementation is just to pass the response along.
    this.parse = function(resp, xhr) {
		return resp;
	};
	// Default URL for the model's representation on the server -- if you're
	// using Backbone's restful methods, override this to change the endpoint
	// that will be called.
    this.url = function() {
		if (_.has(this, 'urlRoot'))
			var base = _.result(this, 'urlRoot');
		else if (_.has(this, 'collection') && _.has(this.collection(), 'url'))
			var base = _.result(this.collection(), 'url');
		else
			throw('A "url" property or function must be specified', 'Backbone');
		if (this.isNew())
			return base;
		return base & (right(base, 1) == '/' ? '' : '/') & urlEncodedFormat(this.id);
	};
	// A model is new if it has never been saved to the server, and lacks an id.
    this.isNew = function () {
		return isNull(this.id) || this.id == '';
	};
}
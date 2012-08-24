// Backbone.Collection
// Provides a standard collection class for our sets of models, ordered
// or unordered. If a `comparator` is specified, the Collection will maintain
// its models in sort order, as they're added and removed.
component extends="Events" {
    this.initialize = function () {};// Initialize is an empty function by default. Override it with your own initialization logic.
	this.Model = new Model().extend();// The default model for a collection is just a **Backbone.Model**. This should be overridden in most cases.
	this.models = [];
    this.length = function () {
		return arrayLen(this.models);
	};
	// Returns a new Collection. Equivalent to: new Backbone.Collection(models, options) in BackboneJS
    this.new = function (array models = [], options = {}) {
		var NewCollection = Backbone.Collection.extend();
		return NewCollection(models, options);
	};
	// Returns a function that creates new instances of this Collection.
    this.extend = function (struct properties = {}) {
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
	};
    // The JSON representation of a Collection is an array of the models' attributes.
    this.toJSON = function () {
		var result = '[';
		_.each(this.models, function(model, i) {
			result &= model.toJSON();
			if (i < arrayLen(this.models))
				result &= ',';
		});
		result &= ']';
		return result;
	};
	// Add a model, or list of models to the set. Pass **silent** to avoid
	// firing the `add` event for every new model.
    this.add = function (any models = [], struct options = {}) {
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
	};
    // Remove a model, or a list of models from the set. Pass silent to avoid firing the `remove` event for every model removed.
    this.remove = function(any models = [], struct options = {}) {
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
	};
    // Get a model from the set by id.
    this.get = function (required any id) {
		// arguments.id can either be an id or a structure with an id (confusing, I know)
		if (isStruct(arguments.id) && _.has(arguments.id, 'id')) {
			return this._byId[arguments.id.id];
		}
		else if (isSimpleValue(arguments.id) && _.has(this._byId, arguments.id)) {
			return this._byId[arguments.id];
		}
	};
	// Get a model from the set by client id.
    this.getByCid = function (required any cid) {
		// arguments.cid can either be a cid or a structure with a cid (confusing, I know)
		if (isStruct(arguments.cid) && _.has(cid, 'cid') && _.has(this._byCid, arguments.cid.cid)) {
			return this._byCid[arguments.cid.cid];
		}
		else if (isSimpleValue(arguments.cid) && _.has(this._byCid, arguments.cid)) {
			return this._byCid[arguments.cid];
		}
	};
    // Get the model at the given index.
    this.at = function (required numeric index) {
		return this.models[index];
	};
    // Add a model to the end of the collection.
    this.push = function (required struct model, struct options = {}) {
		this.add(arguments.model, options);
		return arguments.model;
	};
    // Remove a model from the end of the collection.
    this.pop = function (struct options = {}) {
		var result = _.last(this.models);
		this.remove([result], options);
		return result;
	};
    // Add a model to the beginning of the collection.
    this.unshift = function (required struct model, struct options = {}) {
		arguments.model = this._prepareModel(arguments.model, options);
		this.add(arguments.model, _.extend({at: 1}, options));
		return model;
	};
    // Remove a model from the beginning of the collection.
    this.shift = function (struct options = {}) {
		var result = _.first(this.models);
		this.remove([result], options);
		return result;
	};
	// Slice out a sub-array of models from the collection.
    this.slice = function(required numeric begin, required numeric end) {
		return _.slice(this.models, begin, end);
	};
	// Force the collection to re-sort itself. You don't need to call this under
	// normal circumstances, as the set will maintain sort order as each item
	// is added.
    this.sort = function (struct options = {}) {
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
	};
	// Pluck an attribute from each model in the collection.
    this.pluck = function (required string attribute) {
		return _.map(this.models, function(model) {
			return model.get(attribute);
		});
	};
    // Return models with matching attributes. Useful for simple cases of `filter`.
    this.where = function (required struct attributes) {
		return _.filter(this.models, function(model) {
			var result = true;
			_.each(attributes, function(val, key){
				if(!model.get(key) == val)
					result = false;
			});
			return result;
		});
	};
	// Fetch the default set of models for this collection, resetting the
	// collection when they arrive. If `add: true` is passed, appends the
	// models to the collection instead of resetting.
    this.fetch = function (struct options = {}) {
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
	};
	// When you have more items than you want to add or remove individually,
	// you can reset the entire set with a new list of models, without firing
	// any `add` or `remove` events. Fires `reset` when finished.
    this.reset = function (models = [], struct options = {}) {
		for (var i = 1; i <= ArrayLen(this.models); i++) {
			this._removeReference(this.models[i]);
		}
		this._reset();
		this.add(models, _.extend({silent: true}, options));
		if (!_.has(options, 'silent') || !options.silent)
			this.trigger('reset', this, options);
		return this;
	};
    // Reset all internal state. Called when the collection is reset.
	variables._reset = function(struct options = {}) {
		this.models = [];
		this._byId  = {};
		this._byCid = {};
	};
    // Prepare a model or hash of attributes to be added to this collection.
	variables._prepareModel = function(required struct model, struct options = {}) {
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
	};
	// Internal method to remove a model's ties to a collection.
	variables._removeReference = function(required model) {
		if (_.has(model, 'collection') && this.cid == model.collection().cid) {
			structDelete(model, 'collection');
		}
		if (_.has(model, 'off')) {
			model.off('all', this._onModelEvent, this);
		}
	};
	// Internal method called every time a model in the set fires an event. Sets need to update their indexes when models change ids. All other events simply proxy through. "add" and "remove" events that originate in other collections are ignored.
	variables._onModelEvent = function(required string eventName, required struct model, collection, options = {}) {
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
	};
	// Create a new instance of a model in this collection. Add the model to the
	// collection immediately, unless `wait: true` is passed, in which case we
	// wait for the server to agree.
    this.create = function (struct attributes = {}, struct options = {}) {
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
	};
	// **parse** converts a response into the hash of attributes to be `set` on
	// the model. The default implementation is just to pass the response along.
    this.parse = function(resp, xhr) {
		return resp;
	};
}
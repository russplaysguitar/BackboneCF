component extends="mxunit.framework.TestCase" {

	public void function initialize() {
		var Model = Backbone.Model.extend({
			initialize: function() {
				this.one = 1;
				assertEquals(this.Collection.cid, collection.cid);
			}
		});
		var model = Model({}, {collection: collection});
		assertEquals(model.one, 1);
		assertEquals(model.collection.cid, collection.cid);
	}

	public void function initWithAttrsAndOpts() {
		var Model = Backbone.Model.extend({
			initialize: function(attributes, options) {
				this.one = options.one;
			}
		});
		var model = Model({}, {one: 1});
		assertEquals(model.one, 1);
	}

	public void function initWithParsedAtts() {
		var Model = Backbone.Model.extend({
			parse: function(obj) {
				obj.value += 1;
				return obj;
			}
		});
		var model = Model({value: 1}, {parse: true});
		assertEquals(model.get('value'), 2);
	}

	public void function url() {
		var errorThrown = false;
		structDelete(doc, 'urlRoot');
		assertEquals(urlDecode(doc.url()), '/collection/1-the-tempest');
		doc.collection().url = '/collection/';
		assertEquals(urlDecode(doc.url()), '/collection/1-the-tempest');
		doc.collection = false;
		try {
			doc.url();
		}
		catch (any e) {
			errorThrown = true;
		}
		assertTrue(errorThrown);
		doc.collection = collection;
	}

	public void function urlWhenUsingUrlRootAndUriEncoding() {
		var Model = Backbone.Model.extend({
			urlRoot: '/collection'
		});
		var m = Model();
		assertEquals(m.url(), '/collection');
		m.set({id: '+1+'});
		assertEquals(m.url(), '/collection/%2B1%2B');
	}

	public void function urlWhenUsingUrlRootAsAFunctionToDetermineUrlRootAtRuntime() {
		var Model = Backbone.Model.extend({
			urlRoot: function() {
				return '/nested/' & this.get('parent_id') & '/collection';
			}
		});

		var m = Model({parent_id: 1});
		assertEquals(m.url(), '/nested/1/collection');
		m.set({id: 2});
		assertEquals(m.url(), '/nested/1/collection/2');
	}

	public void function clone() {
		var a = Backbone.Model.new({ 'foo': 1, 'bar': 2, 'baz': 3});
		var b = a.clone();
		assertEquals(a.get('foo'), 1);
		assertEquals(a.get('bar'), 2);
		assertEquals(a.get('baz'), 3);
		assertEquals(b.get('foo'), a.get('foo'), "Foo should be the same on the clone.");
		assertEquals(b.get('bar'), a.get('bar'), "Bar should be the same on the clone.");
		assertEquals(b.get('baz'), a.get('baz'), "Baz should be the same on the clone.");
		a.set({foo : 100});
		assertEquals(a.get('foo'), 100);
		assertEquals(b.get('foo'), 1, "Changing a parent attribute does not change the clone.");
	}

	public void function isNew() {
		var a = Backbone.Model.new({ 'foo': 1, 'bar': 2, 'baz': 3});
		assertTrue(a.isNew(), "it should be new");
		a = Backbone.Model.new({ 'foo': 1, 'bar': 2, 'baz': 3, 'id': -5 });
		assertTrue(!a.isNew(), "any defined ID is legal, negative or positive");
		a = Backbone.Model.new({ 'foo': 1, 'bar': 2, 'baz': 3, 'id': 0 });
		assertTrue(!a.isNew(), "any defined ID is legal, including zero");
		assertTrue( Backbone.Model.new({		  }).isNew(), "is true when there is no id");
		assertTrue(!Backbone.Model.new({ 'id': 2  }).isNew(), "is false for a positive integer");
		assertTrue(!Backbone.Model.new({ 'id': -5 }).isNew(), "is false for a negative integer");
	}

	public void function get() {
		assertEquals(doc.get('title'), 'The Tempest');
		assertEquals(doc.get('author'), 'Bill Shakespeare');
	}

	public void function escape() {
		assertEquals(doc.escape('title'), 'The Tempest');
		doc.set({audience: 'Bill & Bob'});
		assertEquals(doc.escape('audience'), 'Bill &amp; Bob');
		doc.set({audience: 'Tim > Joan'});
		assertEquals(doc.escape('audience'), 'Tim &gt; Joan');
		doc.set({audience: 10101});
		assertEquals(doc.escape('audience'), '10101');
		doc.unset('audience');
		assertEquals(doc.escape('audience'), '');
	}

	public void function has() {
		var model = Backbone.Model.new();

		assertEquals(model.has('name'), false);

		model.set({
		  '0': 0,
		  '1': 1,
		  'true': true,
		  'false': false,
		  'empty': '',
		  'name': 'name'
		  // 'null': null,
		  // 'undefined': undefined
		});

		assertEquals(model.has('0'), true);
		assertEquals(model.has('1'), true);
		assertEquals(model.has('true'), true);
		assertEquals(model.has('false'), true);
		assertEquals(model.has('empty'), true);
		assertEquals(model.has('name'), true);

		model.unset('name');

		assertEquals(model.has('name'), false);
		assertEquals(model.has('null'), false);
		assertEquals(model.has('undefined'), false);
	}

	public void function setAndUnset() {
		var a = Backbone.Model.new({id: 'id', foo: 1, bar: 2, baz: 3});
		var changeCount = 0;
		a.on("change:foo", function() { changeCount += 1; });
		a.set({'foo': 2});
		assertTrue(a.get('foo') == 2, "Foo should have changed.");
		assertTrue(changeCount == 1, "Change count should have incremented.");
		a.set({'foo': 2}); // set with value that is not new shouldn't fire change event
		assertTrue(a.get('foo') == 2, "Foo should NOT have changed, still 2");
		assertTrue(changeCount == 1, "Change count should NOT have incremented.");

		a.validate = function(attrs) {
			assertTrue(attrs.foo == '', "don't ignore values when unsetting");
		};
		a.unset('foo');
		assertTrue(isNull(a.get('foo')), "Foo should have changed");
		structDelete(a, 'validate');
		assertTrue(changeCount == 2, "Change count should have incremented for unset.");

		a.unset('id');
		assertEquals(a.id, "", "Unsetting the id should remove the id property.");
	}

	public void function multipleUnsets() {
		var i = 0;
		var counter = function(){ i++; };
		var model = Backbone.Model.new({a: 1});
		model.on("change:a", counter);
		model.set({a: 2});
		model.unset('a');
		model.unset('a');
		assertEquals(i, 2, 'Unset does not fire an event for missing attributes.');
	}

	public void function unsetAndChangedAttribute() {
		var model = Backbone.Model.new({a: 1});
		model.unset('a', {silent: true});
		var changedAttributes = model.changedAttributes();
		assertTrue(_.has(changedAttributes, 'a'), 'changedAttributes should contain unset properties');

		changedAttributes = model.changedAttributes();
		assertTrue(_.has(changedAttributes, 'a'), 'changedAttributes should contain unset properties when running changedAttributes again after an unset.');
	}

	public void function usingANonDefaultIdAttribute() {
		var MongoModel = Backbone.Model.extend({idAttribute : '_id'});
		var model = MongoModel({id: 'eye-dee', _id: 25, title: 'Model'});
		assertEquals(model.get('id'), 'eye-dee');
		assertEquals(model.id, 25);
		assertEquals(model.isNew(), false);
		model.unset('_id');
		assertEquals(model.id, '');
		assertEquals(model.isNew(), true);
	}

	public void function setAnEmptyString() {
		var model = Backbone.Model.new({name : "Model"});
		model.set({name : ''});
		assertEquals(model.get('name'), '');
	}

	public void function clear() {
		var changed = false;
		var model = Backbone.Model.new({id: 1, name : "Model"});
		model.on("change:name", function(){ changed = true; });
		model.on("change", function() {
			var changedAttrs = model.changedAttributes();
			assertTrue(_.has(changedAttrs, 'name'));
		});
		model.clear();
		assertEquals(changed, true);
		assertTrue(isNull(model.get('name')));
	}

	public void function defaults() {
		var Defaulted = Backbone.Model.extend({
		  defaults: {
			"one": 1,
			"two": 2
		  }
		});
		var model = Defaulted({two: ''});
		assertEquals(model.get('one'), 1);
		assertEquals(model.get('two'), '');
		Defaulted = Backbone.Model.extend({
		  defaults: function() {
			return {
			  "one": 3,
			  "two": 4
			};
		  }
		});
		var model = Defaulted({two: ''});
		assertEquals(model.get('one'), 3);
		assertEquals(model.get('two'), '');
	}

	public void function change_hasChanged_changedAttrs_prev_prevAttr() {
		var model = Backbone.Model.new({name : "Tim", age : 10});
		assertEquals(model.changedAttributes(), false);
		model.on('change', function() {
			assertTrue(model.hasChanged('name'), 'name changed');
			assertTrue(!model.hasChanged('age'), 'age did not');
			assertTrue(_.isEqual(model.changedAttributes(), {name : 'Rob'}), 'changedAttributes returns the changed attrs');
			assertEquals(model.previous('name'), 'Tim');
			assertTrue(_.isEqual(model.previousAttributes(), {name : "Tim", age : 10}), 'previousAttributes is correct');
		});
		assertEquals(model.hasChanged(), false);
		model.set({name : 'Rob'}, {silent : true});
		assertEquals(model.hasChanged(), true);
		assertEquals(model.hasChanged('name'), true);
		model.change();
		assertEquals(model.get('name'), 'Rob');
	}

	public void function changeWithOptions() {
		var value = false;
		var model = Backbone.Model.new({name: 'Rob'});
		model.on('change', function(model, options) {
			value = options.prefix & model.get('name');
		});
		model.set({name: 'Bob'}, {silent: true});
		model.change({prefix: 'Mr. '});
		assertEquals(value, 'Mr. Bob');
		model.set({name: 'Sue'}, {prefix: 'Ms. '});
		assertEquals(value, 'Ms. Sue');
	}

	public void function changeAfterInitialize() {
		var changed = 0;
		var attrs = {id: 1, label: 'c'};
		var obj = Backbone.Model.new(attrs);
		obj.on('change', function() { changed += 1; });
		obj.set(attrs);
		assertEquals(changed, 0);
	}

	public void function saveWithinChangeEvent() {
		var model = Backbone.Model.new({firstName : "Taylor", lastName: "Swift"});
		var changeRan = false;
		model.on('change', function () {
			model.save();
			// assertTrue(_.isEqual(lastRequest.model, model));
			changeRan = true;
		});
		model.set({lastName: 'Hicks'});
		assertTrue(changeRan);
	}

	public void function validateAfterSave() {
		var lastError = false; 
		var model = Backbone.Model.new();
		model.validate = function(attrs) {
			if (_.has(attrs, 'admin') && attrs.admin) return "Can't change admin status.";
		};
		model.sync = function(method, model, options) {
			options.success({admin: true});
		};
		model.save({}, {error: function(model, error) {
			lastError = error;
		}});

		assertEquals(lastError, "Can't change admin status.");
	}

	public void function isValid() {
		var model = Backbone.Model.new({valid: true});
		model.validate = function(attrs) {
			if (!attrs.valid) return "invalid";
		};
		assertEquals(model.isValid(), true);
		assertEquals(model.set({valid: false}), false);
		assertEquals(model.isValid(), true);
		var result = model.set('valid', false, {silent: true});
		assertTrue(!_.isBoolean(result) || result != false);
		assertEquals(model.isValid(), false);
	}

	public void function save() {
		doc.save({title : "Henry V"});
		assertEquals(lastRequest.method, 'update');
		assertTrue(_.isEqual(lastRequest.model, doc));
		
	}

	public void function saveInPositionalStyle() {
		var model = Backbone.Model.new();
		model.sync = function(method, model, options) {
			options.success();
		};
		model.save('title', 'Twelfth Night');
		assertEquals(model.get('title'), 'Twelfth Night');
	}
	
	public void function fetch() {
		doc.fetch();
		assertEquals(lastRequest.method, 'read');
		assertTrue(_.isEqual(lastRequest.model, doc));
	}
	
	public void function destroy() {
		doc.destroy();
		assertEquals(lastRequest.method, 'delete');
		assertTrue(_.isEqual(lastRequest.model, doc));

		var newModel = Backbone.Model.new();
		assertEquals(newModel.destroy(), false);
		
	}
	
	public void function nonPersistedDestroy() {
		var a = Backbone.Model.new({ 'foo': 1, 'bar': 2, 'baz': 3});
		a.sync = function() { throw "should not be called"; };
		a.destroy();
		assertTrue(true, "non-persisted model should not call sync");
	}
	
	public void function validate() {
		var lastError = false;
		var model = Backbone.Model.new();
		model.validate = function(attrs) {
			var this_admin = _.has(this.attributes, 'admin') ? this.get('admin') : '';
			var attrs_admin = _.has(attrs, 'admin') ? attrs.admin : '';
			if (attrs_admin != this_admin) return "Can't change admin status.";
		};
		model.on('error', function(model, error) {
			lastError = error;
		});
		var result = model.set({a: 100});
		assertEquals(result, model);
		assertEquals(model.get('a'), 100);
		assertEquals(lastError, false);
		result = model.set({admin: true}, {silent: true});
		assertEquals(model.get('admin'), true);
		result = model.set({a: 200, admin: false});
		assertEquals(lastError, "Can't change admin status.");
		assertEquals(result, false);
		assertEquals(model.get('a'), 100);
	}

	public void function validateOnUnsetAndClear() {
		var error = false;
		var model = Backbone.Model.new({name: "One"});
		model.validate = function(attrs) {
		  if (!_.has(attrs, 'name') || attrs.name == '') {
			error = true;
			return "No thanks.";
		  }
		};
		model.set({name: "Two"});
		assertEquals(model.get('name'), 'Two');
		assertEquals(error, false);
		model.unset('name');
		assertEquals(error, true);
		assertEquals(model.get('name'), 'Two');
		model.clear();
		assertEquals(model.get('name'), 'Two');
		structDelete(model, 'validate');
		model.clear();
		assertTrue(!_.has(model.attributes, 'name'));
	}

	public void function validateWithErrorCallback() {
		var lastError = false;
		var boundError = false;
		var model = Backbone.Model.new();
		model.validate = function(attrs) {
			if (_.has(attrs, 'admin') && attrs.admin) return "Can't change admin status.";
		};
		var callback = function(model, error) {
			lastError = error;
		};
		model.on('error', function(model, error) {
			boundError = true;
		});
		var result = model.set({a: 100}, {error: callback});
		assertEquals(result, model);
		assertEquals(model.get('a'), 100);
		assertEquals(lastError, false);
		assertEquals(boundError, false);
		result = model.set({a: 200, admin: true}, {error: callback});
		assertEquals(result, false);
		assertEquals(model.get('a'), 100);
		assertEquals(lastError, "Can't change admin status.");
		assertEquals(boundError, false);
	}

	public void function defaultsAlwaysExtendAttrs() {
		var Defaulted = Backbone.Model.extend({
		  defaults: {one: 1},
		  initialize : function(attrs, opts) {
			assertEquals(this.attributes.one, 1);
		  }
		});
		var providedattrs = Defaulted({});
		var emptyattrs = Defaulted();
	}

	// TODO: need to adjust Model structure to make this work
	// public void function inheritClassProperties() {
	// 	var nullFunc = function () {};
	// 	var Parent = Backbone.Model.extend({
	// 	   instancePropSame: nullFunc,
	// 	   instancePropDiff: nullFunc
	// 	 }, {
	// 	   classProp: nullFunc
	// 	 });
	// 	 var Child = _.extend(Parent, {
	// 		instancePropDiff: nullFunc
	// 	 });

	// 	 var adult = Parent();
	// 	 var kid   = Child();

	// 	 assertEquals(Child.classProp, Parent.classProp);
	// 	 // assertNotEqual(Child.classProp, undefined);

	// 	 assertEquals(kid.instancePropSame, adult.instancePropSame);
	// 	 // assertNotEqual(kid.instancePropSame, undefined);

	// 	 assertNotEqual(Child.prototype.instancePropDiff, Parent.prototype.instancePropDiff);
	// 	 // assertNotEqual(Child.prototype.instancePropDiff, undefined);
	// }

	public void function nestedChangeEventsDontClobberPrevAtts() {
		var m = Backbone.Model.new();
		var change1ran = false;
		var change2ran = false;
		m.on('change:state', function(model, newState) {
		  // assertEquals(model.previous('state'), undefined);
		  assertEquals(newState, 'hello');
		  // Fire a nested change event.
		  model.set({other: 'whatever'});
		  change1ran = true;
		});
		m.on('change:state', function(model, newState) {
		  // assertEquals(model.previous('state'), undefined);
		  assertEquals(newState, 'hello');
		  change2ran = true;
		});
		m.set({state: 'hello'});
		assertTrue(change1ran);
		assertTrue(change2ran);
	}

	public void function hasChangedSetUseSameComparison() {
		var changed = 0;
		var changeRan = false;
		var model = Backbone.Model.new({a: ''});
		model.on('change', function() {
			changeRan = true;
			assertTrue(this.hasChanged('a'));
		}, model);
		model.on('change:a', function() {
			changed++;
		});
		model.set({a: 'differentValue'});
		assertEquals(changed, 1);
		assertTrue(changeRan);
	}

	public void function changeAttCallbacksShouldFireAfterAllChangesHaveOccurred() {
		var model = Backbone.Model.new();
		var assertionRan = false;

		var assertion = function() {
		  assertEquals(model.get('a'), 'a');
		  assertEquals(model.get('b'), 'b');
		  assertEquals(model.get('c'), 'c');
		  assertionRan = true;
		};

		model.on('change:a', assertion);
		model.on('change:b', assertion);
		model.on('change:c', assertion);

		model.set({a: 'a', b: 'b', c: 'c'});

		assertTrue(assertionRan);
	}

	public void function setWithAttributesProperty() {
		var model = Backbone.Model.new();
		model.set({attributes: true});
		assertTrue(model.has('attributes'));
	}

	public void function setValueRegardlessOfEqualityOrChange() {
		var model = Backbone.Model.new({x: []});
		var a = [];
		model.set({x: a});
		assertEquals(model.get('x'), a);
	}

	public void function unsetFiresChangeForBlankAttributes() {
		var model = Backbone.Model.new({x: ''});
		var changeRan = false;
		model.on('change:x', function(){ changeRan = true; });
		model.unset('x');
		assertTrue(changeRan);
	}

	public void function setBlankValues() {
		var model = Backbone.Model.new({x: ''});
		assertTrue(_.has(model.attributes, 'x'));
	}

	public void function changeFiresChangeAtt() {
		var model = Backbone.Model.new({x: 1});
		var changeRan = false;
		model.set({x: 2}, {silent: true});
		model.on('change:x', function(){ changeRan = true; });
		model.change();
		assertTrue(changeRan);
	}

	public void function hasChangedIsFalseAfterOriginalValuesAreSet() {
		var model = Backbone.Model.new({x: 1});
		model.on('change:x', function(){ assertTrue(false); });
		model.set({x: 2}, {silent: true});
		assertTrue(model.hasChanged());
		model.set({x: 1}, {silent: true});
		assertTrue(!model.hasChanged());
	}

	public void function saveWithWaitSucceedsWithoutValidate() {
		var model = Backbone.Model.new();
		model.save({x: 1}, {wait: true});
		assertEquals(lastRequest.model, model);
	}

	public void function hasChangedForFalsyKeys() {
		var model = Backbone.Model.new();
		model.set({x: true}, {silent: true});
		assertTrue(!model.hasChanged(0));
		assertTrue(!model.hasChanged(''));
	}

	public void function previousForFalsyKeys() {
		var model = Backbone.Model.new({0: true, '': true});
		model.set({0: false, '': false}, {silent: true});
		assertEquals(model.previous(0), true);
		assertEquals(model.previous(''), true);
	}

	public void function saveWithWaitSendsCorrectAttributes() {
		var changed = 0;
		var model = Backbone.Model.new({x: 1, y: 2});
		model.on('change:x', function() { changed++; });
		model.save({x: 3}, {wait: true});
		assertEquals(deserializeJSON(ajaxParams.data), {x: 3, y: 2});
		assertEquals(model.get('x'), 1);
		assertEquals(changed, 0);
		lastRequest.options.success({});
		assertEquals(model.get('x'), 3);
		assertEquals(changed, 1);
	}
	
	public void function aFailedSaveWithWaitDoesntLeaveAttributesBehind() {
		var model = Backbone.Model.new();
		model.save({x: 1}, {wait: true});
		assertTrue(isNull(model.get('x')));
	}

	public void function saveWithWaitResultsInCorrectAttributesIfSuccessIsCalledDuringSync() {
		var model = Backbone.Model.new({x: 1, y: 2});
		model.sync = function(method, model, options) {
			options.success();
		};
		var changeXran = false;
		model.on("change:x", function() { changeXran = true; });
		model.save({x: 3}, {wait: true});
		assertEquals(model.get('x'), 3);
		assertTrue(changeXran);
	}
	
	public void function saveWithWaitValidatesAttributes() {
		var model = Backbone.Model.new();
		var validateRan = false;
		model.validate = function() { validateRan = true; };
		model.save({x: 1}, {wait: true});
		assertTrue(validateRan);
	}

	public void function nestedSetDuringChangeAtt() {
		var events = [];
		var model = Backbone.Model.new();
		model.on('all', function(event) { arrayAppend(events, event, true); });
		model.on('change', function() {
			model.set({z: true}, {silent:true});
		});
		model.on('change:x', function() {
			model.set({y: true});
		});
		model.set({x: true});
		assertEquals(events, ['change:y', 'change:x', 'change']);
		events = [];
		model.change();
		assertEquals(events, ['change:z', 'change']);
	}

	public void function nestedChangeOnlyFiresOnce() {
		var model = Backbone.Model.new();
		var changeRan = 0;
		model.on('change', function() {
			changeRan++;
			model.change();
		});
		model.set({x: true});
		assertEquals(changeRan, 1);
	}

	public void function noChangeEventIfNoChanges() {
		var model = Backbone.Model.new();
		model.on('change', function() { assertTrue(false); });
		model.change();
	}

	public void function nestedSetDuringChange() {
		var count = 0;
		var model = Backbone.Model.new();
		model.on('change', function() {
		  switch(count++) {
			case 0:
			  assertEquals(this.changedAttributes(), {x: true});
			  assertTrue(isNull(model.previous('x')));
			  model.set({y: true});
			  break;
			case 1:
			  assertEquals(this.changedAttributes(), {y: true});
			  assertEquals(model.previous('x'), true);
			  model.set({z: true});
			  break;
			case 2:
			  assertEquals(this.changedAttributes(), {z: true});
			  assertEquals(model.previous('y'), true);
			  break;
			default:
			  assertTrue(false);
		  }
		}, model);
		model.set({x: true});
	}

	public void function nestedChangeWithSilent() {
		var count = 0;
		var model = Backbone.Model.new();
		var changeRan = false;
		model.on('change:y', function() { changeRan = true; });
		model.on('change', function() {
		  switch(count++) {
			case 0:
			  assertEquals(this.changedAttributes(), {x: true});
			  model.set({y: true}, {silent: true});
			  break;
			case 1:
			  assertEquals(this.changedAttributes(), {y: true, z: true});
			  break;
			default:
			  assertTrue(false);
		  }
		}, model);
		model.set({x: true});
		model.set({z: true});
		assertTrue(changeRan);
	}

	public void function multipleNestedChangesWithSilent() {
		var model = Backbone.Model.new();
		var value = false;
		var changeTimes = 0;
		model.on('change:x', function() {
			model.set({y: 1}, {silent: true});
			model.set({y: 2});
		});
		model.on('change:y', function(model, val) {
			value = val;
			changeTimes++;
		});
		model.set({x: true});
		model.change();
		assertEquals(value, 2);
		assertEquals(changeTimes, 1);
	}

	public void function nestedSetMultipleTimes() {
		var model = Backbone.Model.new();
		var changeTimes = 0;
		model.on('change:b', function() {
			changeTimes++;
		});
		model.on('change:a', function() {
		  model.set({b: true});
		  model.set({b: true});
		});
		model.set({a: true});
		assertEquals(changeTimes, 1);
	}

	public void function backboneWrapErrorTriggersError() {
		var errorCallbackRan = false;
		var resp = {};
		var options = {};
		var model = Backbone.Model.new();
		var error = function (_model, _resp, _options) {
		  assertEquals(model, _model);
		  assertEquals(resp,  _resp);
		  assertEquals(options, _options);
		  errorCallbackRan = true;
		};
		model.on('error', error);
		var callback = Backbone.wrapError('', model, options);
		callback(model, resp);
		callback(resp);
		callback = Backbone.wrapError(error, model, options);
		callback(model, resp);
		callback(resp);
		assertTrue(errorCallbackRan);
	}

	public void function isValidReturnsTrueInTheAbsenceOfValidate() {
		var model = Backbone.Model.new();
		structDelete(model, 'validate');
		assertTrue(model.isValid());
	}

	public void function clearDoesNotAlterOptions() {
		var model = Backbone.Model.new();
		var options = {};
		model.clear(options);
		assertTrue(!_.has(options, 'unset'));
	}

	public void function unsetDoesNotAlterOptions() {
		var model = Backbone.Model.new();
		var options = {};
		model.unset('x', options);
		assertTrue(!_.has(options, 'unset'));
	}

	public void function optionsIsPassedToSuccessCallbacks() {
		var model = Backbone.Model.new();
		var successRan = false;
		var opts = {
			success: function( model, resp, options ) {
				assertTrue(!IsNull(options));
				successRan = true;
			}
		};
		model.sync = function(method, model, options) {
			options.success();
		};
		model.save({id: 1}, opts);
		model.fetch(opts);
		model.destroy(opts);
		assertTrue(successRan);
	}
	
	public void function triggerSyncEvent() {
		var syncTimes = 0;
		var model = Backbone.Model.new({id: 1});
		model.sync = function(method, model, options) { options.success(); };
		model.on('sync', function() { syncTimes++; });
		model.fetch();
		model.save();
		model.destroy();
		assertEquals(syncTimes, 3);
	}

	public void function destroyNewModelsExecuteSuccessCallback() {
		var m = Backbone.Model.new();
		var destroyRan = false;
		var successRan = false;
		m.on('sync', function() { assertTrue(false); });
		m.on('destroy', function(){ destroyRan = true; });
		m.destroy({ success: function(){ successRan = true; }});
		assertTrue(destroyRan);
		assertTrue(successRan);
	}
	
	public void function saveAnInvalidModelCannotBePersisted() {
		var model = Backbone.Model.new();
		model.validate = function(){ return 'invalid'; };
		model.sync = function(){ assertTrue(false); };
		assertEquals(model.save(), false);		
	}
	



	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();

		_ = new github.UnderscoreCF.Underscore();

		variables.Backbone.Model.urlRoot = '/';

		var klass = Backbone.Collection.extend({
			url: function() { return '/collection'; }
		});
		var proxy = Backbone.Model.extend();

		variables.doc = proxy({
			id	 : '1-the-tempest',
			title  : "The Tempest",
			author : "Bill Shakespeare",
			length : 123
		});
		variables.collection = klass();
		collection.add(doc);

		originalSync = Backbone.sync;
		variables.Backbone.sync = function(method, model, options) {
			lastRequest = arguments;
			originalSync(argumentCollection = arguments);
			return arguments;
		};
		variables.ajaxParams = {};
		variables.Backbone.ajax = function() { ajaxParams = arguments; return arguments; };

	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}
}
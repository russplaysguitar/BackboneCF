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

	// TODO
	// public void function url() {
	// 	doc.urlRoot = '';
	//	 assertEquals(doc.url(), '/collection/1-the-tempest');
	//	 doc.collection.url = '/collection/';
	//	 assertEquals(doc.url(), '/collection/1-the-tempest');
	//	 doc.collection = false;
	//	 // raises(function() { doc.url(); });
	//	 doc.collection = collection;
	// }

	// TODO
// test("Model: url when using urlRoot, and uri encoding", 2, function() {
//	 var Model = Backbone.Model.extend({
//	   urlRoot: '/collection'
//	 });
//	 var model = new Model();
//	 equal(model.url(), '/collection');
//	 model.set({id: '+1+'});
//	 equal(model.url(), '/collection/%2B1%2B');
//   });

	// TODO
//   test("Model: url when using urlRoot as a function to determine urlRoot at runtime", 2, function() {
//	 var Model = Backbone.Model.extend({
//	   urlRoot: function() {
//		 return '/nested/' + this.get('parent_id') + '/collection';
//	   }
//	 });

//	 var model = new Model({parent_id: 1});
//	 equal(model.url(), '/nested/1/collection');
//	 model.set({id: 2});
//	 equal(model.url(), '/nested/1/collection/2');
//   });


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
		// doc.unset('audience');// doesn't work because _.escape() requires input
		// assertEquals(doc.escape('audience'), '');
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
















	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();

		_ = new github.UnderscoreCF.Underscore();

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
	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}
}
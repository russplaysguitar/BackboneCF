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
	//     assertEquals(doc.url(), '/collection/1-the-tempest');
	//     doc.collection.url = '/collection/';
	//     assertEquals(doc.url(), '/collection/1-the-tempest');
	//     doc.collection = false;
	//     // raises(function() { doc.url(); });
	//     doc.collection = collection;
	// }
	
	// TODO
// test("Model: url when using urlRoot, and uri encoding", 2, function() {
//     var Model = Backbone.Model.extend({
//       urlRoot: '/collection'
//     });
//     var model = new Model();
//     equal(model.url(), '/collection');
//     model.set({id: '+1+'});
//     equal(model.url(), '/collection/%2B1%2B');
//   });

	// TODO
//   test("Model: url when using urlRoot as a function to determine urlRoot at runtime", 2, function() {
//     var Model = Backbone.Model.extend({
//       urlRoot: function() {
//         return '/nested/' + this.get('parent_id') + '/collection';
//       }
//     });

//     var model = new Model({parent_id: 1});
//     equal(model.url(), '/nested/1/collection');
//     model.set({id: 2});
//     equal(model.url(), '/nested/1/collection/2');
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
	    assertTrue( Backbone.Model.new({          }).isNew(), "is true when there is no id");
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
	
	
	
	
	
	
	

	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();
		
		_ = new github.UnderscoreCF.Underscore();

		var klass = Backbone.Collection.extend({
			url: function() { return '/collection'; }
		});		
		var proxy = Backbone.Model.extend();

		variables.doc = proxy({
			id     : '1-the-tempest',
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

component extends="mxunit.framework.TestCase" {
	public void function newAndSort() {
		assertEquals(col.first(), a, "a should be first");
		assertEquals(col.last(), d, "d should be last");
		col.comparator = function(a, b) {
			if (a.id > b.id) {
				return -1;
			}
			else {
				return 1;
			}
		};
		col.sort();
		assertEquals(col.first(), a, "a should be first");
		assertEquals(col.last(), d, "d should be last");
		col.comparator = function(model) { return model.id; };
		col.sort();
		assertEquals(col.first(), d, "d should be first");
		assertEquals(col.last(), a, "a should be last");
		assertEquals(col.length, 4);
	}

	public void function getAndGetByCid() {
		assertEquals(col.get(0), d);
	    assertEquals(col.get(2), b);
	    assertEquals(col.getByCid(col.first().cid), col.first());
	}

	public void function getWithNonDefaultIds() {
		var MyCol = Backbone.Collection.extend();
		var col = MyCol();
	    var MongoModel = Backbone.Model.extend({
	      idAttribute: '_id'
	    });
	    var model = MongoModel({_id: 100});
	    col.push(model);
	    assertEquals(col.get(100), model);
	    model.setMultiple({_id: 101});
	    assertEquals(col.get(101), model);
	}

	public void function updateIndexWhenIdChanges() {
		var MyCol = Backbone.Collection.extend();
		var col = MyCol();
		col.add([
		  {id : 0, name : 'one'},
		  {id : 1, name : 'two'}
		]);
		var one = col.get(0);
		assertEquals(one.get('name'), 'one');
		one.setMultiple({id : 101});
		assertEquals(col.get(101).get('name'), 'one');
	}
	
	public void function testAt() {
		assertEquals(col.at(3), c);
	}
	
	public void function testPluck() {
		assertEquals(col.pluck('label'), ['a', 'b', 'c', 'd']);
	}
	
	public void function testAdd() {
	    var EModel = Backbone.Model.extend();
	    var e = EModel({id: 10, label : 'e'});
	    otherCol.add(e);
	    otherCol.on('add', function() {
			secondAdded = true;
	    });
	    col.on('add', function(model, collection, options){
			added = model.get('label');
			// assertEquals(options.index, 5);
			opts = options;
	    });
	    col.add(e, {amazing: true});
	    assertEquals(added, 'e');
	    assertEquals(col.length, 5);
	    assertTrue(_.isEqual(col.last(), e));
	    assertEquals(otherCol.length, 1);
	    assertTrue(opts.amazing);

	    var Model = Backbone.Model.extend();
	    var f = Model({id: 20, label : 'f'});
	    var g = Model({id: 21, label : 'g'});
	    var h = Model({id: 22, label : 'h'});
	    var NewAtCol = Backbone.Collection.extend();
	    var atCol = NewAtCol([f, g, h]);
	    assertEquals(atCol.length, 3);
	    atCol.add(e, {at: 1});
	    assertEquals(atCol.length, 4);
	    assertTrue(_.isEqual(atCol.at(1), e));
	    assertTrue(_.isEqual(atCol.last(), h));
	}
	
	
	
	

	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();
		variables.MyModel   = Backbone.Model.extend();
		variables.a         = variables.MyModel({id: 3, label: 'a'});
		variables.b         = variables.MyModel({id: 2, label: 'b'});
		variables.c         = variables.MyModel({id: 1, label: 'c'});
		variables.d         = variables.MyModel({id: 0, label: 'd'});
		variables.MyCol		= Backbone.Collection.extend();
		variables.col       = variables.MyCol([a,b,c,d]);
		variables.otherCol  = variables.MyCol();

		Backbone.sync = function(method, model, options) {
			lastRequest = {
				method: method,
				model: model,
				options: options
			};
		};

		_ = new github.UnderscoreCF.Underscore();
	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}	
}
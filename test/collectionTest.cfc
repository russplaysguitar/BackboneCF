
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
		assertEquals(col.length(), 4);
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




	public void function setUp() {
		variables.Backbone = new backbone.Backbone();
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
	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}	
}
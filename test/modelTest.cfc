component extends="mxunit.framework.TestCase" {
	
	public void function initialize() {
		var Model = Backbone.Model.extend({
			initialize: function() {
				this.one = 1;
				assertEquals(this.collection.cid, collection.cid);
			}
		});
		var model = Model({}, {collection: collection});
		assertEquals(model.one, 1);
		assertEquals(model.collection.cid, collection.cid);
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
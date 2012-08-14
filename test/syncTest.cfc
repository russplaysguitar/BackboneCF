component extends="mxunit.framework.TestCase" {

	public void function read() {
		library.fetch();
	    assertEquals(lastRequest.url, '/library');
	    assertEquals(lastRequest.type, 'GET');
	    assertEquals(lastRequest.dataType, 'json');
	    assertTrue(_.isEmpty(lastRequest.data));
	}


	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();
	
		variables._ = new github.UnderscoreCF.Underscore();

		variables.lastRequest = {
			url: '',
			data: '',
			type: '',
			dataType: ''
		};

		LibCollect = Backbone.Collection.extend({
			url : function() { return '/library'; }
		});

		variables.library = LibCollect();

		variables.attrs = {
		    title  : "The Tempest",
		    author : "Bill Shakespeare",
		    length : 123
		  };

		Backbone.ajax = function() {
			lastRequest = arguments;
		};
		library.create(attrs, {wait: false});

	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}

}
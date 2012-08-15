component extends="mxunit.framework.TestCase" {

	public void function read() {
		library.fetch();
		assertEquals(lastRequest.url, '/library');
		assertEquals(lastRequest.type, 'GET');
		assertEquals(lastRequest.dataType, 'json');
		assertTrue(_.isEmpty(lastRequest.data));
	}

	public void function passingData() {
		library.fetch({data: {a: 'a', one: 1}});
		assertEquals(lastRequest.url, '/library');
		assertEquals(lastRequest.data.a, 'a');
		assertEquals(lastRequest.data.one, 1);
	}

	public void function create() {
		assertEquals(lastRequest.url, '/library');
		assertEquals(lastRequest.type, 'POST');
		assertEquals(lastRequest.dataType, 'json');
		var data = deserializeJSON(lastRequest.data);
		assertEquals(data.title, 'The Tempest');
		assertEquals(data.author, 'Bill Shakespeare');
		assertEquals(data.length, 123);
	}

	public void function update() {
		library.first().save({id: '1-the-tempest', author: 'William Shakespeare'});
		assertEquals(urlDecode(lastRequest.url), '/library/1-the-tempest');
		assertEquals(lastRequest.type, 'PUT');
		assertEquals(lastRequest.dataType, 'json');
		var data = deserializeJSON(lastRequest.data);
		assertEquals(data.id, '1-the-tempest');
		assertEquals(data.title, 'The Tempest');
		assertEquals(data.author, 'William Shakespeare');
		assertEquals(data.length, 123);
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
			return arguments;
		};
		library.create(attrs, {wait: false});

	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}

}
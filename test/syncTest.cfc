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

	public void function updateWithEmulateHTTPandEmulateJSON() {
		Backbone.emulateHTTP = Backbone.emulateJSON = true;
		library.first().save({id: '2-the-tempest', author: 'Tim Shakespeare'});
		assertEquals(urlDecode(lastRequest.url), '/library/2-the-tempest');
		assertEquals(lastRequest.type, 'POST');
		assertEquals(lastRequest.dataType, 'json');
		assertEquals(lastRequest.data._method, 'PUT');
		var data = deserializeJSON(lastRequest.data.model);
		assertEquals(data.id, '2-the-tempest');
		assertEquals(data.author, 'Tim Shakespeare');
		assertEquals(data.length, 123);
		Backbone.emulateHTTP = Backbone.emulateJSON = false;
	}

	public void function updateWithEmulateHTTP() {
		Backbone.emulateHTTP = true;
		library.first().save({id: '2-the-tempest', author: 'Tim Shakespeare'});
		assertEquals(urlDecode(lastRequest.url), '/library/2-the-tempest');
		assertEquals(lastRequest.type, 'POST');
		assertEquals(lastRequest.contentType, 'application/json');
		var data = deserializeJSON(lastRequest.data);
		assertEquals(data.id, '2-the-tempest');
		assertEquals(data.author, 'Tim Shakespeare');
		assertEquals(data.length, 123);
		Backbone.emulateHTTP = false;
	}

	public void function updateWithJustEmulateJSON() {
		Backbone.emulateJSON = true;
		library.first().save({id: '2-the-tempest', author: 'Tim Shakespeare'});
		assertEquals(urldecode(lastRequest.url), '/library/2-the-tempest');
		assertEquals(lastRequest.type, 'PUT');
		assertEquals(lastRequest.contentType, 'application/x-www-form-urlencoded');
		var data = deserializeJSON(lastRequest.data.model);
		assertEquals(data.id, '2-the-tempest');
		assertEquals(data.author, 'Tim Shakespeare');
		assertEquals(data.length, 123);
		Backbone.emulateJSON = false;
	}

	public void function readModel() {
		library.first().save({id: '2-the-tempest', author: 'Tim Shakespeare'});
		library.first().fetch();
		assertEquals(urlDecode(lastRequest.url), '/library/2-the-tempest');
		assertEquals(lastRequest.type, 'GET');
		assertTrue(_.isEmpty(lastRequest.data));
	}

	public void function destroy() {
		library.first().save({id: '2-the-tempest', author: 'Tim Shakespeare'});
		library.first().destroy({wait: true});
		assertEquals(urlDecode(lastRequest.url), '/library/2-the-tempest');
		assertEquals(lastRequest.type, 'DELETE');
		assertEquals(lastRequest.data, {});
	}

	public void function destroyWithEmulateHTTP() {
		library.first().save({id: '2-the-tempest', author: 'Tim Shakespeare'});
		Backbone.emulateHTTP = Backbone.emulateJSON = true;
		library.first().destroy();
		assertEquals(urlDecode(lastRequest.url), '/library/2-the-tempest');
		assertEquals(lastRequest.type, 'POST');
		assertEquals(lastRequest.data, {"_method":"DELETE"});
		Backbone.emulateHTTP = Backbone.emulateJSON = false;
	}

	public void function urlError() {
		var model = Backbone.Model.new();
		var threwError = false;
		try {
			model.fetch();
		}
		catch(any e) {
			threwError = true;
		}
		model.fetch({url: '/one/two'});
		assertEquals(lastRequest.url, '/one/two');
		assertTrue(threwError);
	}

	public void function optionsIsOptional() {
		var model = Backbone.Model.new();
		model.url = '/test';
		Backbone.sync('create', model);
	}

	public void function backboneDotAjax() {
		var settingsOuter = {};
		Backbone.ajax = function(){
			settingsOuter = arguments;
		};
		var model = Backbone.Model.new();
		model.url = '/test';
		Backbone.sync('create', model);
		assertEquals(settingsOuter.url, '/test');
	}

	public void function syncProcessDataFalse() {
		var model = Backbone.Model.new();
		model.url = '/test';
		Backbone.sync('create', model);	
		assertFalse(lastRequest.processData);
		Backbone.sync('read', model);
		assertTrue(isNull(lastRequest.processData));
	}
	
	













	public void function setUp() {
		// variables.Backbone  = new backbone.Backbone();

		variables._ = new github.UnderscoreCF.Underscore();

		variables.lastRequest = {
			url: '',
			data: '',
			type: '',
			dataType: ''
		};

		LibCollect = new Backbone.Collection().extend({
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
		// structDelete(variables, "Backbone");
	}

}
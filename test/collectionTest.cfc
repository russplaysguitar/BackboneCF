
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
		var col = Backbone.Collection.new();
	    var MongoModel = Backbone.Model.extend({
	      idAttribute: '_id'
	    });
	    var model = MongoModel({_id: 100});
	    col.push(model);
	    assertEquals(col.get(100), model);
	    model.set({_id: 101});
	    assertEquals(col.get(101), model);
	}

	public void function updateIndexWhenIdChanges() {
		var col = Backbone.Collection.new();
		col.add([
		  {id : 0, name : 'one'},
		  {id : 1, name : 'two'}
		]);
		var one = col.get(0);
		assertEquals(one.get('name'), 'one');
		one.set({id : 101});
		assertEquals(col.get(101).get('name'), 'one');
	}
	
	public void function testAt() {
		assertEquals(col.at(3), c);
	}
	
	public void function testPluck() {
		assertEquals(col.pluck('label'), ['a', 'b', 'c', 'd']);
	}
	
	public void function testAdd() {
	    var e = Backbone.Model.new({id: 10, label : 'e'});
	    otherCol.add(e);
	    otherCol.on('add', function() {
			secondAdded = true;
	    });
	    var ctx = {};
	    col.on('add', function(model, collection, options){
			var added = model.get('label');
			assertEquals(options.index, 5);
		    assertEquals(added, 'e');
		    assertTrue(options.amazing);
	    }, ctx);
	    col.add(e, {amazing: true});
	    assertEquals(col.length, 5);
	    assertTrue(_.isEqual(col.last(), e));
	    assertEquals(otherCol.length, 1);

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
	
	public void function addMultipleModels() {
		var col = Backbone.Collection.new([{at: 1}, {at: 2}, {at: 9}]);
	    col.add([{at: 3}, {at: 4}, {at: 5}, {at: 6}, {at: 7}, {at: 8}, {at: 9}], {at: 3});
	    for (i = 1; i <= 6; i++) {
			assertEquals(col.at(i).get('at'), i);
	    }	
	}
	
	public void function add_AtShouldHavePreferenceOverComparator() {
		var Col = Backbone.Collection.extend({
			comparator: function(a,b) {
				return a.id > b.id ? -1 : 1;
			}
		});

		var col = Col([{id: 2}, {id: 3}]);
		col.add(Backbone.Model.new({id: 1}), {at: 2});

		assertEquals(col.pluck('id'), [3, 1, 2]);
	}
	
	public void function collection_cantAddModelToCollectionTwice() {
		var col = Backbone.Collection.new([{id: 1}, {id: 2}, {id: 1}, {id: 2}, {id: 3}]);
	    assertEquals(col.pluck('id'), [1, 2, 3]);
	}
	
	public void function collection_cantAddDifferentModelWithSameIdToCollectionTwice() {
		var col = Backbone.Collection.new();
	    col.unshift({id: 101});
	    col.add({id: 101});
	    assertEquals(col.length, 1);
	}
	
	public void function collection_mergeInDuplicateModelsWithMergeTrue() {
		var col = Backbone.Collection.new();
		col.add([{id: 1, name: 'Moe'}, {id: 2, name: 'Curly'}, {id: 3, name: 'Larry'}]);
		col.add({id: 1, name: 'Moses'});
		assertEquals(col.first().get('name'), 'Moe');
		col.add({id: 1, name: 'Moses'}, {merge: true});
		assertEquals(col.first().get('name'), 'Moses');
		col.add({id: 1, name: 'Tim'}, {merge: true, silent: true});
		assertEquals(col.first().get('name'), 'Tim');
	}

	public void function collection_addModelToMultipleCollections() {
		var counter = 0;
		var e = Backbone.Model.new({id: 10, label : 'e'});
		e.on('add', function(model, collection) {
			counter++;
			assertEquals(e, model);
			if (counter > 1) {
				assertEquals(collection, colF);
			} else {
				assertEquals(collection, colE);
			}
		});
		var colE = Backbone.Collection.new([]);
		colE.on('add', function(model, collection) {
			assertEquals(e, model);
			assertEquals(colE, collection);
		});
		var colF = Backbone.Collection.new([]);
		colF.on('add', function(model, collection) {
			assertEquals(e, model);
			assertTrue(_.isEqual(colF.toJSON(), collection.toJSON()));
		});
		colE.add(e);
		assertTrue(_.isEqual(e.collection().toJSON(), colE.toJSON()));
		colF.add(e);
		assertTrue(_.isEqual(e.collection().toJSON(), colE.toJSON()));
	}

	public void function addModelWithParse() {
		var Model = Backbone.Model.extend({
			parse: function(obj) {
				obj.value += 1;
				return obj;
			}
		});

		var Collection = Backbone.Collection.extend({model: Model});
		var col = Collection();
		col.add({value: 1}, {parse: true});
		assertEquals(col.at(1).get('value'), 2);
	}

	public void function addModelToCollectionWithSortStyleComparatior() {
		var col = Backbone.Collection.new();
		col.comparator = function(a, b) {
			return a.get('name') < b.get('name') ? -1 : 1;
		};
		var tom = Backbone.Model.new({name: 'Tom'});
		var rob = Backbone.Model.new({name: 'Rob'});
		var tim = Backbone.Model.new({name: 'Tim'});
		col.add(tom);
		col.add(rob);
		col.add(tim);
		assertEquals(col.indexOf(item = rob), 1);
		assertEquals(col.indexOf(item = tim), 2);
		assertEquals(col.indexOf(item = tom), 3);
	}
	
		
	

	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();
		variables.a         = Backbone.Model.new({id: 3, label: 'a'});
		variables.b         = Backbone.Model.new({id: 2, label: 'b'});
		variables.c         = Backbone.Model.new({id: 1, label: 'c'});
		variables.d         = Backbone.Model.new({id: 0, label: 'd'});
		variables.col       = Backbone.Collection.new([a,b,c,d]);
		variables.otherCol  = Backbone.Collection.new();

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
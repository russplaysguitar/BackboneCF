
<cfscript>

variables._ = new github.UnderscoreCF.Underscore();

Backbone = new Backbone();

// writeDump(Backbone);

MyModel = Backbone.Model.extend({
	getThis: function () {
		return this;
	},
	validate: function (attributes) {
		return true;
	}
});

a = MyModel({x: 2});

// writeDump(a);

// writeDump(a.getThis());

// writeDump(a.get('x'));

// a.on('change:y', function (model, val, changedAttributes) { 
// 	writeDump('y changed'); //writeDump(arguments); 
// }, {ctx:true});

// a.set('y', 5);

// writeDump(a.get('x'));

// a.off('change:y');

// a.set('y', 6);

// writeDump(a.get('y'));

// a.clear();

// writeDump(a);

// Meal = Backbone.Model.extend({
//   defaults: {
//     "appetizer":  "caesar salad",
//     "entree":     "ravioli",
//     "dessert":    "cheesecake"
//   }
// });

// m = Meal({
// 	"entree": "blah"
// });

// writeDump(m);

// writeDump(m.toJSON());

// Meal = Backbone.Model.extend({
//   idAttribute: "_id"
// });

// cake = Meal({ _id: 1, id:2, name: "Cake" });
// writeDump("Cake id: " & cake.id);

// writeDump(cake);

// writeDump(cake.clone());

Hacker = Backbone.Model.extend({
	fun: "times"
});

aHacker = Hacker({one:1, id:50});

Collection = Backbone.Collection.extend({model: Hacker});

myCollection = Collection([aHacker]);

// writeDump(myCollection);

// myCollection.remove([aHacker]);

// writeDump(myCollection);


// writeDump(myCollection.pop());

// writeDump(myCollection.where({'one':1}));

// myCollection.create({two:2});

// writeDump(myCollection.toJSON());

DocumentRow = Backbone.View.extend({
  tagName: "li",
  className: "document-row",
  attributes: {
  	type: "document"
  },
  events: {
    "click .icon":          "open",
    "click .button.edit":   "openEditDialog",
    "click .button.delete": "destroy"
  },
  render: function() {
  	writeDump(this.el);
  }
});

Document = Backbone.Model.extend();

DocCollection = Backbone.Collection.extend({
	model: Document,
	url: 'http://localhost:8500/rest/MyRest/restService'
});

/* end definitions */

docCollect = DocCollection();
// doc = docCollect.create({id: 10, content: 'stuff'});
// doc2 = docCollect.create({id: 20, content: 'something else'});

// row = DocumentRow({
// 	collection: docCollect,
// 	model: doc,
// 	id: "document-row-" & doc.id
// });

// writeDump(row);

// row.render();

docCollect.fetch();

// writeDump(docCollect.models);

_.each(docCollect.models, function(model) {
  var row = DocumentRow({
    collection: docCollect,
    model: model,
    id: "document-row-" & model.id
  });
  row.render();
});
</cfscript>
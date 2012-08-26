component extends="mxunit.framework.TestCase" {

	public void function constructor() {
		var xmlEl = xmlParse(view.el);
		var xmlElAttrs = xmlEl.div.xmlAttributes;
		assertEquals(xmlElAttrs.id, 'test-view');
		assertEquals(xmlElAttrs.class, 'test-view');
		assertEquals(view.options.id, 'test-view');
		assertEquals(view.options.className, 'test-view');
	}
	
	public void function make() {
		var div = view.make('div', {id: 'test-div'}, "one two three");
		var xmlDiv = xmlParse(div);
		var xmlDivAttrs = xmlDiv.div.xmlAttributes;
		assertTrue(_.has(xmlDiv, 'div'));
		assertEquals(xmlDivAttrs.id, 'test-div');
		assertEquals(xmlDiv.div.XmlText, 'one two three');
	}
	
	public void function makeCanTakeFalsyValuesForContent() {
		var div = view.make('div', {id: 'test-div'}, 0);
		var xmlDiv = xmlParse(div);
		assertEquals(xmlDiv.div.xmlText, '0');

		var div = view.make('div', {id: 'test-div'}, '');
		var xmlDiv = xmlParse(div);
		assertEquals(xmlDiv.div.xmlText, '');
	}
	
	public void function initialize() {
		var View = new Backbone.View().extend({
			initialize: function() {
				this.one = 1;
			}
		});
		var view = View();
		assertEquals(view.one, 1);
	}
	
	public void function withClassnameAndIdFunctions() {
		var View = new Backbone.View().extend({
			className: function() {
				return 'className';
			},
			id: function() {
				return 'id';
			}
		});
		var view = View();
		var xmlEl = xmlParse(view.el);
		var xmlElAttrs = xmlEl.div.xmlAttributes;
		assertEquals(xmlElAttrs.class, 'className');
		assertEquals(xmlElAttrs.id, 'id');
	}
	
	public void function viewWithAttributes() {
		var view = new Backbone.View().new({attributes : {'class': 'one', id: 'two'}});
		var xmlEl = xmlParse(view.el);
		var xmlElAttrs = xmlEl.div.xmlAttributes;
		assertEquals(xmlElAttrs.class, 'one');
		assertEquals(xmlElAttrs.id, 'two');
	}
	
	public void function withAttributesAsAFunction() {
		var viewClass = new Backbone.View().extend({
			attributes: function() {
				return {'class': 'dynamic'};
			}
		});
		var view = viewClass();
		var xmlEl = xmlParse(view.el);
		var xmlElAttrs = xmlEl.div.xmlAttributes;
		assertEquals(xmlElAttrs.class, 'dynamic');
	}
	
	
	
	
	
	
	
	








	public void function setUp() {

		variables._ = new github.UnderscoreCF.Underscore();

		view = new Backbone.View().new({
			id        : 'test-view',
			className : 'test-view'
		});

	}

	public void function tearDown() {

	}
}
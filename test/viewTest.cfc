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
	
	
	








	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();

		variables._ = new github.UnderscoreCF.Underscore();

		view = Backbone.View.new({
			id        : 'test-view',
			className : 'test-view'
		});

	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}
}
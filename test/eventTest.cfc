component extends="mxunit.framework.TestCase" {

	public void function onAndTrigger() {
		var obj = { counter: 0 };
	    _.extend(obj, Backbone.Events);
	    obj.on('event', function() { obj.counter += 1; });
	    obj.trigger('event');
	    assertEquals(obj.counter, 1, 'counter should be incremented.');
	    obj.trigger('event');
	    obj.trigger('event');
	    obj.trigger('event');
	    obj.trigger('event');
	    assertEquals(obj.counter, 5, 'counter should be incremented five times.');
	}
	
	public void function bindingAndTriggeringMultipleEvents() {
		var obj = { counter: 0 };
	    _.extend(obj, Backbone.Events);

	    obj.on('a b c', function() { obj.counter += 1; });

	    obj.trigger('a');
	    assertEquals(obj.counter, 1);

	    obj.trigger('a b');
	    assertEquals(obj.counter, 3);

	    obj.trigger('c');
	    assertEquals(obj.counter, 4);

	    obj.off('a c');
	    obj.trigger('a b c');
	    assertEquals(obj.counter, 5);
	}
	
	public void function triggerAllForEachEvent() {
		var a = false;
		var b = false;
		var obj = { counter: 0 };
	    
	    _.extend(obj, Backbone.Events);

	    obj.on('all', function(event) {
	      obj.counter++;
	      if (event == 'a') a = true;
	      if (event == 'b') b = true;
	    });
	    obj.trigger('a b');
	    assertTrue(a);
	    assertTrue(b);
	    assertEquals(obj.counter, 2);
	}
	
	public void function onThenUnbindAllFunctions() {
		var obj = { counter: 0 };
	    _.extend(obj, Backbone.Events);

	    var callback = function() { obj.counter += 1; };
	    obj.on('event', callback);
	    obj.trigger('event');
	    obj.off('event');
	    obj.trigger('event');
	    assertEquals(obj.counter, 1, 'counter should have only been incremented once.');
	}
	
	public void function bindTwoCallbacksAndUnbindOnlyOnce() {
		var obj = { counterA: 0, counterB: 0 };
	    _.extend(obj, Backbone.Events);

	    var callback = function() { obj.counterA += 1; };
	    obj.on('event', callback);
	    obj.on('event', function() { obj.counterB += 1; });
	    obj.trigger('event');
	    obj.off('event', callback);
	    obj.trigger('event');
	    assertEquals(obj.counterA, 1, 'counterA should have only been incremented once.');
	    assertEquals(obj.counterB, 2, 'counterB should have been incremented twice.');
	}
	
	public void function unbindACallbackInTheMidstOfItFiring() {
		var obj = {counter: 0};
	    _.extend(obj, Backbone.Events);

	    var callback = function() {
	      obj.counter += 1;
	      obj.off('event', callback);
	    };
	    obj.on('event', callback);
	    obj.trigger('event');
	    obj.trigger('event');
	    obj.trigger('event');
	    assertEquals(obj.counter, 1, 'the callback should have been unbound.');
	}
	
	public void function twoUnbindsThatUnbindThemselves() {
		 var obj = { counterA: 0, counterB: 0 };
	    _.extend(obj,Backbone.Events);
	    var incrA = function(){ obj.counterA += 1; obj.off('event', incrA); };
	    var incrB = function(){ obj.counterB += 1; obj.off('event', incrB); };
	    obj.on('event', incrA);
	    obj.on('event', incrB);
	    obj.trigger('event');
	    obj.trigger('event');
	    obj.trigger('event');
	    assertEquals(obj.counterA, 1, 'counterA should have only been incremented once.');
	    assertEquals(obj.counterB, 1, 'counterB should have only been incremented once.');
	}
	
	public void function bindACallbackWithASuppliedContext() {
		var assertRan = false;
	    var TestStruct = {
	    	assertTrue: function () {
				assertTrue(true, '`this` was bound to the callback');
				assertRan = true;
		    }
	    };

	    var obj = _.extend({}, Backbone.Events);
	    obj.on('event', function () { this.assertTrue(); }, TestStruct);
	    obj.trigger('event');
	    assertTrue(assertRan);
	}
	
	public void function nestedTriggerWithUnbind() {
		var obj = { counter: 0 };
	    _.extend(obj, Backbone.Events);
	    var incr1 = function(){ obj.counter += 1; obj.off('event', incr1); obj.trigger('event'); };
	    var incr2 = function(){ obj.counter += 1; };
	    obj.on('event', incr1);
	    obj.on('event', incr2);
	    obj.trigger('event');
	    assertEquals(obj.counter, 3, 'counter should have been incremented three times');
	}
	
	public void function callbacksListIsNotAlteredDuringTrigger() {
		var counter = 0;
		var obj = _.extend({}, Backbone.Events);
	    var incr = function(){ counter++; };
	    obj.on('event', function(){ obj.on('event', incr); obj.on('all', incr); });
	    obj.trigger('event');
	    assertEquals(counter, 0, 'bind does not alter callback list');
	    obj.off();
	    obj.on('event', function(){ obj.off('event', incr); obj.off('all', incr); });
	    obj.on('event', incr);
	    obj.on('all', incr);
	    obj.trigger('event');
	    assertEquals(counter, 2, 'unbind does not alter callback list');
	}
	
	public void function allCallbackListIsRetrievedAfterEachEvent() {
		var counter = 0;
	    var obj = _.extend({}, Backbone.Events);
	    var incr = function(){ counter++; };
	    obj.on('x', function() {
			obj.on('y', incr);
			obj.on('all', incr);
	    });
	    obj.trigger('x y');
	    assertEquals(counter, 2);
	}
	
	public void function ifNoCallbackIsProvidedOnIsANoop() {
		var obj = _.extend({}, Backbone.Events);
		obj.on('test');
		obj.trigger('test');
	}
	
	public void function removeAllEventsForASpecificContext() {
		var obj = _.extend({}, Backbone.Events);
	    obj.on('x y all', function() { assertTrue(true); });
	    obj.on('x y all', function() { assertTrue(false); }, obj);
	    obj.off(context = obj);
	    obj.trigger('x y');
	}
	
	
	
	
	
	
	
	
	
	
	
	
	

	public void function setUp() {
		variables.Backbone  = new backbone.Backbone();

		variables._ = new github.UnderscoreCF.Underscore();
	}

	public void function tearDown() {
		structDelete(variables, "Backbone");
	}
}
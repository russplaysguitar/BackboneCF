component {
	public struct function init() {
		// requires the Underscore.cfc library
		variables._ = new github.UnderscoreCF.Underscore();

		// handles basic http requests
		variables.httpCFC = new Http();

		// Turn on `emulateJSON` to support legacy servers that can't deal with direct
		// `application/json` requests ... will encode the body as
		// `application/x-www-form-urlencoded` instead and will send the model in a
		// form param named `model`.
		this.emulateJSON: false;
		// Turn on `emulateHTTP` to support legacy HTTP servers. Setting this option
		// will fake `"PUT"` and `"DELETE"` requests via the `_method` parameter and
		// set a `X-Http-Method-Override` header.
		this.emulateHTTP: false;	

		// Map from CRUD to HTTP for our default `Backbone.sync` implementation.
		this.methodMap = {
			'create': 'POST',
			'update': 'PUT',
			'delete': 'DELETE',
			'read':   'GET'
		};	
	}

	public any function wrapError(onError, required struct originalModel, struct options = {}) {
		var args = arguments;
		return function(required struct model, resp) {
			arguments.resp = _.isEqual(arguments.model, originalModel) && _.has(arguments, 'resp') ? arguments.resp : arguments.model;
			if (_.has(args, 'onError') && _.isFunction(args.onError)) {
				onError(originalModel, arguments.resp, args.options);
			} else {
				args.originalModel.trigger('error', args.originalModel, arguments.resp, args.options);
			}
		};
	}

	public struct function ajax() {
		return httpCFC.request(argumentCollection = arguments);
	}
}
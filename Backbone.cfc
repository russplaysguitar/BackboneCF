component {
	public any function init() {
		// requires the Underscore.cfc library
		variables._ = new github.UnderscoreCF.Underscore();

		// handles basic http requests
		variables.httpCFC = new Http();

		// Turn on `emulateJSON` to support legacy servers that can't deal with direct
		// `application/json` requests ... will encode the body as
		// `application/x-www-form-urlencoded` instead and will send the model in a
		// form param named `model`.
		this.emulateJSON = false;
		// Turn on `emulateHTTP` to support legacy HTTP servers. Setting this option
		// will fake `"PUT"` and `"DELETE"` requests via the `_method` parameter and
		// set a `X-Http-Method-Override` header.
		this.emulateHTTP = false;	

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

	public any function sync(required string method, struct model, struct options = {}) {
		var type = this.methodMap[method];
	    // Default JSON-request options.
		var params = {type: type, dataType: 'json'};

		// Ensure that we have a URL.
		if (!_.has(options, 'url')) {
			if (!_.has(model, 'url'))
				throw('A "url" property or function must be specified', 'Backbone');
			params.url = _.result(model, 'url');
		}
	    // Ensure that we have the appropriate request data.
		if (!_.has(options, 'data') && _.has(arguments, 'model') && (method == 'create' || method == 'update')) {
			params.contentType = 'application/json';
			params.data = model.toJSON();
		}
	    // For older servers, emulate JSON by encoding the request into an HTML-form.
		if (this.emulateJSON) {
			params.contentType = 'application/x-www-form-urlencoded';
			if (_.has(params, 'data'))
				params.data = {model: params.data};
			else
				params.data = {};
		}
		// For older servers, emulate HTTP by mimicking the HTTP method with `_method`
		// And an `X-HTTP-Method-Override` header.
		if (this.emulateHTTP) {
			if (type == 'PUT' || type == 'DELETE') {
				if (Backbone.emulateJSON)
					params.data._method = type;
				params.type = 'POST';
				params.headers = {
					'X-HTTP-Method-Override': type
				};
			}
		}

		// ensure data parameter is at least an empty struct
		if (!_.has(params, 'data')) params.data = {};

		// Don't process data on a non-GET request.
		if (params.type != 'GET' && !Backbone.emulateJSON) {
			params.processData = false;
		}

		// Make the request, allowing the user to override any http request options.
		return this.ajax(argumentCollection = _.extend(params, options));
	}

	public struct function ajax() {
		return httpCFC.request(argumentCollection = arguments);
	}
}
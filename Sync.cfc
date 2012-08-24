component extends="Core,Events" {
	public any function init() {
		var type = methodMap[method];
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
		if (Backbone.emulateJSON) {
			params.contentType = 'application/x-www-form-urlencoded';
			if (_.has(params, 'data'))
				params.data = {model: params.data};
			else
				params.data = {};
		}
		// For older servers, emulate HTTP by mimicking the HTTP method with `_method`
		// And an `X-HTTP-Method-Override` header.
		if (Backbone.emulateHTTP) {
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
		return Backbone.ajax(argumentCollection = _.extend(params, options));
	}
}
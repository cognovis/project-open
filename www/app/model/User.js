Ext.define('PO.model.User', {
    extend: 'Ext.data.Model',
    config: {
	fields: [
		'id',
		'first_names',
		'last_name'
	],
	proxy: {
		type:		'rest',
		url:		'/intranet-rest/user',
		appendId:	true,			// Append the object_id: ../im_ticket/<object_id>
		timeout:	300000,

		extraParams: {
			format:		'json',		// Tell the ]po[ REST to return JSON data.
			deref_p:	'0',
			columns:	'first_names,last_name'
		},
		reader: {
			type:	'json',			// Tell the Proxy Reader to parse JSON
			root:	'data',			// Where do the data start in the JSON file?
			totalProperty:  'total'		// Total number of tickets for pagination
		},
			writer: {
			type:	'json'			// Allow Sencha to write ticket changes
		}
	}
    },

    fullName: function() {
	    var d = this.data;
	    return d.first_names + ' ' + d.last_name;
    }

});


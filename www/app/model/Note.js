Ext.define('PO.model.Note', {
    extend: 'Ext.data.Model',
    config: {
	fields: [
		'id',
		'object_name',
		'note_type_id'
	],
	proxy: {
		type:		'rest',
		url:		'/intranet-rest/im_note',
		appendId:	true,			// Append the object_id: ../im_ticket/<object_id>
		timeout:	300000,

		extraParams: {
			format:		'json',		// Tell the ]po[ REST to return JSON data.
			deref_p:	'1',
			columns:	'note_type_id'
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
    }
});


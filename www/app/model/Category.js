Ext.define('PO.model.Category', {
    extend: 'Ext.data.Model',
    config: {
	idProperty:     'category_id',
	fields: [
		 {type: 'string', name: 'category_id'},
		 {type: 'string', name: 'tree_sortkey'},
		 {type: 'string', name: 'category'},
		 {type: 'string', name: 'aux_string1'},
		 {type: 'string', name: 'aux_string2'},
		 {type: 'string', name: 'category_type'},
		 {type: 'string', name: 'category_translated'},
		 {type: 'string', name: 'sort_order'},
		 {type: 'string', name: 'indent_class',
			 // Determine the indentation level for each element in the tree
			 convert: function(value, record) {
			 var category = record.get('category_translated');
			 var indent = (record.get('tree_sortkey').length / 8) - 1;
			 return 'extjs-indent-level-' + indent;
		     }
		 },
		 {type: 'string', name: 'tree_category_translated'}
	],
	proxy: {
		type:		'rest',
		url:		'/intranet-rest/im_category',
		appendId:	true,			// Append the object_id: ../im_ticket/<object_id>
		timeout:	300000,

		extraParams: {
			format:		'json'		// Tell the ]po[ REST to return JSON data.
		},
		reader: {
			type:		'json',		// Tell the Proxy Reader to parse JSON
			rootProperty:	'data',		// Where do the data start in the JSON file?
			totalProperty:  'total'		// Total number of tickets for pagination
		}
	    }
    }

});



var ticketTypeStore = Ext.create('Ext.data.Store', {
		        autoLoad: true,
		        // model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load!!!
		        fields: ['category_id', 'category'],
		        proxy: {
		                type: 'rest',
		                url: '/intranet-rest/im_category',
		                appendId: true,
		                extraParams: {
		                        format: 'json',
					category_type: '\'Intranet Ticket Type\''
		                },
		                reader: { type: 'json', root: 'data' }
		        }
		});


var ticketStatusStore = Ext.create('Ext.data.Store', {
		        autoLoad: true,
		        // model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load!!!
		        fields: ['category_id', 'category'],
		        proxy: {
		                type: 'rest',
		                url: '/intranet-rest/im_category',
		                appendId: true,
		                extraParams: {
		                        format: 'json',
					category_type: '\'Intranet Ticket Status\''
		                },
		                reader: { type: 'json', root: 'data' }
		        }
		});


var ticketPriorityStore = Ext.create('Ext.data.Store', {
		        autoLoad: true,
		        // model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load!!!
		        fields: ['category_id', 'category'],
		        proxy: {
		                type: 'rest',
		                url: '/intranet-rest/im_category',
		                appendId: true,
		                extraParams: {
		                        format: 'json',
					category_type: '\'Intranet Ticket Priority\''
		                },
		                reader: { type: 'json', root: 'data' }
		        }
		});


var ticketPriorityData = [
{"id": "30201", "object_name": "1", "category_id": "30201", "tree_sortkey": "00030201", "category": "1", "category_translated": "1", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30202", "object_name": "2", "category_id": "30202", "tree_sortkey": "00030202", "category": "2", "category_translated": "2", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30203", "object_name": "3", "category_id": "30203", "tree_sortkey": "00030203", "category": "3", "category_translated": "3", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30204", "object_name": "4", "category_id": "30204", "tree_sortkey": "00030204", "category": "4", "category_translated": "4", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30205", "object_name": "5", "category_id": "30205", "tree_sortkey": "00030205", "category": "5", "category_translated": "5", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30206", "object_name": "6", "category_id": "30206", "tree_sortkey": "00030206", "category": "6", "category_translated": "6", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30207", "object_name": "7", "category_id": "30207", "tree_sortkey": "00030207", "category": "7", "category_translated": "7", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30208", "object_name": "8", "category_id": "30208", "tree_sortkey": "00030208", "category": "8", "category_translated": "8", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30209", "object_name": "9", "category_id": "30209", "tree_sortkey": "00030209", "category": "9", "category_translated": "9", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"}
];

var customerContactStore = Ext.create('Ext.data.Store', {
		        autoLoad: true,
		        fields: ['user_id', 'first_names', 'last_name',
				{ name: 'name',
				  convert: function(value, record) {
					return record.get('first_names') + ' ' + record.get('last_name');
				  }
				}
			],
		        proxy: {
		                type: 'rest',
		                url: '/intranet-rest/user',
		                appendId: true,
		                extraParams: {
		                        format: 'json',
					format_variant: 'sencha'
		                },
		                reader: { type: 'json', root: 'data' }
		        }
		});


var employeeStore = Ext.create('Ext.data.Store', {
		        autoLoad: true,
		        fields: ['user_id', 'first_names', 'last_name',
				{ name: 'name',
				  convert: function(value, record) {
					return record.get('first_names') + ' ' + record.get('last_name');
				  }
				}
			],
		        proxy: {
		                type: 'rest',
		                url: '/intranet-rest/user',
		                appendId: true,
		                extraParams: {
		                        format: 'json',
					format_variant: 'sencha'
		                },
		                reader: { type: 'json', root: 'data' }
		        }
		});


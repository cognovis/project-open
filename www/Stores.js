
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


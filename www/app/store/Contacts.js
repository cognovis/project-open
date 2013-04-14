Ext.define('PO.store.Contacts', {
        extend: 'Ext.data.Store',
	config: {
	        fields: ['firstName', 'lastName'],
		sorters: 'firstName',
		grouper: {
		    groupFn: function(record) { return record.get('firstName')[0]; }
	        },
		data: [
		       { firstName: 'Ed',    lastName: 'Spencer' },
		       { firstName: 'Tommy', lastName: 'Maintz' },
		       { firstName: 'Aaron', lastName: 'Conran' },
		       { firstName: 'Jamie', lastName: 'Avins' }
		]

	}
});


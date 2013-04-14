Ext.define('PO.store.Users', {
        extend: 'Ext.data.Store',
	config: {
	        fields: ['first_names', 'last_name'],
		autoLoad: true,
		sorters: 'last_name',

		grouper: {
		    groupFn: function(record) { 
		    	     var fn = record.get('last_name');
			     if (fn == null) { return 'a'; }
		    	     return fn[0]; 
		    }
	        },

		proxy: {
			type: 'rest',
                	url: '/intranet-rest/user',
                	appendId: true,
                	extraParams: {
                        	format: 'json'
                	},
                	reader: { 
				type: 'json', 
				rootProperty: 'data' 
			}
        	}

		/*
		data: [
		       { first_names: 'Ed',    last_name: 'Spencer' },
		       { first_names: 'Tommy', last_name: 'Maintz' },
		       { first_names: 'Aaron', last_name: 'Conran' },
		       { first_names: 'Jamie', last_name: 'Avins' }
		]
		*/
	}
});


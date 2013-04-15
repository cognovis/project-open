Ext.define('PO.store.NoteStore', {
        extend: 'Ext.data.Store',
	storeId: 'noteStore',
	config: {
	    model: 'PO.model.Note',
	    autoLoad: true,
	    sorters: 'last_name',

	    grouper: {
		groupFn: function(record) { 
		    var fn = record.get('note');
		    if (fn == null) { return 'a'; }
		    return fn[0]; 
		}
	    },

	    sorters: [{
		property: 'note',
		direction: 'ASC'
	    }],

	    proxy: {
			type: 'rest',
                	url: '/intranet-rest/im_note',
                	appendId: true,
                	extraParams: {
                        	format: 'json'
                	},
                	reader: { 
				type: 'json', 
				rootProperty: 'data' 
			}
            }

	}
});


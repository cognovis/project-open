Ext.define('PO.store.CategoryNoteTypeStore', {
        extend: 'Ext.data.Store',
	storeId: 'categoryNodeTypeStore',
	config: {
	    model: 'PO.model.Category',
	    autoLoad: true,

	    sorters: [{
                property: 'sort_order',
                direction: 'ASC'
	    }, {
                property: 'tree_sortkey',
                direction: 'ASC'
	    }],

	    proxy: {
			type: 'rest',
                	url: '/intranet-rest/im_category',
                	appendId: true,
                	extraParams: {
		            format: 'json',
			    category_type: '\'Intranet Notes Type\''
                	},
                	reader: { 
				type: 'json', 
				rootProperty: 'data' 
			}
            }

	}
});


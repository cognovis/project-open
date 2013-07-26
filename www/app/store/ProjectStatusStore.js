/*
 * A list of states for projects.
 *
 * ToDo: The list is actually hierarchically.
 */
Ext.define('PO.store.ProjectStatusStore', {
    extend: 'Ext.data.Store',
    storeId: 'projectStatusStore',
    config: {
	model: 'PO.model.Category',
	autoLoad: true,
	sorters: [{
//            property: 'category_translated',
	    property: 'category',
	    direction: 'ASC'
	}],
	proxy: {
	    type: 'rest',
            url: '/intranet-rest/im_category',
            appendId: true,
            extraParams: {
                format: 'json',
		category_type: '\'Intranet Project Status\''
            },
            reader: { type: 'json', rootProperty: 'data' }
        }
    }
});


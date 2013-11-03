Ext.define('PO.store.ProjectTaskStore', {
    extend: 'Ext.data.Store',
    storeId: 'projectTaskStore',
    config: {
	model: 'PO.model.Project',
	autoLoad: true,
	pageSize: 10000,
	
	sorters: [{
	    property: 'project_name',
	    direction: 'ASC'
	}],
	
	proxy: {
	    type: 'rest',
            url: '/intranet-rest/im_project',
            appendId: true,
            extraParams: {
                format: 'json',
		query: 'substring(tree_sortkey for 32) is null'
            },
            reader: { 
		type: 'json', 
		rootProperty: 'data' 
	    }
        }
	
    }
});


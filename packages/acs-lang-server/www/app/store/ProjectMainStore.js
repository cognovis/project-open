Ext.define('PO.store.ProjectMainStore', {
    extend: 'Ext.data.Store',
    storeId: 'projectMainStore',
    config: {
	model: 'PO.model.Project',
	autoLoad: true,
	pageSize: 10000,
	
	grouper: {
	    groupFn: function(record) { 
		var fn = record.get('project_name');
		if (fn == null) { fn = 'a'; }
		return fn.toLowerCase()[0]; 
	    }
	},
	
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
		query: 'parent_id is null and project_status_id in (76)'
            },
            reader: { 
		type: 'json', 
		rootProperty: 'data' 
	    }
        }
	
    }
});


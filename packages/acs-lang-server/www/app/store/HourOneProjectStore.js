/*
 * HourOneProjectStore.js
 * Copyright 2013 ]project-open[
 * Author: Frank Bergmann (frank.bergmann@project-open.com)
 * License: http://www.project-open.org/en/license
 *
 * Stores the hours logged by the current user on a 
 * specific project.
 * The store is designed to be scripted and filtered
 * by a controller.
 * 
*/
Ext.define('PO.store.HourOneProjectStore', {
    extend: 'Ext.data.Store',
    storeId: 'hourOneProjectStore',
    config: {
	model: 'PO.model.Hour',
	autoLoad: false,

	sorters: [{
            property: 'date',
            direction: 'ASC'
        }],

        grouper: {
            groupFn: function(record) {
                return record.get('date');
            }
        },


	// Proxy specifically for this store
	proxy: {
	    type: 'rest',
	    url: '/intranet-rest/im_hour',
	    appendId: true,
	    extraParams: {
		format: 'json',
		user_id: '624',
		project_id: '15751'
	    },
	    reader: {
		type: 'json', 
		rootProperty: 'data' 
	    }
	}
    }
});


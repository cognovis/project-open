/*
 * HourOneDayStore.js
 * Copyright 2013 ]project-open[
 * Author: Frank Bergmann (frank.bergmann@project-open.com)
 * License: http://www.project-open.org/en/license
 *
 * Stores the hours logged by the current user.
 * The store is designed to be scripted and filtered
 * by a controller.
 * 
*/
Ext.define('PO.store.HourOneDayStore', {
    extend: 'Ext.data.Store',
    storeId: 'hourOneDayStore',
    config: {
	model: 'PO.model.Hour',
	autoLoad: false,

	// Proxy specifically for this store: rest_my_timesheet_projects returns 
	// all projects to which the current user has hour logging permissions
	proxy: {
	    type: 'rest',
	    url: '/intranet-rest/im_hour',
	    extraParams: {
		format: 'json',
		day: '2099-12-31',		// to be overwritten by controller
		user_id: 624			// to be overwritten by controller
	    },
	    reader: {
		type: 'json', 
		rootProperty: 'data' 
	    }
	}
    }
});


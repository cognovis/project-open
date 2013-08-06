/*
 * HourDetailListContainer.js
 * (c) 2013 ]project-open[
 * Please see www.project-open.org/en/project_open_license for details
 */

Ext.define('PO.view.HourDetailListContainer', {
    extend: 'Ext.navigation.View',
    xtype: 'hourDetailListContainer',
    requires: [
	'PO.view.HourList'
    ],

    config: {
	title: 'Hour Detail List Container',
	items: [
	    {
		xtype: 'hourPanelDetail'
	    },
	    {
		xtype: 'hourList'
	    }
	]
    }
});

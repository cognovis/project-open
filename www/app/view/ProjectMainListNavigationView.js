/*
 * ProjectMainListNavigationView.js
 * (c) 2013 ]project-open[
 * Please see www.project-open.org/en/project_open_license for details
 */

Ext.define('PO.view.ProjectMainListNavigationView', {
    extend: 'Ext.navigation.View',
    xtype: 'projectMainListNavigationView',
    requires: [
	'PO.view.HourList',
	'PO.view.ProjectMainList',
	'PO.view.ProjectPanelDetail',
	'PO.view.ProjectPanelTimesheet'
    ],

    config: {
	title: 'Main Projects',
	iconCls: 'star',
	items: [{
	    xtype: 'projectMainList'
	}]
    }
});

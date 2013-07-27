/*
 * ProjectNavigationView.js
 * (c) 2013 ]project-open[
 * Please see www.project-open.org/en/project_open_license for details
 */

Ext.define('PO.view.ProjectNavigationView', {
    extend: 'Ext.navigation.View',
    xtype: 'projectNavigationView',
    requires: [
	'PO.view.ProjectList',
	'PO.view.ProjectPanelDetail',
	'PO.view.ProjectPanelTimesheet'
    ],
    config: {
	title: 'Projects',
	iconCls: 'star',
	items: [{
	    xtype: 'projectList'
	}]
    }
});

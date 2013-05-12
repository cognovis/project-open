Ext.define('PO.view.ProjectNavigationView', {
	extend: 'Ext.navigation.View',
	xtype: 'projectNavigationView',
	requires: [
		   'PO.view.ProjectList',
		   'PO.view.ProjectDetail'
	],
	config: {
	    title: 'Projects',
	    iconCls: 'star',
	    items: [{
		    xtype: 'projectList'
	    }]
	}
});

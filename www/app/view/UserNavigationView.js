Ext.define('PO.view.UserNavigationView', {
	extend: 'Ext.navigation.View',
	xtype: 'userNavigationView',
	requires: [
		   'PO.view.UserList',
		   'PO.view.UserDetail'
	],
	config: {
	    title: 'UserNavView',
	    iconCls: 'star',
	    items: [{
		    xtype: 'userList'
	    }]
	}
});

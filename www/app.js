Ext.application({
    name: 'PO',
    requires: [
	'Ext.MessageBox',
	'Ext.data.Store',
	'Ext.List',
	'Ext.plugin.PullRefresh'
    ],

    models: [
	'Category',
	'Note',
	'User'
    ],
    stores: [
	'NoteStore', 
	'UserStore', 
	'ContactStore',
	'CategoryNoteTypeStore'
    ],
    views: [
	'SplashPage', 
	'UserList', 
	'UserDetail', 
	'BlogList', 
	'NoteList', 
	'UserNavigationView', 
	'NoteNavigationView',
	'ContactPage',
    ],
    controllers: [
	'UserNavigationController', 
	'NoteNavigationController'
    ],

    // Main function: Load the various panels
    launch: function() {
	Ext.create("Ext.tab.Panel", {
		fullscreen: true,
		tabBarPosition: 'bottom',
		items: [
			{xtype: 'splashPage'}, 
//			{xtype: 'blogList'}, 
			{xtype: 'noteNavigationView'}, 
			{xtype: 'userNavigationView'}, 
			{xtype: 'contactPage'}
		]
	});
    }
});


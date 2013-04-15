Ext.application({
    name: 'PO',

    models: [
	'Note'
    ],
    stores: [
	'NoteStore'
    ],
    views: [
	'SplashPage', 
	'NoteDetail',
	'NoteList',
	'NoteNavigationView'
    ],
    controllers: [
	'NoteNavigationController'
    ],

    // Main function: Load the various panels
    launch: function() {
	Ext.create("Ext.tab.Panel", {
		fullscreen: true,
		tabBarPosition: 'bottom',
		items: [
			// The application consists of two pages only:
			{xtype: 'splashPage'}, 
			{xtype: 'noteNavigationView'}
		]
	});
    }
});


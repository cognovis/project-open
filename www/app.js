Ext.application({
    name: 'PO',
    models: [
	'Note',
	'Project'
    ],
    stores: [
	'NoteStore',
	'ProjectTimesheetStore'
    ],
    views: [
	'SplashPage', 
	'NoteDetail',
	'NoteList',
	'NoteNavigationView',
	'ProjectDetail',
	'ProjectTimesheet',
	'ProjectList',
	'ProjectNavigationView'
    ],
    controllers: [
	'NoteNavigationController',
	'ProjectNavigationController'
    ],

    viewport: {
	autoMaximize: true
    },

    // Main function: Load the various panels
    launch: function() {
	Ext.create("Ext.tab.Panel", {
	    fullscreen: true,
	    tabBarPosition: 'bottom',
	    items: [
		// The application consists of two pages only:
		{xtype: 'projectNavigationView'},
		{xtype: 'splashPage'}, 
		{xtype: 'noteNavigationView'}
	    ]
	});
    }
});


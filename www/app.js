Ext.application({
    name: 'PO',
    models: [
	'Category',				// Represents states and types of objects
	'Hour',					// Logged timesheet hours
	'Note',					// A simple text note that can be attached to projects or users
	'Project'				// Project or task
    ],
    stores: [
	'ProjectStatusStore',			// List of project states
	'ProjectTypeStore',			// List of project types
	'NoteStore',				// List of global notes
	'HourOneDayStore',			// List of hours per project, day or user (depending on use)
	'HourOneProjectStore',			// List of hours per project, day or user (depending on use)
	'ProjectMainStore',			// List of main projects projects
	'ProjectTimesheetStore'			// List of projects whith hierarchical indent.
						// Includes only projects with permissions for the current user to log hours
    ],
    views: [
	'SplashPage',				// Initial screen with ]po[ logo
	'NoteNavigationView',			// Container for navigation between NoteList and NoteDetail
	'ProjectNavigationView',		// Container for navigation between ProjectList and ProjectTimesheet
	'ProjectMainListNavigationView'
    ],
    controllers: [
	'NoteNavigationController',
	'ProjectMainListController'
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
		{xtype: 'projectMainListNavigationView'},
		{xtype: 'splashPage'}, 
		{xtype: 'noteNavigationView'}
	    ]
	});
    }
});


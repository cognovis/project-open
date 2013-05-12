Ext.define('PO.controller.ProjectNavigationController', {
        extend: 'Ext.app.Controller',
	xtype: 'projectNavigationController',
	config: {
	    refs: {
	    	  projectNavigationView: 'projectNavigationView'
	    },
	    control: {
		'projectNavigationView': {
		    initialize: 'onInitializeNavigationView'
		},
		'projectList': {
		    disclose: 'showDetail'
		}
	    }
	},

	// Initialization of the Container - add a button
	// The NavigationView itself doesn't seem to allow for this type of customization
	onInitializeNavigationView: function(navView) {
	    var navBar = Ext.ComponentQuery.query('projectNavigationView')[0].getNavigationBar();
	    navBar.add({
		        xtype: 'button',
			text: 'New Project',
			align: 'right',
			handler: function() {
			    console.log('ProjectListController: New Project button pressed');
			    navView.push({
				    xtype: 'projectDetail',
				    title: 'New Project'
			    });
		    }
	    });
	},

	// "Disclose" Event - somebody pressed on the -> button at the list
	// Create a new instance of the projectDetail page and push on the top
	// of the stack
	showDetail: function(list, record) { 
	    var view = this.getProjectNavigationView();
	    view.push({
		xtype: 'projectTimesheet',
		record: record
	    });
	}

});


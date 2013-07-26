Ext.define('PO.controller.ProjectNavigationController', {
        extend: 'Ext.app.Controller',
	xtype: 'projectNavigationController',
	config: {
	    refs: {
	    	  projectNavigationView: 'projectNavigationView'
	    },
	    control: {
		'projectList': {
		    disclose: 'showDetail'
		}
	    }
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


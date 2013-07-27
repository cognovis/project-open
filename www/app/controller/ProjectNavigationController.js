Ext.define('PO.controller.ProjectNavigationController', {
    extend: 'Ext.app.Controller',
    xtype: 'projectNavigationController',
    config: {
	refs: {
	    projectNavigationView: 'projectNavigationView'
	},
	control: {
	    'projectTimesheetDataView': {
		disclose: 'showTimesheet',		// Disclose - somebody pressed on the -> button at the list
		itemtap: 'showDetail'		// ItemTap - somebody tapped on the item itself
	    }
	}
    },
    
    // Show the details of the project: Create a new instance of the 
    // projectDetail page and push on the top of the stack
    showDetail: function(list, index, listItem, record, touchEvent) {
	var view = this.getProjectNavigationView();
	view.push({
	    xtype: 'projectPanelDetail',
	    record: record
	});
    },
    
    // Show the timesheet page of the project: Create a new instance of the 
    // projectTimesheet page and push on the top of the stack
    showTimesheet: function(list, record) { 
	var view = this.getProjectNavigationView();
	view.push({
	    xtype: 'projectPanelTimesheet',
	    record: record
	});
    }
});


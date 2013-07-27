Ext.define('PO.view.ProjectTimesheetDataView', {
    extend: 'Ext.DataView',
    xtype: 'projectTimesheetDataView',
    requires: [
	'PO.store.ProjectTimesheetStore', 
	'PO.view.ProjectTimesheetDataViewItem'
    ],
    
    config: {
	title: 'Project List',
	store: 'ProjectTimesheetStore',
	useComponents: true,
	defaultType: 'projectTimesheetDataViewItem',
	deselectOnContainerClick: false
    }

});


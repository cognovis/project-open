/*
 * ProjectPanelDetail.js
 * (c) 2013 ]project-open[
 * Please see www.project-open.org/en/project_open_license for details
 *
 * Detail entry page for a single task, sub-project or main project.
 * Allows the user to log a single timesheet entry.
 */
Ext.define('PO.view.ProjectPanelDetail', {
    extend: 'Ext.form.Panel',
    xtype: 'projectPanelDetail',
    config: {
        title: 'Project Detail',
        layout: 'vbox',
        items: [
	    {
		xtype: 'fieldset',
		title: 'Information',
		items: [
		    {
			xtype: 'textfield',
			name: 'project_name',
			label: 'Project'
		    }, {
			xtype: 'selectfield',
			name: 'project_status_id',
			label: 'Status',
			store: 'ProjectStatusStore'
		    }, {
			xtype: 'selectfield',
			name: 'project_type_id',
			label: 'Type',
			store: 'ProjectTypeStore'
		    }, {
			xtype: 'hiddenfield',
			name: 'id'
		    }, {
			xtype: 'hiddenfield',
			name: 'object_id',
			label: 'Object ID',
			value: 0		// Magic value: 0 is the ID of the "guest" object
		    }
		]
            }, {
		xtype: 'button',
		text: 'Save',
		ui: 'confirm',
		handler: function() {
		    console.log('ProjectPanelDetail: Button "Save" pressed:');
		    
		    // Save the form values to the record.
		    // The record was set by the ProjectNavigationController
		    var form = this.up('formpanel');
		    var values = form.getValues();
		    var rec = form.getRecord();
		    
		    // Did we create a completely new project?
		    if (typeof rec === "undefined" || rec == null) {
			rec = Ext.ModelManager.create(values, 'PO.model.Project');
		    }
		    
		    // Save the model - generates PUT or POST to REST backend
		    rec.set(values);
		    rec.save();
		    
		    // reload the store
		    var projectStore = Ext.data.StoreManager.lookup('ProjectStore');
		    projectStore.load();
		    
		    // Return to the list of projects page
		    var navView = this.up('projectNavigationView');
		    navView.pop();
		}
            }
        ]
    }
});


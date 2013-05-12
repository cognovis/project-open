/*
 * ProjectTimesheet.js
 * (c) 2013 ]project-open[
 * Please see www.project-open.org/en/project_open_license for details
 *
 * Timesheet entry page for a single task, sub-project or main project.
 * Allows the user to log a single timesheet entry.
 */
Ext.define('PO.view.ProjectTimesheet', {
	extend: 'Ext.form.Panel',
	xtype: 'projectTimesheet',
	config: {
                    title: 'Project Timesheet',
                    layout: 'vbox',
                    items: [{
                            xtype: 'fieldset',
                            title: 'Information',
                            items: [{
                                    xtype: 'selectfield',
				    name: 'project_type_id',
				    label: 'Type',
				    options: [
					      {text: 'Address', value: '11500'},
					      {text: 'Email', value: '11502'},
					      {text: 'Http', value: '11504'},
					      {text: 'Ftp', value: '11506'},
					      {text: 'Phone', value: '11508'},
					      {text: 'Fax', value: '11510'},
					      {text: 'Mobile', value: '11512'},
					      {text: 'Other', value: '11514'}
				    ]
                                }, {
                                    xtype: 'textareafield',
				    name: 'project',
                                    label: 'Project'
                                }, {
                                    xtype: 'hiddenfield',
				    name: 'id'
                                }, {
                                    xtype: 'hiddenfield',
				    name: 'project_status_id',
				    value: 11400
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
			        console.log('ProjectTimesheet: Button "Save" pressed:');

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

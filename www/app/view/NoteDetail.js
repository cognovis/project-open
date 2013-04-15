Ext.define('PO.view.NoteDetail', {
	extend: 'Ext.form.Panel',
	xtype: 'noteDetail',
	config: {
                    title: 'Note Detail',
                    layout: 'vbox',
                    items: [{
                            xtype: 'fieldset',
                            title: 'Note Fields',
                            instructions: '(email address is optional)',
                            items: [{
                                    xtype: 'selectfield',
				    name: 'note_type_id',
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
				    name: 'note',
                                    label: 'Note'
                                }, {
                                    xtype: 'hiddenfield',
				    name: 'id'
                                }, {
                                    xtype: 'hiddenfield',
				    name: 'object_id',
                                    label: 'Object ID'
                                }
                            ]
                        }, {
                            xtype: 'button',
                            text: 'Save',
                            ui: 'confirm',
                            handler: function() {
			    	// Save the form values to the record.
				// The record was set by the NoteNavigationController
			        var form = this.up('formpanel');
				var rec = form.getRecord();
				rec.set(form.getValues());
				rec.save();

				// Return to the list of notes page
				var navView = this.up('noteNavigationView');
				navView.pop();
                            }
                        }
                    ]
		}
});

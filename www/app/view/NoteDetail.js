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
				    name: 'note_status_id',
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
			        console.log('NoteDetail: Button "Save" pressed:');

			    	// Save the form values to the record.
				// The record was set by the NoteNavigationController
			        var form = this.up('formpanel');
				var values = form.getValues();
				var rec = form.getRecord();

				// Did we create a completely new note?
				if (typeof rec === "undefined" || rec == null) {
				    rec = Ext.ModelManager.create(values, 'PO.model.Note');
				}

				// Save the model - generates PUT or POST to REST backend
				rec.set(values);
				rec.save();
				
				// reload the store
				var noteStore = Ext.data.StoreManager.lookup('NoteStore');
				noteStore.load();

				// Return to the list of notes page
				var navView = this.up('noteNavigationView');
				navView.pop();
                            }
                        }
                    ]
		}
});

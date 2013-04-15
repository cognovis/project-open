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
                                    xtype: 'textfield',
				    name: 'first_names',
                                    label: 'Name'
                                }, {
                                    xtype: 'emailfield',
				    name: 'email',
                                    label: 'Email'
                                }, {
                                    xtype: 'textareafield',
				    name: 'message',
                                    label: 'Message'
                                }
                            ]
                        }, {
                            xtype: 'button',
                            text: 'Save',
                            ui: 'confirm',
                            handler: function() {
			         // var form = Ext.getCmp('contactFormPanel').getValues();
			         var form = this.up('formpanel');
				 form.submit({
					 method: 'GET',
					 url: 'http://www.project-open.net/intranet-crm-tracking/contact',
					 success: function() {
					     alert('form submitted successfully!');
					 },
					 failure: function() {
					     alert('form submission failed');
					 }
				     });
                            }
                        }
                    ]
	}
});


Ext.define('PO.view.ContactPage', {
	extend: 'Ext.form.Panel',
	xtype: 'contactPage',
	config: {
                    title: 'Contact',
                    iconCls: 'user',
		//                    xtype: 'formpanel',
		    id: 'contactFormPanel',
                    url: 'http://www.project-open.net/intranet-crm-tracking/contact',
                    layout: 'vbox',
                    items: [{
                            xtype: 'fieldset',
                            title: 'Contact Us',
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
                            text: 'Send',
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


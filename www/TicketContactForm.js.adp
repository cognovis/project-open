/**
 * intranet-sencha-ticket-tracker/www/TicketContactForm.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id$
 *
 * Copyright (C) 2011, ]project-open[
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


Ext.define('TicketBrowser.TicketContactForm', {
	extend:		'Ext.form.Panel',
        alias:		'widget.ticketContactForm',
        id:		'ticketContactForm',
	title:		'#intranet-sencha-ticket-tracker.Contacts#',
	frame:		true,
	fieldDefaults: {
		msgTarget:	'side',
		labelWidth:	125,
		width:		300
	},
        items: [{
                name:           'user_id',
                xtype:          'combobox',
                fieldLabel:     '#intranet-core.User#',
                value:          '#intranet-core.New_User#',
		valueNotFoundText: '#intranet-sencha-ticket-tracker.Create_New_User#',
                valueField:     'user_id',
                displayField:   'name',
                store:          userStore,
		listeners:{
		    // The user has selected a user from the drop-down box.
		    // Lookup the user and fill the form with the fields.
		    'select': function() {
			var user_id = this.getValue();
			var user_record = userStore.findRecord('user_id',user_id);
		        if (user_record == null || typeof user_record == "undefined") { return; }
			this.ownerCt.loadRecord(user_record);
		    }
		}
        }, {
               name:           'first_names',
               xtype:          'textfield',
               fieldLabel:     '#intranet-core.First_names#',
               allowBlank:     false
        }, {
                name:           'last_name',
                xtype:          'textfield',
                fieldLabel:     '#intranet-core.Last_name#'
        }, {
                name:           'last_name2',
                xtype:          'textfield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Last_Name2#'
        }, {
                name:           'email',
                xtype:          'textfield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Email#'
        }, {
                name:           'telephone',
                xtype:          'textfield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Telephone#'
	}, {
                name:           'ticket_customer_contact_p',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Primary_Contact#',
                xtype:          'checkbox',
                value:          '1'
	}, {
                name:           'language',
                xtype:          'radiofield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Ticket_Language#',
                boxLabel:       '#intranet-sencha-ticket-tracker.lang_eu_ES#',
                value:          'eu_ES'
        }, {
                name:           'language',
                xtype:          'radiofield',
                boxLabel:       '#intranet-sencha-ticket-tracker.lang_es_ES#',
                value:          'es_ES',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false
	}, {
                name:           'gender',
                xtype:          'radiofield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Gender#',
                boxLabel:       '#intranet-sencha-ticket-tracker.Male#',
                value:          '1'
        }, {
                name:           'gender',
                xtype:          'radiofield',
                boxLabel:       '#intranet-sencha-ticket-tracker.Female#',
                value:          '0',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false
        }],
        buttons: [{
        	text: '#intranet-sencha-ticket-tracker.Add_New_Contact#',
		itemId:	'addButton',
		width: 	100,
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			form.reset();			// empty fields to allow for entry of new contact

			// Button logic:
			this.hide();

			var createButton = this.ownerCt.child('#createButton');
			createButton.show();
			var saveButton = this.ownerCt.child('#saveButton');
			saveButton.hide();
		}
	}, {
        	text: '#intranet-sencha-ticket-tracker.Save_Changes#',
		itemId:	'saveButton',
		width: 	120,
        	handler: function(){
			// Get the values of this form into the "values" object
			var form = this.ownerCt.ownerCt.getForm();
			var combo = form.findField('user_id');
			var user_id = combo.getValue();
			var values = form.getFieldValues();

			// Search for previous row in the store
			var rec = userStore.findRecord('user_id',user_id);

			// overwrite the store data with the new data
			rec.set(values);

			// Tell the store to update the server via it's REST proxy
			userStore.sync();

			// Get the ticket
			var ticketForm = Ext.getCmp('ticketForm');
			var ticket_id_field = ticketForm.getForm().findField('ticket_id');
                        var ticket_id = ticket_id_field.getValue();
                        var ticket_model = ticketStore.findRecord('ticket_id',ticket_id);

			// Mark the user as the ticket's contact
			var ticket_customer_ticket_customer_contact_field = form.findField('ticket_customer_contact_p');
			var ticket_customer_contact_p = ticket_customer_ticket_customer_contact_field.getValue();

			if (true == ticket_customer_contact_p || '1' == ticket_customer_contact_p) {
	                        ticket_model.set('ticket_customer_contact_id', user_id);
        	                ticket_model.save();
			}

			// Tell all panels to load the data of the newly created object
			var compoundPanel = Ext.getCmp('ticketCompoundPanel');
			compoundPanel.loadTicket(ticket_model);	
                }
	}, {
        	text:	'#intranet-sencha-ticket-tracker.Create_New_Contact#',
		itemId:	'createButton',
		width: 	120,
		hidden:	true,
        	handler: function() {
			var form = this.ownerCt.ownerCt.getForm();
			var values = form.getFieldValues();
			values.user_id = null;
			values.first_names = values.first_names + Math.random();
			values.last_name = values.last_name + Math.random();
			values.email = values.first_names + '.' + values.last_name + '@asdf.com';

			// create a new user
			var user_record = Ext.ModelManager.create(values, 'TicketBrowser.User');
			user_record.phantom = true;
			user_record.save({
				scope: Ext.getCmp('ticketContactForm'),
				success: function(record, operation) {
					// This code is called once the reply from the server has arrived.
					try {
						var resp = Ext.decode(operation.response.responseText);
						var user_id = resp.data[0].object_id + '';
					} catch (ex) {
						alert('Error creating object.\nThe server returned:\n' + operation.response.responseText);
						return;
					}

					// update the user_model and add to the store
					var new_user = Ext.ModelManager.getModel('TicketBrowser.User');
					new_user.load(user_id, {
						scope: this,
						success: function(record, operation) {
							userStore.add(record);
						},
						failure: function(record, operation) {
							alert('Error reloading the newly created users from the server.');
						}
					});

					// Store the new user_id into the ticketForm
					var ticketForm = Ext.getCmp('ticketForm');
					var ticket_id_field = ticketForm.getForm().findField('ticket_id');
					var ticket_id = ticket_id_field.getValue();
					var ticket_model = ticketStore.findRecord('ticket_id',ticket_id);
					ticket_model.set('ticket_customer_contact_id', user_id);
					ticket_model.save();

					//  Get the customer_id from the customer panel
					var customerForm = Ext.getCmp('ticketCustomerPanel');
					var customer_id_field = customerForm.getForm().findField('company_id');
					var customer_id = customer_id_field.getValue();
					
					// Create a object_member relationship between the user and the company
					var memberValues = {
						object_id_one:	customer_id,
						object_id_two:	user_id,
						rel_type:	'im_biz_object_member',
						object_role_id:	1300,
						percentage:	''
					};
					var member_model = Ext.ModelManager.create(memberValues, 'TicketBrowser.BizObjectMember');
		                        member_model.phantom = true;
					member_model.save({
						scope: Ext.getCmp('ticketCompoundPanel'),
		                                success: function(record, operation) {
							// reload the entire form
							this.loadTicket(ticket_model);
						}
					});
				}
			});
                }
        }],

	loadTicket: function(rec){
		// Customer contact ID, may be NULL
		var contact_id;
		if (rec.data.hasOwnProperty('ticket_customer_contact_id')) { 
			contact_id = rec.data.ticket_customer_contact_id; 
		}

		var contact_record = userStore.findRecord('user_id',contact_id);
	        if (contact_record == null || typeof contact_record == "undefined") { return; }

		// load the information from the record into the form
		this.loadRecord(contact_record);

		// Show (might have been hidden when creating a new ticket)
		this.show();
	},

	loadUser: function(rec){
		// load the information from the record into the form
		this.loadRecord(rec);
		this.show();
	},

	// Called when the user changed the customer in the TicketCustomerPanel
	loadCustomer: function(customerModel){
		var form = this.getForm();
		form.reset();
	},

        // Somebody pressed the "New Ticket" button:
        // Prepare the form for entering a new ticket
        newTicket: function() {
		var form = this.getForm();
                form.reset();
		this.hide();
        }

});


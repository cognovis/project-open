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
		msgTarget:		'side',
		labelWidth:		125,
		width:			300,
		typeAhead:		true
	},
	items: [{
		name:			'user_id',
		xtype:			'combobox',
		fieldLabel:		'#intranet-core.User#',
		value:			'#intranet-core.New_User#',
		valueNotFoundText:	'#intranet-sencha-ticket-tracker.Create_New_User#',
		valueField:		'user_id',
		displayField:   	'name',
		store:			userCustomerStore,
		enableKeyEvents:	true,
		triggerAction:		'all',
		listeners:{

		 // The user has selected a user from the drop-down box.
		 // Lookup the user and fill the form with the fields.
		 'blur': function(field, event) {

			var user_id = this.getValue();
			var user_record = userStore.findRecord('user_id',user_id);
			if (user_record == null || user_record == undefined) { 
				var user_record = userStore.findRecord('name',user_id);
			}
			if (user_record == null || user_record == undefined) { return; }

			// load the values of the user into the form
			this.ownerCt.loadRecord(user_record);

			// Enable/Disable the "Save" button for anonymous
			var buttonToolbar = this.ownerCt.getDockedComponent(0);
			var saveButton = buttonToolbar.getComponent('saveButton');
			var username = user_record.get('username');
			if (username.indexOf('anon') >= 0) {
				saveButton.hide();
			} else {
				saveButton.show();
			}

		 }
		}
	}, {
		name:		'first_names',
		xtype:		'textfield',
		fieldLabel:	'#intranet-core.First_names#',
		allowBlank:	false
	}, {
		name:		'last_name',
		xtype:		'textfield',
		fieldLabel:	'#intranet-core.Last_name#',
		allowBlank:	false
	}, {
		name:		'last_name2',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Last_Name2#'
	}, {
		name:		'email',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Email#'
	}, {
		name:		'telephone',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Telephone#'
	}, {
		name:		'ticket_customer_contact_p',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Primary_Contact#',
		xtype:		'checkbox',
		value:		true
	}, {
		name:		'language',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_Language#',
		queryMode:	'local',
		valueField:	'iso',
		displayField:	'language',
		triggerAction:	'all',
		store:		new Ext.data.ArrayStore({
					id: 0,
					fields: ['iso', 'language'],
					data: [
						['es_ES', '#intranet-sencha-ticket-tracker.lang_es_ES#'], 
						['eu_ES', '#intranet-sencha-ticket-tracker.lang_eu_ES#']
					]
		})
	}, {
		name:		'gender',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Gender#',
		queryMode:	'local',
		valueField:	'id',
		displayField:	'gender',
		triggerAction:	'all',
		store:		new Ext.data.ArrayStore({
					id: 0,
					fields: ['id', 'gender'],
					data: [
						['male', '#intranet-sencha-ticket-tracker.Male#'], 
						['female', '#intranet-sencha-ticket-tracker.Female#']
					]
		})
	}],
	buttons: [{
		text:		'#intranet-sencha-ticket-tracker.Add_New_Contact#',
		itemId:		'addButton',
		width: 		100,
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
		text:		'#intranet-sencha-ticket-tracker.Save_Changes#',
		itemId:		'saveButton',
		width:		120,
		handler: function(){
			// Get the values of this form into the "values" object
			var form = this.ownerCt.ownerCt.getForm();
			var combo = form.findField('user_id');
			var user_id = combo.getValue();
			var values = form.getFieldValues();

			// Update the model with the form variables and save
			var userModel = userStore.findRecord('user_id',user_id);
			userModel.set(values);
			userModel.save({
				scope: Ext.getCmp('ticketContactForm'),
				success: function(record, operation) {
					this.loadUser(userModel);
				},
				failure: function(record, operation) {
					Ext.Msg.alert('Failed to save user', operation.request.scope.reader.jsonData["message"]);
				}
			});

			// Get the ticket
			var ticketForm = Ext.getCmp('ticketForm');
			var ticket_id = ticketForm.getForm().findField('ticket_id').getValue();
			var ticket_model = ticketStore.findRecord('ticket_id',ticket_id);
			var customer_id = ticket_model.get('company_id');

			// Mark the user as the ticket's contact
			var ticket_customer_contact_p = form.findField('ticket_customer_contact_p').getValue();
			if (true == ticket_customer_contact_p || '1' == ticket_customer_contact_p) {
				ticket_model.set('ticket_customer_contact_id', user_id);
				ticket_model.save({
					scope: Ext.getCmp('ticketContactForm'),
					success: function(record, operation) {
						// Tell all panels to refresh
					},
					failure: function(record, operation) {
						Ext.Msg.alert('Failed to save ticket', operation.request.scope.reader.jsonData["message"]);
					}
				});
			}

			// Add the users as a contact of the company
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
					// reload the entire form AFTER the relationship was saved
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticket_model);	
				},
				failure: function(record, operation) { 
					Ext.Msg.alert('Failed to create company-user relationship', operation.request.scope.reader.jsonData["message"]); 
				}
			});
		}
	}, {
		text:		'#intranet-sencha-ticket-tracker.Create_New_Contact#',
		itemId:		'createButton',
		width: 		120,
		hidden:		true,
		handler: function() {
			var form = this.ownerCt.ownerCt.getForm();
			var values = form.getFieldValues();
			values.user_id = null;
			values.first_names = values.first_names.toUpperCase();
			values.last_name = values.last_name.toUpperCase();
			values.last_name2 = values.last_name2.toUpperCase();

			// Deugging help...
			// values.first_names = values.first_names + Math.random();
			// values.last_name = values.last_name + Math.random();
			// values.email = values.first_names + '.' + values.last_name + '@asdf.com';

			// create a new user
			var userModel = Ext.ModelManager.create(values, 'TicketBrowser.User');
			userModel.phantom = true;
			userModel.save({
				scope: Ext.getCmp('ticketContactForm'),
				success: function(user_record, operation) {

					// Add the new user to the user store to make it accessible
					userStore.add(user_record);
					userCustomerStore.add(user_record);
					var user_id = user_record.get('user_id');

					// Get the ticket model and extract the customer_id
					var ticketForm = Ext.getCmp('ticketForm');
					var ticket_id = ticketForm.getForm().findField('ticket_id').getValue();
					var ticket_model = ticketStore.findRecord('ticket_id',ticket_id);
					var customer_id = ticket_model.get('company_id');


					// Save the new user as the default contact for the ticket.
					// We don't care much if this save was successful - no refresh.
					var ticket_customer_contact_field = this.getForm().findField('ticket_customer_contact_p');
					var ticket_customer_contact_p = ticket_customer_contact_field.getValue();
					if (true == ticket_customer_contact_p || '1' == ticket_customer_contact_p) {
						ticket_model.set('ticket_customer_contact_id', user_id);
						ticket_model.save({
							success: function(record, operation) { 
								// Ext.Msg.alert('ticket_customer_contact_id saved.', operation.request.scope.reader.jsonData["message"]); 
							},
							failure: function(record, operation) { 
								Ext.Msg.alert('Failed to save ticket_customer_contact_id.', operation.request.scope.reader.jsonData["message"]);
							}
						});
					}

					// Create an object_member relationship between the user and the company
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
							// reload the entire form AFTER the relationship was saved
							this.loadTicket(ticket_model);
						},
						failure: function(record, operation) { 
							Ext.Msg.alert('Failed to create company-user relationship', operation.request.scope.reader.jsonData["message"]); 
						}
					});

					// Add the users to the group "Customers".
					// This code doesn't need to be synchronized.
					// The record will establish a "relationship" between the users and a group
					var groupMember = {
						object_id_one:	461,		// group_id for Customers
						object_id_two:	user_id,
						rel_type:	'membership_rel',
						member_state:	'approved'
					};
		
					var groupMemberModel = Ext.ModelManager.create(groupMember, 'TicketBrowser.GroupMember');
					groupMemberModel.phantom = true;
					groupMemberModel.save({
						scope: Ext.getCmp('ticketCompoundPanel'),
						failure: function(record, operation) { 
							Ext.Msg.alert('Failed to create group membership relationship.', operation.request.scope.reader.jsonData["message"]); 
						}
					});
				},
				failure: function(record, operation) {
					Ext.Msg.alert("Error durante la creacion de un nuevo contacto", operation.request.scope.reader.jsonData["message"]);
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
		this.loadUser(contact_record);
		
		//If Ticket is closed, disable the buttons.
		var ticketStatusId=rec.get('ticket_status_id');;
		var buttonToolbar = Ext.getCmp('ticketContactForm').getDockedComponent(0);
		var saveButton = buttonToolbar.getComponent('saveButton');	
		var addButton = buttonToolbar.getComponent('addButton');	
		var createButton = buttonToolbar.getComponent('createButton');	

		if (ticketStatusId == '30001'){
			saveButton.hide();
			addButton.hide();
		} else {
			saveButton.show();
			addButton.show();	
		}		
	},

	loadUser: function(rec){

		// load the information from the record into the form
		this.loadRecord(rec);

		// Show (might have been hidden when creating a new ticket)
		this.show();

		// Reset button config
		var buttonToolbar = this.getDockedComponent(0);
		var addButton = buttonToolbar.getComponent('addButton');
		addButton.show();
		var createButton = buttonToolbar.getComponent('createButton');
		createButton.hide();
		var saveButton = buttonToolbar.getComponent('saveButton');

		var username = rec.get('username');
		if (username.indexOf('anon') >= 0) {
			saveButton.hide();
		} else {
			saveButton.show();
		}

		var form = this.getForm();
		contactField = form.findField('ticket_customer_contact_p');
		contactField.setValue(true);
		
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


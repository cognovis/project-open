/**
 * intranet-sencha-ticket-tracker/www/ContactForm.js
 * Contact form to allow modifying and creating new companies.
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


var contactForm = Ext.define('TicketBrowser.ContactForm', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.contactForm',
	id:		'contactForm',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-sencha-ticket-tracker.Contact#',
	bodyStyle:	'padding:5px 5px 0',
	minHeight:	250,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 75
	},
	defaultType:	'textfield',
	defaults: {
	        mode:           'local',
	        queryMode:      'local',
	        value:          '',
	        displayField:   'pretty_name',
	        valueField:     'id',
		typeAhead:	true
	},
	items: [{
		name: 'user_id',
		xtype: 'hiddenfield'
	}, {
		name:		'first_names',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.First_names#',
		allowBlank:	false
	}, {
		name:		'last_name',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Last_name#',
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
	    itemId:	'saveButton',
            text:	'#intranet-sencha-ticket-tracker.button_Save#',
            disabled:	false,
            formBind:	true,			// Disable if form is invalid
	    handler: function(){

		// get the form and all of its values
		var form = this.up('form').getForm();
		var values = form.getFieldValues();
		var value;
		values.first_names = values.first_names.toUpperCase();
		values.last_name = values.last_name.toUpperCase();
		values.last_name2 = values.last_name2.toUpperCase();
		
		Function_checkValues(values);

		// New or Edit?
		var user_id = form.findField('user_id').getValue();
		if ('' == user_id) {
			// user_id is empty - create a new contact

			// Disable the form until the user_id has arrived
			// Ext.getCmp('contactForm').setDisabled(true);

			// create a new contact
			var contactModel = Ext.ModelManager.create(values, 'TicketBrowser.User');
			contactModel.phantom = true;
			contactModel.save({
				scope: Ext.getCmp('contactForm'),
				success: function(contact_record, operation) {
					// This code is called once the reply from the server has arrived.
					// The server response includes all necessary data for the new object.
					userStore.add(contact_record);

					// Tell all panels to load the data of the newly created object
					var compoundPanel = Ext.getCmp('contactCompoundPanel');
					compoundPanel.loadContact(contact_record);
				},
				failure: function(record, operation) {
					Ext.Msg.alert("Error durante la creacion de un nuevo contact", operation.request.scope.reader.jsonData["message"]);
					// Re-enable this form
					Ext.getCmp('contactForm').setDisabled(false);

					// Return to the main contacts Tab
					var contactContainer = Ext.getCmp('contactContainer');
					var mainTabPanel = Ext.getCmp('mainTabPanel');
					mainTabPanel.setActiveTab(contactContainer);
				}
			});

		} else {

			// Update an existing contact
			// Loop through all form fields and store into the contact store
			var contactModel = userStore.findRecord('user_id',user_id);
			for(var field in values) {
				if (values.hasOwnProperty(field)) {
					value = values[field];
					contactModel.set(field, value);
				}
			}
	
			// Disable this form to indicate the request is working
			// Ext.getCmp('contactForm').setDisabled(true);

			// Tell the store to update the server via it's REST proxy
			contactModel.save({
				scope: Ext.getCmp('contactForm'),
				success: function(record, operation) {
					// Refresh all forms to show the updated information
					var compoundPanel = Ext.getCmp('contactCompoundPanel');
					compoundPanel.loadContact(contactModel);
				},
				failure: function(record, operation) {
					Ext.Msg.alert('Failed to save contact', operation.request.scope.reader.jsonData["message"]);
				}
			});
		}
	    }
	}],

	loadContact: function(rec){
		// Show this contact, in case it was disabled before
		this.setDisabled(false);
		// load the data from the record into the form
		this.loadRecord(rec);
	},

	// Somebody pressed the "New Contact" button:
	// Prepare the form for entering a new contact
	newContact: function() {
	        var form = this.getForm();
	        form.reset();
	}
});


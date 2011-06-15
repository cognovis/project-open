/**
 * intranet-sencha-ticket-tracker/www/TicketContactForm.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketContactForm.js.adp,v 1.2 2011/06/15 16:11:47 po34demo Exp $
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
                name:           'ticket_language',
                xtype:          'radiofield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Ticket_Language#',
                boxLabel:       '#intranet-sencha-ticket-tracker.lang_eu_ES#',
                value:          'eu_ES'
        }, {
                name:           'ticket_language',
                xtype:          'radiofield',
                boxLabel:       '#intranet-sencha-ticket-tracker.lang_es_ES#',
                value:          'es_ES',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false
	}, {
                name:           'ticket_sex',
                xtype:          'radiofield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Gender#',
                boxLabel:       '#intranet-sencha-ticket-tracker.Male#',
                value:          '1'
        }, {
                name:           'ticket_sex',
                xtype:          'radiofield',
                boxLabel:       '#intranet-sencha-ticket-tracker.Female#',
                value:          '0',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false
        }],
        buttons: [{
        	text: '#intranet-sencha-ticket-tracker.button_New_Contact#',
		width: 	100,
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			form.reset();			// empty fields to allow for entry of new contact
			var combo = form.findField('user_id');
		}
	}, {
        	text: '#intranet-sencha-ticket-tracker.button_Save_Changes#',
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

			// force reload of the drop-down
			delete combo.lastQuery;

                }
	}, {
        	text: '#intranet-sencha-ticket-tracker.Create_New_Contact#',
		width: 	120,
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			var combo = form.findField('user_id');
			var values = form.getFieldValues();
			values.user_id = null;

			var user = Ext.ModelManager.create(values, 'TicketBrowser.User');
			user.phantom = true;
			user.save();

			// add the form values to the store.
			userStore.add(user);
			// the store should create a new object now (does he?)

			// Tell the store to update the server via it's REST proxy
			userStore.sync();

			// force reload of the drop-down
			delete combo.lastQuery;
                }
        }],

	loadTicket: function(rec){
		// Customer contact ID, may be NULL
		var contact_id;
		if (rec.data.hasOwnProperty('ticket_customer_contact_id')) { contact_id = rec.data.ticket_customer_contact_id; }

		var contact_record = userStore.findRecord('user_id',contact_id);
	        if (contact_record == null || typeof contact_record == "undefined") { return; }

		// load the information from the record into the form
		this.loadRecord(contact_record);
	},

	loadUser: function(rec){
		// load the information from the record into the form
		this.loadRecord(rec);
	},

        // Somebody pressed the "New Ticket" button:
        // Prepare the form for entering a new ticket
        newTicket: function() {
		var form = this.getForm();
                form.reset();
        }

});


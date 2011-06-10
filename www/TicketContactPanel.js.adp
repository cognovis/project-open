/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketContactPanel.js.adp,v 1.12 2011/06/10 14:24:05 po34demo Exp $
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


Ext.define('TicketBrowser.TicketContactPanel', {
	extend:		'Ext.form.Panel',
        alias:		'widget.ticketContactPanel',
        id:		'ticketContactPanel',
	title:		'Ticket Contact',
	frame:		true,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 125
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
            xtype:	'fieldset',
            title:	'#intranet-sencha-ticket-tracker.User_Information#',
            checkboxToggle: false,
            defaultType: 'textfield',
            collapsed:	false,
	    frame:	false,
            layout: 	'hbox',
            defaults:	{ anchor: '50%'  },
            items :[{
	                name:           'first_names',
	                xtype:          'textfield',
	                fieldLabel:     '#intranet-core.First_names#',
	                allowBlank:     false
	        }, {
	                name:           'last_name',
	                xtype:          'textfield',
	                fieldLabel:     '#intranet-core.Last_name#'
	    }]
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
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			form.reset();			// empty fields to allow for entry of new contact
			var combo = form.findField('user_id');
		}
	}, {
        	text: '#intranet-sencha-ticket-tracker.button_Save_Changes#',
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
		var contact_id = rec.data.ticket_customer_contact_id;
		var contact_record = userStore.findRecord('user_id',contact_id);
	        if (contact_record == null || typeof contact_record == "undefined") { return; }

		// load the information from the record into the form
		this.loadRecord(contact_record);
	},

        // Somebody pressed the "New Ticket" button:
        // Prepare the form for entering a new ticket
        newTicket: function() {
		var form = this.getForm();
                form.reset();
        }

});


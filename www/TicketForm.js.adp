/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketForm.js.adp,v 1.21 2011/06/14 16:10:51 po34demo Exp $
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

var ticketInfoPanel = Ext.define('TicketBrowser.TicketForm', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.ticketForm',
	id:		'ticketForm',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-core.Ticket#',
	bodyStyle:	'padding:5px 5px 0',
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
	        valueField:     'id'
	},
	items: [

	// Variables for the new.tcl page to recognize an ad_form
	{ name: 'ticket_id',		xtype: 'textfield', disabled: true },
	{ name: 'ticket_status_id',	xtype: 'hiddenfield', value: 30000 },
	{ name: 'ticket_name',		xtype: 'hiddenfield' },
	{ name: 'ticket_sla_id',	xtype: 'hiddenfield', value: 53349 },
	{ name: 'parent_id',		xtype: 'hiddenfield', value: 53349 },

	// Main ticket fields
	{
		name: 'project_name', 
		fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_Name#',
		disabled:	false,
        	width: 		300
	}, {
	        fieldLabel:	'#intranet-helpdesk.Ticket_type#',
		name:		'ticket_type_id',
		xtype:		'combobox',
        	width: 		300,
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		queryMode: 	'remote',
		store: 		ticketTypeStore
	}, {
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Area#',
		name:		'ticket_area_id',
		xtype:		'combobox',
        	width: 		300,
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		queryMode: 	'remote',
		store: 		ticketAreaStore
	}, {
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_File_Number#',
	        name:		'ticket_file',
        	width: 		300,
	        xtype:		'textfield'
	}],

	buttons: [{
	    itemId:	'saveButton',
            text:	'#intranet-sencha-ticket-tracker.button_Save#',
            disabled:	false,
            formBind:	true,
	    handler: function(){

		// get the form and all of its values
		var form = this.up('form').getForm();
		var values = form.getFieldValues();
		var value;

		// find out the ticket_id
		var ticket_id_field = form.findField('ticket_id');
		var ticket_id = ticket_id_field.getValue();

		if ('' == ticket_id) {

			// create a new ticket
			var ticket_record = Ext.ModelManager.create(values, 'TicketBrowser.Ticket');
			ticket_record.phantom = true;
			ticket_record.save({
				scope: Ext.getCmp('ticketForm'),
				success: function(record, operation) {
					// This code is called once the reply from the server has arrived.
					// The server response includes data.object_id for the new object.
					try {
						var resp = Ext.decode(operation.response.responseText);
						var ticket_id = resp.data.object_id;
					} catch (ex) {
						alert('Error creating object.\nThe server returned:\n' + operation.response.responseText);
						return;
					}

					// Extract all fields of the new object, including the ones in this form.
					var ticketForm = Ext.getCmp('ticketForm').getForm();
					var form_values = ticketForm.getFieldValues();
					form_values.ticket_id = ticket_id;

					// Tell all panels to load the data of the newly created object
					var ticket_model= Ext.ModelManager.create(form_values, 'TicketBrowser.Ticket');
					ticketStore.add(ticket_model);
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticket_model);	
				}
			});

		} else {

			// Update an existing ticket
			// Loop through all form fields and store into the ticket store
			var ticket_record = ticketStore.findRecord('ticket_id',ticket_id);
			for(var field in values) {
				if (values.hasOwnProperty(field)) {
					value = values[field];
					ticket_record.set(field, value);
				}
			}
	
			// Tell the store to update the server via it's REST proxy
			ticketStore.sync();

			// Update this and the other ticket forms
			var compoundPanel = Ext.getCmp('ticketCompoundPanel');
			compoundPanel.loadTicket(ticket_record);

		}
	    }
	}],

	loadTicket: function(rec){
		this.loadRecord(rec);
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
	        var form = this.getForm();
	        form.reset();
		this.setNewTicketName();
	},
	
	setNewTicketName: function() {
		// Use TCL function to create the next ticket Nr
	        var form = this.getForm();
		var name = '#intranet-sencha-ticket-tracker.New_Ticket_Prefix#' + '<%= [im_ticket::next_ticket_nr] %>';
		form.findField('project_name').setValue(name);
	}
});


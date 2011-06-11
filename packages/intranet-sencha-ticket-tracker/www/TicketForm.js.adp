/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketForm.js.adp,v 1.14 2011/06/10 14:24:05 po34demo Exp $
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
	{ name: 'form:id',		xtype: 'hiddenfield', value: 'helpdesk_ticket' },
	{ name: '__key_signature',	xtype: 'hiddenfield', value: '530 0 DC49DED6D708DC86A6A618E7A482E7050FB53ACB' },
	{ name: '__key',		xtype: 'hiddenfield', value: 'ticket_id' },
	{ name: '__new_p',		xtype: 'hiddenfield', value: '0' },
	{ name: '__refreshing_p',	xtype: 'hiddenfield', value: '0' },
	{ name: 'ticket_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_status_id',	xtype: 'hiddenfield', value: '30000' },
	{ name: 'ticket_name',		xtype: 'hiddenfield', value: 'sencha' },
	{ name: 'ticket_sla_id',	xtype: 'hiddenfield', value: '53349' },

	// tell the /intranet-helpdesk/new page to return JSON
	{ name: 'format',			xtype: 'hiddenfield', value: 'json' },

	// Main ticket fields
	{ name: 'project_name', fieldLabel: '#intranet-helpdesk.Ticket_Name#' },
	{ name: 'parent_id',		xtype: 'hiddenfield' },
	{
	        fieldLabel: '#intranet-sencha-ticket-tracker.Service_Type#',
		name: 'ticket_service_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
	}, {
	        fieldLabel: '#intranet-helpdesk.Ticket_type#',
		name: 'ticket_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
	}, {
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_File_Number#',
	        name:		'ticket_file',
	        xtype:		'textfield'
	}, {
        	fieldLabel:	'#intranet-sencha-ticket-tracker.Area#',
        	name:		'ticket_area',
        	xtype:          'combobox',
        	valueField:     'category_id',
        	displayField:   'category_translated',
        	valueField:     'id',
        	triggerAction:  'all',
        	width: 		300,
        	editable:       false,
        	queryMode:      'remote',
        	store:          requestAreaStore
	}, {
        	fieldLabel:     '#intranet-sencha-ticket-tracker.Program#',
        	name:           'ticket_program_id',
        	xtype:          'combobox',
        	valueField:     'category_id',
        	displayField:   'category_translated',
        	valueField:     'id',
        	triggerAction:  'all',
        	width: 		320,
        	editable:       false,
        	queryMode:      'remote',
        	store:          requestAreaProgramStore,
		listeners:{
		    // The user has selected a program from the drop-down box.
		    // Lookup the area (parent of program) and fill the form with the fields.
		    'select': function() {
			var program_id = this.getValue();
			var area = requestAreaProgramStore.findRecord('id',program_id);
		        if (area == null || typeof area == "undefined") { return; }
			this.ownerCt.loadRecord(area);
		    }
		}
	},

	// Additional fields to add later
	{ name: 'ticket_assignee_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_dept_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_hardware_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_application_id',	xtype: 'hiddenfield'},
	{ name: 'ticket_queue_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_alarm_date',		xtype: 'hiddenfield'},
	{ name: 'ticket_alarm_action',		xtype: 'hiddenfield'},
	{ name: 'ticket_note',			xtype: 'hiddenfield'},
	{ name: 'ticket_conf_item_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_component_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_description',		xtype: 'hiddenfield'},
	{ name: 'ticket_customer_deadline', 	xtype: 'hiddenfield'},
	{ name: 'ticket_closed_in_1st_contact_p', xtype: 'hiddenfield'}
	],

	buttons: [{
            text: '#intranet-sencha-ticket-tracker.button_Save#',
            disabled: false,
            formBind: true,
	    handler: function(){
		var form = this.up('form').getForm();

		var ticket_name_field = form.findField('ticket_name');
		var project_name_field = form.findField('project_name');
		ticket_name_field.setValue(project_name_field.getValue());

		form.submit({
                    url: '/intranet-helpdesk/new',
		    method: 'GET',
                    submitEmptyText: false,
                    waitMsg: '#intranet-sencha-ticket-tracker.Saving_Data#'
		});
	    }
	}],

	loadTicket: function(rec){
		this.loadRecord(rec);
		var comp = this.getComponent('ticket_type_id');
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
	        var form = this.getForm();
	        form.reset();
		// Use TCL function to create the next ticket Nr
		var name = '#intranet-helpdesk.Ticket#' + ' <%= [im_ticket::next_ticket_nr] %>';
		form.findField('project_name').setValue(name);
	}
});


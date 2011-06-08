/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketForm.js.adp,v 1.4 2011/06/08 17:54:22 po34demo Exp $
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
	alias: 		'widget.ticketInfo',
	minHeight:	200,
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-helpdesk.Ticket#',
	bodyStyle:	'padding:5px 5px 0',
	width: 		350,
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
	{ name: 'ticket_name',		xtype: 'hiddenfield', value: 'sencha' },
	{ name: 'ticket_sla_id',	xtype: 'hiddenfield', value: '53349' },

	// tell the /intranet-helpdesk/new page to return JSON
	{ name: 'format',			xtype: 'hiddenfield', value: 'json' },

	// Main ticket fields
	{ name: 'project_name', fieldLabel: 'Name' },
	{ name: 'parent_id', fieldLabel: 'SLA', allowBlank:false},
	{ name: 'ticket_customer_contact_id',	xtype: 'combobox',
		fieldLabel: 'Customer Contact',
                valueField: 'user_id',
                displayField: 'name',
		forceSelection: true,
		queryMode: 'remote',
		store: userStore
	}, {
	        fieldLabel: '#intranet-helpdesk.Ticket_type#',
		name: 'ticket_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
	}, {
	        fieldLabel:	'Expediente',
	        name:		'ticket_file',
	        xtype:		'textfield'
	}, {
        	fieldLabel:	'Area',
        	name:		'ticket_area',
	        xtype:		'textfield'
	}, {
		fieldLabel: 'Status',
		name: 'ticket_status_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketStatusStore
	}, {
		fieldLabel: 'Prio',
		name: 'ticket_prio_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketPriorityStore
	}, {
		xtype: 'timefield',
		fieldLabel: 'Time',
		name: 'time',
		minValue: '8:00am',
		maxValue: '6:00pm'
	}, {
        	fieldLabel:     '#intranet-core.Program#',
        	name:           'ticket_program_id',
        	xtype:          'combobox',
        	valueField:     'category_id',
        	displayField:   'category',
        	valueField:     'id',
        	triggerAction:  'all',
        	forceSelection: true,
        	editable:       false,
        	queryMode:      'remote',
        	store:          'requestAreaStore'
	}, {
	        fieldLabel:	'Tipo de Servicio',
	        name:		'ticket_service_id',
	        xtype:		'combobox',
	        valueField:	'category_id',
	        displayField:	'category',
	        forceSelection: true,
	        queryMode: 	'remote',
	        store: 		ticketServiceTypeStore
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
            text: 'Submit',
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
                    waitMsg: 'Saving Data...'
		});
	    }
	}],

	loadTicket: function(rec){
		this.loadRecord(rec);
		var comp = this.getComponent('ticket_type_id');
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	onNewTicket: function() {
	        var form = this.getForm();
	        form.reset();
	        alert('New Ticket');
	}
});


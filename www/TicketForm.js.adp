/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketForm.js.adp,v 1.1 2011/06/03 08:38:00 po34demo Exp $
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

Ext.define('TicketBrowser.TicketForm', {
	extend: 'Ext.form.Panel',	
	alias: 'widget.ticketform',
	minHeight: 200,
	stanardsubmit:false,
	frame:true,
	title: 'Ticket',
	bodyStyle:'padding:5px 5px 0',
	width: 350,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 75
	},
	defaultType: 'textfield',
	defaults: { anchor: '100%' },
	items: [

	// Variables for the new.tcl page to recognize an ad_form
	{ name: 'form:id',			xtype: 'hiddenfield', value: 'helpdesk_ticket' },
	{ name: '__key_signature',		xtype: 'hiddenfield', value: '530 0 DC49DED6D708DC86A6A618E7A482E7050FB53ACB' },
	{ name: '__key',			xtype: 'hiddenfield', value: 'ticket_id' },
	{ name: '__new_p',			xtype: 'hiddenfield', value: '0' },
	{ name: '__refreshing_p',		xtype: 'hiddenfield', value: '0' },
	{ name: 'ticket_id',			xtype: 'hiddenfield'},
	{ name: 'ticket_name',			xtype: 'hiddenfield', value: 'sencha' },
	{ name: 'ticket_sla_id',		xtype: 'hiddenfield', value: '53349' },

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
		store: customerContactStore
	}, {
		fieldLabel: 'Type',
		name: 'ticket_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
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
	},

	// Additional fields to add later
	{ name: 'ticket_assignee_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_dept_id',		xtype: 'hiddenfield'},
	{ name: 'ticket_service_id',		xtype: 'hiddenfield'},
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

	loadTicket: function(rec){
		this.loadRecord(rec);
		var comp = this.getComponent('ticket_type_id');
	},

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
	}]
});

/**
 * intranet-sencha-ticket-tracker/www/TicketFormRight.js
 * Ticket form to allow modifying the "right hand side"
 * of an existing ticket
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketFormRight.js.adp,v 1.7 2011/06/10 14:24:05 po34demo Exp $
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

var ticketInfoPanel = Ext.define('TicketBrowser.TicketFormRight', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.ticketFormRight',
	id:		'ticketFormRight',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-core.Ticket#',
	bodyStyle:	'padding:5px 5px 0',
	width:		800,

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
	{ name: 'format',		xtype: 'hiddenfield', value: 'json' },

	// Main ticket fields
	{ name: 'project_name',		xtype: 'hiddenfield' },
	{ name: 'parent_id',		xtype: 'hiddenfield' },
	{ name: 'ticket_type_id',	xtype: 'hiddenfield' },

        {
	    xtype:	'fieldset',
            title:	'',
            checkboxToggle: false,
            collapsed:	false,
	    frame:	false,
	    width:	800,

            layout: 	{ type: 'table', columns: 3 },
            items :[{
	                name:           'creation_date',
	                xtype:          'datefield',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Creation_Date#'
	        }, {
	                name:           'ticket_channel_id',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Incoming_Channel#',
		        xtype:		'combobox',
		        valueField:	'category_id',
		        displayField:	'category_translated',
		        forceSelection: true,
		        queryMode: 	'remote',
		        store: 		ticketChannelStore
	        }, {
	                name:           'ticket_channel_detail_id',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Channel_Details#',
		        xtype:		'combobox',
		        valueField:	'category_id',
		        displayField:	'category_translated',
		        forceSelection: true,
		        queryMode: 	'remote',
		        store: 		ticketServiceTypeStore
	        }, {
	                name:           'ticket_done_date',
	                xtype:          'datefield',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Close_Date#'
	        }, {
	                name:           'ticket_escalation_date',
	                xtype:          'datefield',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Escalation_Date#'
	        }, {
	                name:           'ticket_reaction_date',
	                xtype:          'datefield',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Reaction_Date#',
	    }]
	},

        {
	    xtype:	'fieldset',
            title:	'',
            checkboxToggle: false,
            collapsed:	false,
	    frame:	false,
	    width:	800,

            layout: 	{ type: 'table', columns: 2 },
            items :[{
	                name:           'ticket_note',
			xtype:		'textareafield',
			fieldLabel:	'#intranet-sencha-ticket-tracker.Request#',
			width:		400
	        }, {
	                name:           'ticket_resolution',
			xtype:		'textareafield',
			fieldLabel:	'#intranet-sencha-ticket-tracker.Resolution#',
			width:		400
	    }]
	},

        {
	    xtype:	'fieldset',
            title:	'',
            checkboxToggle: false,
            collapsed:	false,
	    frame:	false,
	    width:	800,

            layout: 	{ type: 'table', columns: 3 },
            items :[{
			name:		'ticket_closed_in_1st_contact_p',
			xtype:		'checkbox',
			fieldLabel:     '#intranet-core.lt_Closed_in_1st_Contact#',
			value:		'1',
			width:		150
	    }, {
			name:		'ticket_requires_addition_info_p',
			xtype:		'checkbox',
			fieldLabel:     '#intranet-sencha-ticket-tracker.Requires_additional_info#',
			value:		'1',
			width:		150
	        }, {
	                name:           'ticket_exit_channel_id',
	                fieldLabel:     '#intranet-sencha-ticket-tracker.Outgoing_Channel#',
		        xtype:		'combobox',
		        valueField:	'category_id',
		        displayField:	'category_translated',
		        forceSelection: true,
		        queryMode: 	'remote',
		        store: 		ticketServiceTypeStore
	    }]

	}, {

	    xtype:	'fieldset',
            title:	'',
            checkboxToggle: false,
            collapsed:	false,
	    frame:	false,
	    width:	800,

            layout: 	{ type: 'table', columns: 2 },
            items :[{
			fieldLabel: '#intranet-core.Status#',
			name: 'ticket_status_id',
			xtype: 'combobox',
	                valueField: 'category_id',
	                displayField: 'category_translated',
			forceSelection: true,
			queryMode: 'remote',
			store: ticketStatusStore,
			width: 200
	    }, {
			fieldLabel: '#intranet-sencha-ticket-tracker.Escalated#',
			name: 'ticket_queue_id',
			xtype: 'combobox',
	                valueField: 'group_id',
	                displayField: 'group_name',
			forceSelection: true,
			queryMode: 'remote',
			store: ticketQueueStore,
			width: 300
	    }]
	},

	// SPRI specific fields
	{ name: 'ticket_file',		xtype: 'hiddenfield' },
	{ name: 'ticket_area',		xtype: 'hiddenfield' },
	{ name: 'ticket_status_id',	xtype: 'hiddenfield' },
	{ name: 'ticket_program_id',	xtype: 'hiddenfield' },
	{ name: 'ticket_service_id',	xtype: 'hiddenfield' },

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
	}
});


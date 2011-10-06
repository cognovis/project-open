/**
 * intranet-sencha-ticket-tracker/www/TicketFormRight.js
 * Ticket form to allow modifying the "right hand side"
 * of an existing ticket
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

var ticketInfoPanel = Ext.define('TicketBrowser.TicketFormRight', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.ticketFormRight',
	id:		'ticketFormRight',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-sencha-ticket-tracker.Ticket#',
	bodyStyle:	'padding:5px 5px 0',
	width:		800,
	monitorValid:	true,
	layout: {
	    type: 'vbox',
	    align : 'stretch',
	    pack  : 'start'
	},

	fieldDefaults: {
		msgTarget:	'side',
		labelWidth:	100,
		typeAhead:	true
	},
	defaultType:	'textfield',
	defaults: {
		mode:		'local',
		queryMode:	'local',
		value:		'',
		displayField:   'pretty_name',
		valueField:	'id'
	},
	items: [

		// tell the /intranet-helpdesk/new page to return JSON
		{ name: 'format',		xtype: 'hiddenfield', value: 'json' },
	
		// Variables for the new.tcl page to recognize an ad_form
		{ name: 'ticket_id',		xtype: 'hiddenfield' },
		{ name: 'ticket_last_queue_id',	xtype: 'hiddenfield' },
		{ name: 'ticket_org_queue_id',	xtype: 'hiddenfield' },	// original queue_id from DB when loading the form.
	
		// Main ticket fields
		{
			xtype:		'fieldset',
			title:		'',
			checkboxToggle: false,
			collapsed:	false,
			frame:		false,
			flex: 2,
			layout: 	{ type: 'table', columns: 3 },
			defaults: {		
				margin: '5 50 0 0',
				listeners: {
							change: function (field,newValue,oldValue) {
								 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
							}
				}					
			},
			items :[{
				name:		'ticket_creation_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Creation_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false,
				validator: function(value){
					if (!dateFormat.test(value)) {
						return 'Formato no válido';
					}
					return true;
				}						
			}, {
				name:		'ticket_escalation_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Escalation_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false,
				validator: function(value){
					if (!dateFormat.test(value)) {
						return 'Formato no válido';
					}
					return true;
				}				
			}, {
				name:		'ticket_done_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Close_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false,		
				validator: function(value){
					if (!dateFormat.test(value)) {
						return 'Formato no válido';
					}
					return true;
				}						
			}, {
				name:		'ticket_incoming_channel_id',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Incoming_Channel#',
				xtype:		'combobox',
				valueField:	'category_id',
				displayField:	'category_translated',
				forceSelection: true,
				queryMode: 	'local',
				store: 		ticketOriginStore,
				allowBlank: false,
				listConfig: {
					getInnerTpl: function() {
						return '<div class={indent_class}>{category_translated}</div>';
					}
				},
				validator: function(value){
					return this.store.validateLevel(this.value,this.allowBlank)
				}						
			}, {
				name:		'ticket_reaction_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Reaction_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false,
				validator: function(value){
					if (!dateFormat.test(value)) {
						return 'Formato no válido';
					}
					return true;
				}						
			}]
	
		}, {
	
			xtype:		'fieldset',
			title:		'',
			checkboxToggle: false,
			collapsed:	false,
			frame:		false,
			flex: 3,		
			layout: 	{ 
		    type: 'hbox',
    		pack: 'start',
		    align: 'stretch'		    
		  },
			defaults: {		
				margin: '5 10 0 0',
				listeners: {
							change: function (field,newValue,oldValue) {
								 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
							}
				}					
			},			
			items :[{
				name:		'ticket_request',
				xtype:		'textareafield',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Request#',
				labelAlign:	'top',
				flex: 2
			}, {
				name:		'ticket_resolution',
				xtype:		'textareafield',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Resolution#',
				labelAlign:	'top',
				flex: 2
			}]
	
		}, {
			xtype:		'fieldset',
			title:		'',
			checkboxToggle: false,
			collapsed:	false,
			frame:		false,
		//	width:		800,
			flex: 2,
	
			layout: 	{ type: 'table', columns: 3 },
			defaults: {	
				listeners: {
							change: function (field,newValue,oldValue) {
								 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
							}
				}					
			},				
			items :[{
				name:		'ticket_closed_in_1st_contact_p',
				xtype:		'checkbox',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Closed_in_1st_Contact#',
				inputValue:	't',
				width:		150,
				handler: function(checkbox, checked) {
					// Set status to "closed" if checked by the user
					var panel = this.ownerCt.ownerCt;
					if (checked && panel.rendered) {
						var statusField = panel.getForm().findField('ticket_status_id');
						statusField.setValue('30001');

						// Set the creation done_date of the ticket
						Ext.Ajax.request({
							scope:	panel.getForm(),
							url:	'/intranet-sencha-ticket-tracker/today-date-time',
							success: function(response) {		// response is the current date-time
								var doneField = this.findField('ticket_done_date');
								doneField.setValue(response.responseText);
								doneField.setDisabled(false);
							}
						});

					}
				}
			}, {
				name:		'ticket_requires_addition_info_p',
				xtype:		'checkbox',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Requires_additional_info#',
				inputValue:	't',
				width:		150,
				handler: function(checkbox, checked) {
					// Set status to "frozen" if checked by the user
					var panel = this.ownerCt.ownerCt;
					if (checked && panel.rendered) {
						var statusField = panel.getForm().findField('ticket_status_id');
						statusField.setValue('30028');
					}
				}
			}, {
				name:		'ticket_outgoing_channel_id',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Outgoing_Channel#',
				xtype:		'combobox',
				valueField:	'category_id',
				displayField:	'category_translated',
				forceSelection: true,
				queryMode: 	'local',
				store: 		ticketOriginStore,
				listConfig: {
					getInnerTpl: function() {
						return '<div class={indent_class}>{category_translated}</div>';
					}
				},
				validator: function(value){
					return this.store.validateLevel(this.value,this.allowBlank)
				}						
			}]
	
		}, {
			xtype:		'fieldset',
			title:		'',
			checkboxToggle: false,
			collapsed:	false,
			frame:		false,
			flex: 2,
		//	width:		800,
			layout: 	{ type: 'table', columns: 2 },
			defaults: {	
				margin: '5 10 0 0',
				listeners: {
							change: function (field,newValue,oldValue) {
								 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
							}
				}					
			},				
			items :[{
				fieldLabel:	'#intranet-sencha-ticket-tracker.Status#',
				name:		'ticket_status_id',
				xtype:		'combobox',
				valueField:	'category_id',
				displayField:	'category_translated',
				forceSelection: true,
				queryMode:	'local',
				allowBlank: false,
				store:		ticketStatusStore,
				width:		200,
				listeners:{
				    // Handle special "Esclation" date + field entable
				    'select': function(field, values) {
					var panel = this.ownerCt.ownerCt;
					if (!panel.rendered) { return; }		// Skip action while form is still rendering
					var value = field.getValue();
					var queueField = panel.getForm().findField('ticket_queue_id');

					// by default hide the Queue field, unless there is a specific status
					queueField.hide();

					switch (value) {
						case '30001':		// closed
						case '30022':		// sign-off
						case '30096':		// resolved
							// Set the done_date of the ticket
							Ext.Ajax.request({
								scope:	panel.getForm(),
								url:	'/intranet-sencha-ticket-tracker/today-date-time',
								success: function(response) {		// response is the current date-time
									var doneField = this.findField('ticket_done_date');
									doneField.setValue(response.responseText);
									doneField.setDisabled(false);
								}
							});
		
							break;
						case '30009':		// escalated
						case '30011':		// assigned
							// Enable the tickte_queue_id to define the escalation group
							queueField.store = programGroupStore;
							delete queueField.lastQuery;
							queueField.show();
	
							// Set the escalation_date
							Ext.Ajax.request({
								scope:	panel.getForm(),
								url:	'/intranet-sencha-ticket-tracker/today-date-time',
								success: function(response) {		// response is the current date-time
									var escalationField = this.findField('ticket_escalation_date');
									escalationField.setValue(response.responseText);
									escalationField.setDisabled(false);
								}
							});
							break;
					};

				    },
					change: function (field,newValue,oldValue) {
						 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
					}				    
				}
			}, {
				fieldLabel:	'#intranet-sencha-ticket-tracker.Escalated#',
				name:		'ticket_queue_id',
				xtype:		'combobox',
				valueField:	'group_id',
				displayField:	'group_name',
				forceSelection: true,
				hidden:		true,
				queryMode:	'local',
				store:		programGroupStore,	// Filtered list of profiles
				width:		300
			}]
		}
	],

	loadTicket: function(rec){
		var form = this.getForm();
		this.loadRecord(rec);
		this.dateCheck();
		// Save the originalqueue_id from the DB. This value will become the 
		// value of ticket_last_queue_id if the user selected a different queue.
		var ticket_queue_field = form.findField('ticket_queue_id');
		var ticket_last_queue_field = form.findField('ticket_last_queue_id');
		var ticket_org_queue_field = form.findField('ticket_org_queue_id');
		ticket_org_queue_field.setValue(ticket_queue_field.getValue());

		var queueField = form.findField('ticket_queue_id');
		var ticket_status_id = rec.get('ticket_status_id');
		var ticket_queue_id = rec.get('ticket_queue_id');
		if (ticket_status_id == '30009' || ticket_status_id == '30011') {
			// Enable the queue field
			queueField.store = programGroupStore;
			queueField.show();
			queueField.setValue(ticket_queue_id);
		}
		
		Ext.getCmp('ticketActionBar').checkButtons(rec);

		Funtion_calculateEscalation(rec.get('ticket_area_id'));

		this.show();
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
		var form = this.getForm();
		form.reset();
		this.dateCheck();

		form.findField('ticket_status_id').setValue('30000');		//Open
		Ext.getCmp('ticketActionBar').checkButtons(null);
	},
	
	dateCheck: function() {
		if (!currentUserIsAdmin) {
			this.getForm().findField('ticket_creation_date').readOnly = true;
			this.getForm().findField('ticket_escalation_date').readOnly = true;
			this.getForm().findField('ticket_done_date').readOnly = true;
		}
	}
});
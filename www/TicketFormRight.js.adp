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
				disabled:	false
			}, {
				name:		'ticket_escalation_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Escalation_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false
			}, {
				name:		'ticket_done_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Close_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false
			}, {
				name:		'ticket_incoming_channel_id',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Incoming_Channel#',
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
			}, {
				name:		'ticket_reaction_date',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Reaction_Date#',
				xtype:		'po_datetimefield_read_only',
				disabled:	false
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
	
	buttons: [/*{
		text:			'#intranet-sencha-ticket-tracker.Reject_Button#',
		itemId:			'rejectButton',
		id:			'ticketFormRightRejectButton',
		hidden:			false,	
		formBind:		true,
		handler: function() {

			// Get the field information
			var form = this.up('form').getForm();
			var ticket_queue_field = form.findField('ticket_queue_id');
			var ticket_last_queue_field = form.findField('ticket_last_queue_id');
			var ticket_last_queue_id = ticket_last_queue_field.getValue();

			// Check that the store contains the value for rejection
			var lastQueueRecord = programGroupStore.findRecord('group_id', ticket_last_queue_id);
			if (null == lastQueueRecord || undefined == lastQueueRecord) {
				// We need to add the group to the store
                                var profileModel = profileStore.findRecord('group_id', ticket_last_queue_id);
				programGroupStore.insert(0, profileModel);
			}
			ticket_queue_field.setValue(ticket_last_queue_id);
		}
	},*/ {
		text:			'#intranet-sencha-ticket-tracker.button_Save#',
		itemId:			'saveButton',
		id:			'ticketFormRightSaveButton',
		disabled:		false,
		formBind:		true,
		handler: function(){
			var form = this.up('form').getForm();
	
			// find out the ticket_id
			var ticket_id_field = form.findField('ticket_id');
			var ticket_id = ticket_id_field.getValue();
	
			// Set certain ticket dates depending on the status
			var ticket_status_field = form.findField('ticket_status_id');
			var ticket_status_id = parseInt(ticket_status_field.getValue());
			
			// Set escalation_date once the tickt is reassinged to a queue
			// Store the last assignation into the ticket_last_queue_id
			var ticket_queue_field = form.findField('ticket_queue_id');
			var ticket_last_queue_field = form.findField('ticket_last_queue_id');
			var ticket_org_queue_field = form.findField('ticket_org_queue_id');
			var ticket_escalation_date_field = form.findField('ticket_escalation_date');

			var ticket_queue_id = ticket_queue_field.getValue();
			var ticket_org_queue_id = ticket_org_queue_field.getValue();
			var ticket_escalation_date = ticket_escalation_date_field.getValue();
	
			// set the escalation date if not already defined
			if (ticket_escalation_date == null && (ticket_queue_id != null && ticket_queue_id != '')) {
				form.findField('ticket_escalation_date').setValue(today);
			}
	
			// Write the org_queue_id into the last_queue_id field
			// IF org_queue_id != queue_id
			if (ticket_queue_id != ticket_org_queue_id) {
				// We've got a queue-change-event
				ticket_last_queue_field.setValue(ticket_org_queue_field.getValue());
			}
	
	
			// Write form values into the store
			var values = form.getValues();
			var ticket_record = ticketStore.findRecord('ticket_id',ticket_id);
			var value;
			for(var field in values) {
				if (values.hasOwnProperty(field)) {
					value = values[field];
					if (value == null) { value = ''; }
					value = Function_espaces(value);
					ticket_record.set(field, value);
				}
			}

			// Check if the model validates correctly
			var errors = ticket_record.validate();
			if (!errors.isValid()) {
				var msg = '';
				for (var i = 0; i < errors.length; i++) {
					var field = errors.items[i].field;
					var message = errors.items[i].message;
					msg = msg + 'Error in ' + field + ': ' + message + '\n';
				}
				alert(msg);
				return;
			}

			// Save the record and _then_ reload the form.
			ticket_record.save({
				scope: 			Ext.getCmp('ticketFormRight'),
				messageProperty:	'message',
				success: function(record, operation) {
					// Refresh all forms to show the updated information
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					//compoundPanel.loadTicket(ticket_record);

					Function_insertAction(record.get('ticket_id'), Ext.getCmp('ticketForm').getForm().findField('datetime').getValue(), record);									
				},
				failure: function(record, operation) {
					Ext.Msg.alert('Failed to save ticket', operation.request.scope.reader.jsonData["message"]);
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticket_record);
				}
			});
		}
	}],

	loadTicket: function(rec){
		var form = this.getForm();
		this.loadRecord(rec);

		// Save the originalqueue_id from the DB. This value will become the 
		// value of ticket_last_queue_id if the user selected a different queue.
		var ticket_queue_field = form.findField('ticket_queue_id');
		var ticket_last_queue_field = form.findField('ticket_last_queue_id');
		var ticket_org_queue_field = form.findField('ticket_org_queue_id');
		ticket_org_queue_field.setValue(ticket_queue_field.getValue());

		// Disable the read-only date fields
		// form.findField('ticket_creation_date').setDisabled(true);
		// form.findField('ticket_escalation_date').setDisabled(true);
		// form.findField('ticket_done_date').setDisabled(true);


		var queueField = form.findField('ticket_queue_id');
		var ticket_status_id = rec.get('ticket_status_id');
		var ticket_queue_id = rec.get('ticket_queue_id');
		if (ticket_status_id == '30009' || ticket_status_id == '30011') {
			// Enable the queue field
			queueField.store = programGroupStore;
			queueField.show();
			queueField.setValue(ticket_queue_id);
		}
		
		//If the Ticket is close, hide the buttons
		var buttonToolbar = this.getDockedComponent(0);
		var rejectButton = Ext.getCmp('ticketActionBar').getComponent('buttonReject')	
		rejectButton.show();
		if (ticket_status_id == '30001' && currentUserIsAdmin != 1){
			buttonToolbar.disable();
			rejectButton.disable();
		} else {
			buttonToolbar.enable();
			// Enable the "Reject" button if last_queue_id exists
			if (Ext.isEmpty(ticket_last_queue_field.getValue())){
				rejectButton.disable();
			} else {
				rejectButton.enable();
			}
		}
		

		// Calculate the drop-down box for escalation
		var programId = rec.get('ticket_area_id');
		if (null != programId) {
			var programModel = ticketAreaStore.findRecord('category_id', programId);
			if (null != programModel) {

				// Delete the selection of the Escalation combo
				var esclationField = form.findField('ticket_queue_id');
				delete esclationField.lastQuery;

				// Remove all elements from the store
				programGroupStore.removeAll();
	
				// Get the row with the list of groups enabled for this area:
				var programName = programModel.get('category');
	            var mapRow = SPRIProgramGroupMap.findRecord('Programa', programName);
				if (null == mapRow) {
					alert('Configuration Error:\nProgram "'+programName+'" not found');
					return;
				}
	
				// loop through the groups in the profile store and add them
				// to the programGroupStore IF it's enabled for this program.
				for (var i = 0; i < profileStore.getCount(); i++) {
					var profileModel = profileStore.getAt(i);
					var profileName = profileModel.get('group_name');
					var enabled = mapRow.get(profileName);
					if (enabled != null && enabled != '') {
						programGroupStore.insert(0, profileModel);
					}
				}
		    	}
		}

		this.show();
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
		var form = this.getForm();
		form.reset();

		// Pre-set the creation date
		var creation_date = '<%= [db_string date "select to_char(now(), \'YYYY-MM-DD HH24:MI\')"] %>';
		form.findField('ticket_creation_date').setValue(name);

		this.hide();
	}
});


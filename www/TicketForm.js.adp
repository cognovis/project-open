/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
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
	        valueField:     'id',
					typeAhead:	true,
					listeners: {
								change: function (field,newValue,oldValue) {
									 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
								}
					}							
	},

	items: [

	// Variables for the new.tcl page to recognize an ad_form
	{ name: 'ticket_id',			xtype: 'hiddenfield' },
	{ name: 'ticket_creation_date', 	xtype: 'hiddenfield' },
	{ name: 'ticket_status_id',		xtype: 'hiddenfield', value: 30000 },	// Open by default
	{ name: 'ticket_queue_id',		xtype: 'hiddenfield', value: 463 },	// Assign to Employees by default
	{ name: 'ticket_last_queue_id',		xtype: 'hiddenfield' },			// 
	{ name: 'fs_folder_id',			xtype: 'hiddenfield' },			// Assign to Employees by default
	{ name: 'project_nr',			xtype: 'hiddenfield' },

	// Optional fields start here
	{ name: 'ticket_request',		xtype: 'hiddenfield' },
	{ name: 'ticket_resolution',		xtype: 'hiddenfield' },
	{ name: 'ticket_description',		xtype: 'hiddenfield' },
	{ name: 'ticket_note',			xtype: 'hiddenfield' },

	{ name: 'ticket_closed_in_1st_contact_p',xtype: 'hiddenfield' },
	{ name: 'ticket_incoming_channel_id',	xtype: 'hiddenfield' },
	{ name: 'ticket_outgoing_channel_id',	xtype: 'hiddenfield' },

	{ name: 'ticket_confirmation_date',	xtype: 'hiddenfield' },
	{ name: 'ticket_done_date',		xtype: 'hiddenfield' },
	{ name: 'ticket_escalation_date',	xtype: 'hiddenfield' },
	{ name: 'ticket_reaction_date',		xtype: 'hiddenfield' },
	{ name: 'ticket_resolution_date',	xtype: 'hiddenfield' },
	{ name: 'ticket_signoff_date',		xtype: 'hiddenfield' },
	// Optional fields end here

	{ 	// Anonimous User
		name: 'ticket_customer_contact_id',
		xtype: 'hiddenfield',
		value: <%= [db_string anon "select user_id from users where username = 'anonimo'" -default 624] %>
	},
	{ 	// Anonimous SLA
		name: 'parent_id',
		xtype: 'hiddenfield',
		value: <%= [db_string anon "select project_id from im_projects where project_nr = 'anonimo'" -default 0] %>
	},
	{ 	// Anonimous Company
		name: 'company_id',
		xtype: 'hiddenfield',
		value: <%= [db_string anon "select company_id from im_companies where company_path = 'anonimo'" -default 0] %>
	},

	// Main ticket fields
	{
		name:		'project_name',
		itemId:		'project_name',
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
		store: 		ticketTypeStore,
		allowBlank:	false,			// Require a value for this one
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		}
	}, {
		name:		'ticket_program_id',
		itemId:		'ticket_program_id',
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Area#',
		xtype:		'combobox',
        	width: 		300,
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		store: 		programTicketAreaStore,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners:{
		    // The user has selected a program/area from the drop-down box.
		    // Now construct a new ProgramGroupStore based on this information
		    // with only those groups/profiles that are assigned to the program
		    'change': function() {
									var ticket_area_id =  Ext.getCmp('ticketForm').getForm().findField('ticket_area_id');
									ticket_area_id.reset();
									if (ticket_area_id.store.filters.length > 0) {
										//Filter value is modified with the new value selected.
										ticket_area_id.store.filters.getAt(0).value = Ext.String.leftPad(this.value,8,"0");
									} else {
										//New filters is created with the value selected
										ticket_area_id.store.filter('tree_sortkey',  Ext.String.leftPad(this.value,8,"0"));
									}
									ticket_area_id.store.load();
		    }
		} 
	}, {
		fieldLabel:	'#intranet-sencha-ticket-tracker.Program#',
		name:		'ticket_area_id',
		xtype:		'combobox',
		displayField:	'category_translated',
		valueField:	'category_id',
		store:		areaTicketAreaStore,
    width: 		300,
		forceSelection: true,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners: {
			'change': function() {
				// Set the default code for the new ticket
									var programId = this.getValue();
									if (null == programId) { return; }
									var programModel = ticketAreaStore.findRecord('category_id', programId);
									if (null == programModel) { return; }
									var programName = programModel.get('category');
									var programFile = programModel.get('aux_string1');
									var fileField = this.ownerCt.child('#ticket_file');
									fileField.setValue(programFile);				
			}
		}
	}, {
		name:		'ticket_file',
		itemId:		'ticket_file',
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_File_Number#',
        	width: 		300,
	        xtype:		'textfield'
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

		// find out the ticket_id
		var ticket_id_field = form.findField('ticket_id');
		var ticket_id = ticket_id_field.getValue();

		if ('' == ticket_id) {

			// Disable the form until the ticket_id has arrived
			Ext.getCmp('ticketForm').setDisabled(true);

			// create a new ticket
			var ticketModel = Ext.ModelManager.create(values, 'TicketBrowser.Ticket');
			ticketModel.phantom = true;
			ticketModel.save({
				scope: Ext.getCmp('ticketForm'),
				success: function(ticket_record, operation) {
					// This code is called once the reply from the server has arrived.
					// The server response includes all necessary data for the new object.
					ticketStore.add(ticket_record);

					// Tell all panels to load the data of the newly created object
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticket_record);
				},
				failure: function(record, operation) {
					Ext.Msg.alert("Error durante la creacion de un nuevo ticket", operation.request.scope.reader.jsonData["message"]);
					// Re-enable this form
					Ext.getCmp('ticketForm').setDisabled(true);

					// Return to the main tickets Tab
					var ticketContainer = Ext.getCmp('ticketContainer');
					var mainTabPanel = Ext.getCmp('mainTabPanel');
					mainTabPanel.setActiveTab(ticketContainer);
				}
			});

		} else {

			// Update an existing ticket
			// Loop through all form fields and store into the ticket store
			var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);
			for(var field in values) {
				if (values.hasOwnProperty(field)) {
					value = values[field];
					ticketModel.set(field, value);
				}
			}
	
			// Disable this form to indicate the request is working
			Ext.getCmp('ticketForm').setDisabled(true);

			// Tell the store to update the server via it's REST proxy
			ticketModel.save({
				scope: Ext.getCmp('ticketForm'),
				success: function(record, operation) {
					// Refresh all forms to show the updated information
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticketModel);
				},
				failure: function(record, operation) {
					Ext.Msg.alert('Failed to save ticket', operation.request.scope.reader.jsonData["message"]);
				}
			});
		}
	    }
	}],

	loadTicket: function(rec){
		var form = this.getForm();

		// Show this ticket, in case it was disabled before
		this.setDisabled(false);
						
		// load the data from the record into the form
		this.loadRecord(rec);

		//Search the program/area values and recover the ticket file
		var ticket_program_id = rec.get('ticket_area_id');
		var ticket_program_model = ticketAreaStore.getById(ticket_program_id);
		if (ticket_program_model != null && ticket_program_model != undefined){
			var ticket_program_tree_sortkey = ticket_program_model.get('tree_sortkey');
			var ticket_program_tree_sortkey_cut = '' + parseInt(ticket_program_tree_sortkey.substring(0,8),'10');
			form.findField('ticket_program_id').select(ticket_program_tree_sortkey_cut);			// The real "area" field
			form.findField('ticket_area_id').select(ticket_program_id);					// The real "program" field

			// fraber 110720: Should be stored in Model anyway, right?
			// dblao 110720: No, 'ticket_file' value is calculated when 'ticket_area_id' changes (event), the real stored value must be reloaded.
			var ticket_file = Ext.getCmp('ticketForm').getForm().findField('ticket_file')
			ticket_file.setValue(rec.get('ticket_file'));
		}
		
			
		//If Ticket is closed, disable the buttons.
		var ticket_status_id=rec.get('ticket_status_id');
		var buttonToolbar =this.getDockedComponent(0);
		var saveButton = buttonToolbar.getComponent('saveButton');		
		if (saveButton == null || saveButton == undefined){
			buttonToolbar =this.getDockedComponent(1);
			saveButton = buttonToolbar.getComponent('saveButton');	
		}
		
		if (ticket_status_id == '30001') {		// Closed status
			saveButton.hide();
		} else {
			saveButton.show();
		}		
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
	        var form = this.getForm();
	        form.reset();
		
		//Enable the buttons.
		var buttonToolbar =this.getDockedComponent(0);
		var saveButton = buttonToolbar.getComponent('saveButton');		
		if (saveButton == null || saveButton == undefined){
			buttonToolbar =this.getDockedComponent(1);
			saveButton = buttonToolbar.getComponent('saveButton');	
		}
		saveButton.show();

		// Ask the server to provide a new ticket name
		this.setNewTicketName();		

		// Set the creation data of the new ticket
		Ext.Ajax.request({
			scope:	this,
			url:	'/intranet-sencha-ticket-tracker/today-date-time',
			success: function(response) {		// response is the current date-time
				var form = this.getForm();
				var date_time = response.responseText;
				form.findField('ticket_creation_date').setValue(date_time);
			}
		});

		// Set the default value for ticket_type
		var form = this.getForm();
		form.findField('ticket_type_id').setValue('10000191');
	},
	
	// Determine the new of the new ticket. Send an async AJAX request
	// to the server and tell the callback to insert the new ticket number
	// into the project_name field in this form.
	setNewTicketName: function() {
	    Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/ticket-next-nr',
		success: function(response) {
		    // ticket-next-nr just returns a string which represents the name
		    var ticket_nr = response.responseText;
		    var form = this.getForm();
		    form.findField('project_nr').setValue(ticket_nr);
		    var ticket_name = '#intranet-sencha-ticket-tracker.New_Ticket_Prefix#' + ticket_nr;
		    form.findField('project_name').setValue(ticket_name);
		},
		failure: function(response) {
		    alert('#intranet-sencha-ticket-tracker.Failed_to_get_new_ticket_nr#');
		}
	    });
	}
});


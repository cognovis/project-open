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

var resetCombo = true;

var ticketInfoPanel = Ext.define('TicketBrowser.TicketForm', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.ticketForm',
	id:		'ticketForm',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-sencha-ticket-tracker.Ticket#',
	bodyStyle:	'padding:5px 5px 0',
	fieldDefaults: {
		msgTarget: 'side'
	//	labelWidth: 125
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
					 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue);
				}
			}							
	},

	items: [

	// Variables for the new.tcl page to recognize an ad_form
	{ name: 'ticket_id',				xtype: 'hiddenfield' },
	{ name: 'ticket_creation_date', 	xtype: 'hiddenfield' },
	{ name: 'ticket_status_id',			xtype: 'hiddenfield', value: 30000 },	// Open by default
	{ name: 'ticket_queue_id',			xtype: 'hiddenfield', value: 463 },	// Assign to Employees by default
	{ name: 'ticket_last_queue_id',		xtype: 'hiddenfield' },		
	{ name: 'fs_folder_id',				xtype: 'hiddenfield' },			
	{ name: 'project_nr',				xtype: 'hiddenfield' },

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

	// Audit field
	{ name: 'datetime',	xtype: 'hiddenfield' },
	//end audit_field
	
	{ 	// Anonimous User
		name: 'ticket_customer_contact_id',
		xtype: 'hiddenfield',
		value: anonimo_user_id
	},
	{ 	// Anonimous SLA
		name: 'parent_id',
		xtype: 'hiddenfield',
		value: anonimo_sla
	},
	{ 	// Anonimous Company
		name: 'company_id',
		xtype: 'hiddenfield',
		value: anonimo_company_id
	},

	// Main ticket fields
	{
		name:		'project_name',
		itemId:		'project_name',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_Name#',
		allowBlank:	false,	
		disabled:	false,
        	width: 		300
	}, {
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_type#',
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
		},
		validator: function(value){
			Ext.getCmp('ticketForm').getForm().findField('ticket_area_id').validate();
			return this.store.validateLevel(this.value,this.allowBlank)
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
		allowBlank:	false,
		store: 		programTicketAreaStore,
		queryMode:	'local',
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners:{
		    // The user has selected a program/area from the drop-down box.
		    // Now construct a new ProgramGroupStore based on this information
		    // with only those groups/profiles that are assigned to the program
		    change: function(field, newValue, oldValue) {
		    	Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue);
				var ticket_area_id =  Ext.getCmp('ticketForm').getForm().findField('ticket_area_id');

				if (ticket_area_id.store.filters.length > 0) {
					//Filter value is modified with the new value selected.
					ticket_area_id.store.filters.getAt(0).value = Ext.String.leftPad(newValue,8,"0");
				} else {
					//New filters is created with the value selected
					ticket_area_id.store.filter('tree_sortkey',  Ext.String.leftPad(newValue,8,"0"));
				}
				if (resetCombo) {
					ticket_area_id.reset();
					ticket_area_id.store.load();
				} else {
					resetCombo = true;
				}							
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
		allowBlank:	false,
		queryMode:	'local',
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners: {
			change: function(field, newValue, oldValue, options) {			
				Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue);
				var programId = this.getValue();
				if (null != programId) {
					var programModel = ticketAreaStore.findRecord('category_id', programId);
					if (null != programModel) { 
						var programName = programModel.get('category');
						var programFile = programModel.get('aux_string1');
						var fileField = this.ownerCt.child('#ticket_file');
						fileField.setValue(programFile);
					}
				}
				
				//if (null == newValue) { this.reset(); } else {
				if (!Ext.isEmpty(newValue)) {
					var form =  Ext.getCmp('ticketForm').getForm();
					var record = areaTicketAreaStore.getById(newValue);
					if (record != null){
						var tree_sortkey = record.get('tree_sortkey').substring(0,8);				
						var program_id = '' + parseInt(tree_sortkey,'10');	
						var ticket_program_id = form.findField('ticket_program_id')
						if (ticket_program_id.value != program_id) {
							resetCombo = false;			
							form.findField('ticket_program_id').select(program_id);	
						}
						Funtion_calculateEscalation(newValue);
					}
				}										
			}
		},
		validator: function(value){
			try{
				var ticket_type_field = Ext.getCmp('ticketForm').getForm().findField('ticket_type_id');
				if (this.store.data.length > 0 && !Ext.isEmpty(this.value) && !Ext.isEmpty(ticket_type_field.store.findRecord('category_id',ticket_type_field.getValue())) ) {
					var string_2_program = this.store.findRecord('category_id',this.value).get('aux_string2');
					var string_2_type = ticket_type_field.store.findRecord('category_id',ticket_type_field.getValue()).get('aux_string2');
					if (Ext.String.trim(string_2_program).toLowerCase()!=Ext.String.trim(string_2_type).toLowerCase()) {
						return 'Tipo de ticket no válido para el programa indicado'; 
					}
				}
			} catch(err) {
				return this.store.validateLevel(this.value,this.allowBlank);
			}
			return this.store.validateLevel(this.value,this.allowBlank);
			/*
			var levelv = this.store.validateLevel(this.value,this.allowBlank);
			if (levelv==true) {
				var ticket_type_field = Ext.getCmp('ticketForm').getForm().findField('ticket_type_id');
				var parent_type_id = ticket_type_field.store.getParent(ticket_type_field.getValue());
				if ((this.value=='10000221' || this.value=='10000244' || this.value=='10000234' || this.value=='10000235' || this.value=='10000236' || this.value=='10000223' || this.value=='10000238' || this.value=='10000239' || this.value=='10000240') && parent_type_id!=serviceId) {
						return 'Tipo de ticket no válido para el programa indicado';
				}
				return true;
			} else {
				return levelv;
			}*/
		}		
	}, {
		name:		'ticket_file',
		itemId:		'ticket_file',
        fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_File_Number#',
    	width: 		300,
        xtype:		'textfield'        
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
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
        var form = this.getForm();
        form.reset();	

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
				Ext.getCmp('ticketFormRight').getForm().findField('ticket_creation_date').setValue(date_time);
			}
		});

		// Set the default value for ticket_type
		var form = this.getForm();
		//form.findField('ticket_type_id').setValue('10000173');
		
		// SEt datetime for actions
		var date = new Date();
		form.findField('datetime').setValue(date.getTime());		
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
				Function_errorMessage('', '#intranet-sencha-ticket-tracker.Failed_to_get_new_ticket_nr#', response.responseText);
			}
	    });
	}
});


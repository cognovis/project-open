/**
 * intranet-sencha-ticket-tracker/www/TicketContactForm.js
 * Container for both TicketGrid and TicketForm.
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

Ext.define('TicketBrowser.TicketContactForm', {
	extend:		'Ext.form.Panel',
	alias:		'widget.ticketContactForm',
	id:		'ticketContactForm',
	title:		'#intranet-sencha-ticket-tracker.Contacts#',
	frame:		true,
	fieldDefaults: {
		msgTarget:		'side',
		labelWidth:		125,
		width:			300,
		typeAhead:		true
	},
	items: [{
		name:			'user_id',
		xtype:			'combobox',
		fieldLabel:		'#intranet-sencha-ticket-tracker.NameSearch#',
		value: '',
		//value:			'#intranet-sencha-ticket-tracker.New_User#',
		//valueNotFoundText:	'#intranet-sencha-ticket-tracker.Create_New_User#',
		queryMode:	'local',
		valueField:		'user_id',
		displayField:   	'name',
		store:			userCustomerContactStore,
		enableKeyEvents:	true,
		triggerAction:		'all',
		listeners:{

		 // The user has selected a user from the drop-down box.
		 // Lookup the user and fill the form with the fields.
		 'blur': function(field, event) {

			var user_id = this.getValue();
			var user_record = userCustomerContactStore.findRecord('user_id',user_id);
			
			if (Ext.isEmpty(user_record)) {
				var user_record = userCustomerContactStore.findRecord('name',this.getRawValue());
				//var user_record = userCustomerStore.findRecord('user_id',anonimo_user_id);
			}
			if (Ext.isEmpty(user_record)) {
				return;
			}			
			
			if (Ext.isEmpty(user_record.get('user_id'))){
				Ext.getCmp('ticketContactForm').getForm().findField('first_names').show();					
				Ext.getCmp('ticketContactForm').getForm().findField('last_name').show();
				Ext.getCmp('ticketContactForm').getForm().findField('last_name2').show();
			} else {
				Ext.getCmp('ticketContactForm').getForm().findField('first_names').hide();
				Ext.getCmp('ticketContactForm').getForm().findField('last_name').hide();
				Ext.getCmp('ticketContactForm').getForm().findField('last_name2').hide();
			}

			// load the values of the user into the form
			this.ownerCt.loadRecord(user_record);
		 }
		}
	}, {
		name:		'first_names',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.First_names#',
		hidden: true,
		allowBlank:	false,
		validator: function(value){
			if (Ext.isEmpty(value)){
				return "Obligatorio";
			}
			if (value.substring(0,14).toLowerCase() == "nuevo contacto"){
				return "No válido";
			}
			return true;
		}		
	}, {
		name:		'last_name',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Last_name#',
		hidden: true,
		allowBlank:	false
	}, {
		name:		'last_name2',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Last_Name2#',
		hidden: true
	}, {
		name:		'email',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Email#'
	}, {
		name:		'telephone',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Telephone#'
	}, {
		name:		'ticket_customer_contact_p',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Primary_Contact#',
		xtype:		'checkbox',
		hidden: true,
		value:		true
	}, {
		name:		'language',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_Language#',
		queryMode:	'local',
		valueField:	'iso',
		displayField:	'language',
		triggerAction:	'all',
		store:		new Ext.data.ArrayStore({
					id: 0,
					fields: ['iso', 'language'],
					data: [
						['', null],
						['es_ES', '#intranet-sencha-ticket-tracker.lang_es_ES#'], 
						['eu_ES', '#intranet-sencha-ticket-tracker.lang_eu_ES#']
					]
		})
	}, {
		name:		'gender',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Gender#',
		queryMode:	'local',
		valueField:	'id',
		displayField:	'gender',
		triggerAction:	'all',
		store:		new Ext.data.ArrayStore({
					id: 0,
					fields: ['id', 'gender'],
					data: [
						['male', '#intranet-sencha-ticket-tracker.Male#'], 
						['female', '#intranet-sencha-ticket-tracker.Female#']
					]
		})
	}],

	loadTicket: function(rec){
		userCustomerTicketRelationStore.removeAll();
		userCustomerTicketRelationStore.proxy.extraParams['object_id_one'] = rec.get('company_id');
		userCustomerTicketRelationStore.load();			
	},

	loadUser: function(rec){

		// load the information from the record into the form
		this.loadRecord(rec);

		// Show (might have been hidden when creating a new ticket)
		this.show();

		var form = this.getForm();
		contactField = form.findField('ticket_customer_contact_p');
		contactField.setValue(true);
		
		rec.dirty = false;
		Ext.getCmp('ticketContactForm').getForm().findField('first_names').hide();					
		Ext.getCmp('ticketContactForm').getForm().findField('last_name').hide();
		Ext.getCmp('ticketContactForm').getForm().findField('last_name2').hide();			
	},

	// Called when the user changed the customer in the TicketCustomerPanel
	loadCustomer: function(customerModel){		
		//Load anonymus contact
		var company_id = customerModel.get('company_id');
		if (Ext.isEmpty(company_id)) {
			company_id = '1';
		}
		userCustomerTicketRelationStore.removeAll();
		userCustomerTicketRelationStore.proxy.extraParams['object_id_one'] = company_id;
		userCustomerTicketRelationStore.load();				
		
		Ext.getCmp('ticketContactForm').getForm().findField('first_names').show();					
		Ext.getCmp('ticketContactForm').getForm().findField('last_name').show();
		Ext.getCmp('ticketContactForm').getForm().findField('last_name2').show();		
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
		userCustomerTicketRelationStore.removeAll();
		userCustomerTicketRelationStore.proxy.extraParams['object_id_one'] = anonimo_company_id;
		userCustomerTicketRelationStore.load();				
	}

});


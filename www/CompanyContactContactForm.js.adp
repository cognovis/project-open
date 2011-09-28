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


Ext.define('TicketBrowser.CompanyContactContactForm', {
	extend:		'Ext.form.Panel',
	alias:		'widget.companyContactContactForm',
	id:			'companyContactContactForm',
	title:		'#intranet-sencha-ticket-tracker.Contacts#',
	frame:		true,
	fieldDefaults: {
		msgTarget:		'side',
		labelWidth:		125,
		width:			500,
		typeAhead:		true
	},
	defaults: {
		listeners: {
			change: function (field,newValue,oldValue) {
				 Ext.getCmp('companyContactCompoundPanel').checkContactField(field,newValue,oldValue)
			}
		}
	},		
	items: [{
		name:			'user_id',
		xtype:			'combobox',
		fieldLabel:		'#intranet-sencha-ticket-tracker.NameSearch#',
	/*	value:			'#intranet-sencha-ticket-tracker.New_User#',
		valueNotFoundText:	'#intranet-sencha-ticket-tracker.Create_New_User#',*/
		value: '',
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
			
			// load the values of the user into the form
			this.ownerCt.loadRecord(user_record);
		 }
		}
	}, {
		name:		'first_names',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.First_names#',
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
		allowBlank:	false
	}, {
		name:		'last_name2',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Last_Name2#'
	}, {
		name:		'email',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Email#'
	}, {
		name:		'telephone',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Telephone#'
	},/* {
		name:		'ticket_customer_contact_p',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Primary_Contact#',
		xtype:		'checkbox',
		value:		true
	},*/ {
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

	loadUser: function(rec){
		// load the information from the record into the form
		this.loadRecord(rec);
		
		rec.dirty = false; 
		
		// Show (might have been hidden when creating a new ticket)
		this.show();
	},

	loadCompany: function(customerModel){
		var company_id = customerModel.get('company_id');
		if (Ext.isEmpty(company_id)) {
			company_id = '1';
		}		
		userCustomerContactRelationStore.removeAll();
		userCustomerContactRelationStore.proxy.extraParams['object_id_one'] = company_id;
		userCustomerContactRelationStore.load();	
	},

	newCompany: function() {
		userCustomerContactRelationStore.removeAll();
		userCustomerContactRelationStore.proxy.extraParams['object_id_one'] = "1";
		userCustomerContactRelationStore.load();	
	}
});
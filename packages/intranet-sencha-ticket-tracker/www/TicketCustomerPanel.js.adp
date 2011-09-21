/**
 * intranet-sencha-ticket-tracker/www/TicketCustomerPanel.js
 * Shows the ticket's customer and allows to create a new customer.
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

Ext.define('TicketBrowser.TicketCustomerPanel', {
	extend:		'Ext.form.Panel',
	alias:		'widget.ticketCustomerPanel',
	id:		'ticketCustomerPanel',
	title:		'#intranet-sencha-ticket-tracker.Ticket_Customer#',
	frame:		true,
	fieldDefaults: {
		msgTarget:	'side',
		labelWidth:	125,
		typeAhead:	true				
	},
	items: [/*{ 
		name: 'checkNew',
		xtype: 'checkbox',
		value: true,
		fieldLabel:	'#intranet-sencha-ticket-tracker.CreateNew#',
		listeners:{
			change: function(field, newValue, oldValue, options) {
				if (newValue) {
					Ext.getCmp('ticketCustomerPanel').getForm().findField('company_id').disable();
				} else {
					Ext.getCmp('ticketCustomerPanel').getForm().findField('company_id').enable();					
				}
			}
		}
	},*/ {
		name:		'company_id',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.CompanySearch#',
		//valueNotFoundText: '#intranet-sencha-ticket-tracker.Create_New_Company#',
		//value:		'#intranet-sencha-ticket-tracker.New_Customer#',
		value: '',
		valueField:	'company_id',
		displayField:   'company_name',
		store:		companyStore,
		queryMode:	'local',
		listeners: {
			// The user has selected a customer from the drop-down box.
			// Lookup the customer and fill the form with the fields.
			'blur': function() {
				var customer_id = this.getValue();
				var cust = companyStore.findRecord('company_id',customer_id);
				if (cust == null || cust == undefined) { 
					cust = companyStore.findRecord('company_name',this.getRawValue());
				}
				if (Ext.isEmpty(cust)) { return; }

				// Add the province to the store (province field is now a combobox but old data maybe no correct)
				provincesStore.load();
				var company_province_name = cust.get('company_province');
				var store_company = provincesStore.findRecord('name',company_province_name,0,false,true,true);
				if (store_company==null){
					provincesStore.add({'name': company_province_name});
				}
				
				if (Ext.isEmpty(cust.get('company_id'))){
					Ext.getCmp('ticketCustomerPanel').getForm().findField('company_name').show();					
				} else {
					Ext.getCmp('ticketCustomerPanel').getForm().findField('company_name').hide();
				}
				// load the record into the form
				this.ownerCt.loadRecord(cust);
			
				// Inform the TicketCustomerPanel about the new company
				Ext.getCmp('ticketContactPanel').loadCustomer(cust);
			},
			change: function (field,newValue,oldValue) {
				 Ext.getCmp('ticketCompoundPanel').checkTicketField(field,newValue,oldValue)
			}
		}
	}, {
		name:		'company_name',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Company_name#',
		hidden: true,
		allowBlank:	false
	}, {
		name:		'vat_number',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.VAT_Number#'
	},{
		name:		'company_type_id',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Company_Type#',
		value:		'',
		valueField:	'category_id',
		displayField:   'category_translated',
		allowBlank:	false,
		store:		companyTypeStore,
		queryMode:	'local',
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		validator: function(value){
			return this.store.validateLevel(this.value,this.allowBlank)
		}				
	}, 
	
	{
		name:		'company_province',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Province#',
		allowBlank:	false,
		forceSelection: true,
		store: provincesStore,
		valueField:	'name',
		displayField:   'name',		
		queryMode: 'local'
	}],

	// For a new ticket reset the values of the form.
	newTicket: function() {
		var form = this.getForm();
		form.reset();

		provincesStore.load();
		
		// Don't show this form for new tickets
		//this.hide();
		companyStore.clearFilter();
		this.loadRecord(companyStore.findRecord('company_id', anonimo_company_id));
	},

	loadTicket: function(rec){
		this.getForm().reset();
		// Show the form
		this.show();		

		// Customer ID, may be NULL
		var customer_id;
		if (rec.data.hasOwnProperty('company_id')) { customer_id = rec.data.company_id; }

		companyStore.clearFilter();
		var cust = companyStore.findRecord('company_id',customer_id);
		if (cust == null || typeof cust == "undefined") { return; }

		// Add the province to the store (province field is now a combobox but data maybe no correct
		provincesStore.load();
		var company_province_name = cust.get('company_province');
		var store_company = provincesStore.findRecord('name',company_province_name,0,false,true,true);
		if (store_company==null){
			provincesStore.add({'name': company_province_name});
		}
		
		// load the customer's information into the form.
		this.loadRecord(cust);
	}

});


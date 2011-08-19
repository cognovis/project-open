/** 
 *  Container for customer detail.
 *
 * @author David Blanco (david.blanco@grupoversia.com)
 * @creation-date 2011-08
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

Ext.define('TicketBrowser.CompanyContactCustomerPanel', {
	extend:		'Ext.form.Panel',
	alias:		'widget.companyContactCustomerPanel',
	id:			'companyContactCustomerPanel',
	title:		'#intranet-sencha-ticket-tracker.Ticket_Customer#',
	frame:		true,
	fieldDefaults: {
		msgTarget:	'side',
		labelWidth:	125,
		width: 500,
		typeAhead:	true				
	},
	defaults: {
		listeners: {
			change: function (field,newValue,oldValue) {
				 Ext.getCmp('companyContactCompoundPanel').checkCompanyField(field,newValue,oldValue)
			}
		}
	},	
	items: [
	{	name: 'company_id',			
		xtype: 'hiddenfield'
	}, {
		name:		'company_name',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Company_name#',
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
	}, {
		name:		'company_province',
		xtype:		'combobox',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Province#',
		allowBlank:	false,
		forceSelection: true,
		store: companyContactProvincesStore,
		valueField:	'name',
		displayField:   'name',		
		queryMode: 'local'
	}, {
		name:		'spri_company_address',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Address#',
	}, {
		name:		'spri_company_city',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.City#',
	}, {
		name:		'spri_company_pc',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.PC#',
	}, {
		name:		'spri_company_telephone',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Telephone#',
	}, {
		name:		'spri_company_fax',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Fax#',
	}, {
		name:		'spri_company_email',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Email#',	
	}],

	newCompany: function() {
		var form = this.getForm();
		form.reset();
		companyContactProvincesStore.load();
	},

	loadCompany: function(rec){
		this.getForm().reset();

		// Customer ID, may be NULL
		var customer_id;
		if (rec.data.hasOwnProperty('company_id')) { customer_id = rec.data.company_id; }

		var cust = companyStore.findRecord('company_id',customer_id);
		if (cust == null || typeof cust == "undefined") { return; }

		// Add the province to the store (province field is now a combobox but data maybe no correct
		companyContactProvincesStore.load();
		var company_province_name = cust.get('company_province');
		var store_company = companyContactProvincesStore.findRecord('name',company_province_name,0,false,true,true);
		if (store_company==null){
			companyContactProvincesStore.add({'name': company_province_name});
		}
		
		// load the customer's information into the form.
		this.loadRecord(cust);		
	}
});
/**
 * intranet-sencha-ticket-tracker/www/CompanyGrid.js
 * Grid table for ]po[ companies
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
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.	If not, see <http://www.gnu.org/licenses/>.
 */


var companyGridStore = Ext.create('PO.data.CompanyStore', {
	storeId: 'companyGridStore',
	model: 'TicketBrowser.Company',
	remoteSort: true,
	remoteFilter:	true,
	pageSize: 12,
	autoSync: true,				// Write changes to the REST server ASAP
	autoLoad: true,
	sorters: [{
		property: 'company_name',
		direction: 'ASC'
	}]
});

var companyGridSelModel = Ext.create('Ext.selection.CheckboxModel', {
	mode:	'SINGLE',
	allowDeselect: true,
	checkOnly: true,
	listeners: {
		select: function (component,record,index, eOpts ){
			Ext.getCmp('contactFilterForm').getForm().findField('company_id').setValue(record.get('company_id'));
			setTimeout('Ext.getCmp(\'contactFilterForm\').onSearch()',1000);
			
		}, 
		deselect: function (component,record,index, eOpts ){
			Ext.getCmp('contactFilterForm').getForm().findField('company_id').setValue(null);
			Ext.getCmp('contactFilterForm').onSearch();
			
		},
		selectionchange: function(view,selections,options)		{
			var otherSel = Ext.getCmp('contactGrid').getSelectionModel().getSelection();
			if (selections.length + otherSel.length == 1){
				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',false);
			} else {
				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',true);
			}			
		}	
	}	
});

var companyGrid = Ext.define('TicketBrowser.CompanyGrid', {
	extend:		'Ext.grid.Panel',	
	alias:		'widget.companyGrid',
	id:		'companyGrid',
	minHeight:	200,
	store:		companyGridStore,
	selModel:	companyGridSelModel,

	listeners: {	
		itemdblclick: function(view, record, item, index, e) {
			var compoundPanel = Ext.getCmp('companyContactCompoundPanel');
			compoundPanel.loadCompany(record);
			var title = record.get('company_name');
			compoundPanel.tab.setText(title);
			compoundPanel.tab.show();
		
			var mainTabPanel = Ext.getCmp('mainTabPanel');
			mainTabPanel.setActiveTab(compoundPanel);			
		}/*,
		selectionchange: function(view,selections,options)		{
			//One selection select contact in contactGrid
			if (selections.length == 1) {
				Ext.getCmp('contactFilterForm').getForm().findField('company_id').setValue(selections[0].get('company_id'));
			} else {
				//Other selection view all contact un contactGrid
				Ext.getCmp('contactFilterForm').getForm().findField('company_id').setValue(null);
			}
			
			//TODO: control action bar buttons depend of selection in two grid (company and contact)
			var otherSel = Ext.getCmp('contactGrid').getSelectionModel();
			
			Ext.getCmp('contactFilterForm').onSearch();
		}*/
	},

	columns: [
		{
			header: '#intranet-sencha-ticket-tracker.Company_Name#',
			dataIndex: 'company_name',
			flex: 1,
			minWidth: 150/*,
			renderer: function(value, metaData, record, rowIndex, colIndex, store) {
				return '<a href="/intranet/companies/view?company_id=' + 
					record.get('company_id') + 
					'" target="_blank">' + 
					value +
					'</a>';
			}*/
		}, {
			header: '#intranet-sencha-ticket-tracker.VAT_Number#',
			dataIndex: 'vat_number'
		}, {
			header: '#intranet-sencha-ticket-tracker.Province#',
			dataIndex: 'company_province'
		}, {
			header: '#intranet-sencha-ticket-tracker.Primary_contact#',
			dataIndex: 'primary_contact_id',
			renderer: function(value, o, record) {
				return userStore.name_from_id(record.get('primary_contact_id'));
			}
		}, {
 			header: '#intranet-helpdesk.Status#',
			dataIndex: 'company_status_id',
			renderer: function(value, o, record) {
				return companyStatusStore.category_from_id(record.get('company_status_id'));
			},
			field: {
				xtype: 'combobox',
				typeAhead: false,
				triggerAction: 'all',
				selectOnTab: true,
				queryMode: 'local',
				store: companyStatusStore,
				displayField: 'category',
				valueField: 'category_id'
			}
		}, {
 			header: '#intranet-sencha-ticket-tracker.Type#',
			dataIndex: 'company_type_id',
			renderer: function(value, o, record) {
				return companyTypeStore.category_from_id(record.get('company_type_id'));
			}
		}

	],
	dockedItems: [{
		xtype: 'pagingtoolbar',
		store: companyGridStore,
		dock: 'bottom',
		displayInfo: true
	}],


	// Called from CompanyFilterForm in order to limit the list of
	// companies according to filter variables.
	// filterValues is a key-value list (object).
	filterCompanies: function(filterValues){
		var store = this.store;
		var proxy = store.getProxy();
		var value = '';
		var query = '1=1';
	
		// delete filters added by other accordion filters
		delete proxy.extraParams['query'];
	
		// Apply the filter values directly to the proxy.
		// This only works if the filters are named according
		// to the REST interface specs.
		for(var key in filterValues) {
			if (filterValues.hasOwnProperty(key)) {
	
				value = filterValues[key];
				if (value == '' || value == undefined || value == null) {
					// Delete the filter
					delete proxy.extraParams[key];
				} else {
		
					// special treatment for special filter variables
					switch (key) {
					case 'vat_number':
						// The customer's VAT number is not part of the REST
						// company fields. So translate into a query:
						value = value.toLowerCase();
						query = query + ' and company_id in (select company_id from im_companies where lower(vat_number) like \'%' + value + '%\')';
						key = 'query';
						value = query;
						break;
					case 'company_type_id':
						// The customer's company type is not part of the REST company fields.
						query = query + ' and company_id in (select company_id from im_companies where company_type_id in (select im_sub_categories from im_sub_categories(' + value + ')))';
						key = 'query';
						value = query;
						break;
					case 'ticket_telephone':
						query = query + ' and company_id in (select object_id_one from acs_rels where object_id_two in (select person_id from persons where telephone like \'%' + value + '%\'))';
						key = 'query';
						value = query;
						break;		
					case 'email':
						// Fuzzy search
						value = value.toLowerCase();
						query = query + ' and company_id in (select object_id_one from acs_rels where object_id_two in (select party_id from parties where lower(email) like \'%' + value + '%\'))';
						key = 'query';
						value = query;
						break;											
					case 'company_name':
						// The customer's company name is not part of the REST
						// company fields. So translate into a query:
						value = value.toLowerCase();
						query = query + ' and company_id in (select company_id from im_companies where lower(company_name) like \'%' + value + '%\')';
						key = 'query';
						value = query;
						break;
					case 'start_date':
						// I can't get the proxy to quote (') the date, so we do it manually here:
						var	year = '' + value.getFullYear(),
							month =  '' + (1 + value.getMonth()),
							day = '' + value.getDate();
						if (month.length < 2) { month = '0' + month; }
						if (day.length < 2) { day = '0' + day; }
						value = '\'' + year + '-' + month + '-' + day + '\'';
						// console.log(value);
						query = query + ' and company_creation_date >= ' + value;
						key = 'query';
						value = query;
						break;
					case 'end_date':
						// I can't get the proxy to quote (') the date, so we do it manually here:
						var	year = '' + value.getFullYear(),
							month =  '' + (1 + value.getMonth()),
							day = '' + value.getDate();
						if (month.length < 2) { month = '0' + month; }
						if (day.length < 2) { day = '0' + day; }
						value = '\'' + year + '-' + month + '-' + day + '\'';
						// console.log(value);
						query = query + ' and company_creation_date <= ' + value;
						key = 'query';
						value = query;
						break;
					break;
					}
		
					// Save the property in the proxy, which will pass it directly to the REST server
					proxy.extraParams[key] = value;
				}
			}
		}
		
		store.loadPage(1);
	},

	onNew: function() {
		alert('CompanyGrid.onNew() not implemented yet');
	},

	onDelete: function() {
		// Get the selected customer (only one!)
		var selection = this.selModel.getSelection();
		var customerModel = selection[0];		
		
		//Create and show the window to change and delete the customer
		var changeWindow = new TicketBrowser.TicketChangeCustomerWindow();
		changeWindow.down('form').getForm().findField('company_id').select(customerModel.get('company_id'));
		changeWindow.show();
	},

	onCopy: function() {
		alert('CompanyGrid.onCopy() not implemented yet');
	}

});

/**
 * intranet-sencha-ticket-tracker/www/CompanyForm.js
 * Company form to allow modifying and creating new companies.
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


var companyForm = Ext.define('TicketBrowser.CompanyForm', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.companyForm',
	id:		'companyForm',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-sencha-ticket-tracker.Company#',
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
		typeAhead:	true
	},
	items: [

	// Auxillary variables not part of the actual form
	{ name: 'company_id',			xtype: 'hiddenfield' },
	{ name: 'company_status_id',		xtype: 'hiddenfield', value: 46 },	// "Active"

	// Main company fields
	{
		name:		'company_name',
		itemId:		'company_name',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Company_Name#',
		disabled:	false,
        	width: 		300
	}, {
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Company_Type#',
		name:		'company_type_id',
		xtype:		'combobox',
        	width: 		300,
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		store: 		companyTypeStore,
		allowBlank:	false,			// Require a value for this one
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		}
	}, {
		name:		'vat_number',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.VAT_Number#'
	},/* {
		name:		'company_province',
		xtype:		'textfield',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Province#'
	}*/
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
		
		values.company_name = values.company_name.toUpperCase();
		values.vat_number = values.vat_number.toUpperCase();
		
		checkValues(values);

		// New or Edit?
		var company_id = form.findField('company_id').getValue();
		if ('' == company_id) {
			// company_id is empty - create a new company

			// Disable the form until the company_id has arrived
			Ext.getCmp('companyForm').setDisabled(true);

			// create a new company
			var companyModel = Ext.ModelManager.create(values, 'TicketBrowser.Company');
			companyModel.phantom = true;
			companyModel.save({
				scope: Ext.getCmp('companyForm'),
				success: function(company_record, operation) {
					// This code is called once the reply from the server has arrived.
					// The server response includes all necessary data for the new object.
					companyStore.add(company_record);

					// Tell all panels to load the data of the newly created object
					var compoundPanel = Ext.getCmp('companyCompoundPanel');
					compoundPanel.loadCompany(company_record);
				},
				failure: function(record, operation) {
					Ext.Msg.alert("Error durante la creacion de un nuevo company", operation.request.scope.reader.jsonData["message"]);
					// Re-enable this form
					Ext.getCmp('companyForm').setDisabled(true);

					// Return to the main companys Tab
					var companyContainer = Ext.getCmp('companyContainer');
					var mainTabPanel = Ext.getCmp('mainTabPanel');
					mainTabPanel.setActiveTab(companyContainer);
				}
			});

		} else {

			// Update an existing company
			// Loop through all form fields and store into the company store
			var companyModel = companyStore.findRecord('company_id',company_id);
			for(var field in values) {
				if (values.hasOwnProperty(field)) {
					value = values[field];
					companyModel.set(field, value);
				}
			}
	
			// Disable this form to indicate the request is working
			Ext.getCmp('companyForm').setDisabled(true);

			// Tell the store to update the server via it's REST proxy
			companyModel.save({
				scope: Ext.getCmp('companyForm'),
				success: function(record, operation) {
					// Refresh all forms to show the updated information
					var compoundPanel = Ext.getCmp('companyCompoundPanel');
					compoundPanel.loadCompany(companyModel);
				},
				failure: function(record, operation) {
					Ext.Msg.alert('Failed to save company', operation.request.scope.reader.jsonData["message"]);
				}
			});
		}
	    }
	}],

	loadCompany: function(rec){
		// Show this company, in case it was disabled before
		this.setDisabled(false);
		
		// Add the province to the store (province field is now a combobox but data maybe no correct
		provincesStore.load();
		var company_province_name = rec.get('company_province');
		var store_company = provincesStore.findRecord('name',company_province_name,0,false,true,true);
		if (store_company==null){
			provincesStore.add({'name': company_province_name});
		}
				
		// load the data from the record into the form
		this.loadRecord(rec);
	},

	// Somebody pressed the "New Company" button:
	// Prepare the form for entering a new company
	newCompany: function() {
	        var form = this.getForm();
	        form.reset();
		
		// Add the province to the store 
		provincesStore.load();
		
		// Ask the server to provide a new company name
		this.setNewCompanyName();		

		// Set the creation data of the new company
		Ext.Ajax.request({
			scope:	this,
			url:	'/intranet-sencha-ticket-tracker/today-date-time',
			success: function(response) {		// response is the current date-time
				var form = this.getForm();
				var date_time = response.responseText;
				form.findField('company_creation_date').setValue(date_time);
			}
		});

		// Set the default value for company_type
		var form = this.getForm();
		form.findField('company_type_id').setValue('10000191');
	},
	
	// Determine the new of the new company. Send an async AJAX request
	// to the server and tell the callback to insert the new company number
	// into the company_name field in this form.
	setNewCompanyName: function() {
	    Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/company-next-nr',
		success: function(response) {
		    // company-next-nr just returns a string which represents the name
		    var company_nr = response.responseText;
		    var form = this.getForm();
		    form.findField('project_nr').setValue(company_nr);
		    var company_name = '#intranet-sencha-ticket-tracker.New_Company_Prefix#' + company_nr;
		    form.findField('company_name').setValue(company_name);
		},
		failure: function(response) {
		    alert('#intranet-sencha-ticket-tracker.Failed_to_get_new_company_nr#');
		}
	    });
	}
});


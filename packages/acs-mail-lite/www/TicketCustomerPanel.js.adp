/**
 * intranet-sencha-ticket-tracker/www/TicketCustomerPanel.js
 * Shows the ticket's customer and allows to create a new customer.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketCustomerPanel.js.adp,v 1.6 2011/06/10 14:24:05 po34demo Exp $
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
	extend:	'Ext.form.Panel',
        alias:	'widget.ticketCustomer',
        id:	'ticketCustomerPanel',
	title:	'Ticket Customer',
	frame:	true,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 125
	},
        items: [{
                name:           'company_id',
                xtype:          'combobox',
                fieldLabel:     '#intranet-core.Customer#',
		valueNotFoundText: '#intranet-sencha-ticket-tracker.Create_New_Company#',
                value:          '#intranet-core.New_Customer#',
                valueField:     'company_id',
                displayField:   'company_name',
                store:          companyStore,
		listeners:{
		    // The user has selected a customer from the drop-down box.
		    // Lookup the customer and fill the form with the fields.
		    'select': function() {
			var customer_id = this.getValue();
			var cust = companyStore.findRecord('company_id',customer_id);
		        if (cust == null || typeof cust == "undefined") { return; }
			this.ownerCt.loadRecord(cust);
		    }
		}
        }, {
                name:           'company_name',
        	xtype:          'textfield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Company_name#',
                allowBlank:     false
        }, {
                name:           'vat_number',
        	xtype:          'textfield',
                fieldLabel:     '#intranet-core.VAT_Number#',
        },{
                name:           'company_type_id',
                xtype:          'combobox',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Company_Type#',
                value:          '',
                valueField:     'category_id',
                displayField:   'category_translated',
                store:          companyTypeStore
        }, {
                name:           'company_province',
                xtype:          'textfield',
                fieldLabel:     '#intranet-sencha-ticket-tracker.Province#'
        }],
        buttons: [{
		itemId:		'addButton',
        	text: 		'#intranet-core.Add_a_new_Company#',
        	handler: function(){
                        var form = this.ownerCt.ownerCt.getForm();
                        form.reset();                   // empty fields to allow for entry of new contact
                        var combo = form.findField('company_id');

			// Enable the button to save the new company
			var createButton = this.ownerCt.child('#createButton');
			createButton.show();
			
			// Disable the "Save Changes" button
			var createButton = this.ownerCt.child('#saveButton');
			createButton.hide();
			
			// Diable this button
			this.hide();
                }
	}, {
		itemId:		'saveButton',
        	text: 		'#intranet-core.Save_Changes#',
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			var combo = form.findField('company_id');
			var values = form.getFieldValues();
			var company_id = combo.getValue();
			
			// find the company in the store
			var company_record = companyStore.findRecord('company_id',company_id);
			company_record.set('company_name', form.findField('company_name').getValue());
			company_record.set('company_type_id', form.findField('company_type_id').getValue());
			company_record.set('vat_number', form.findField('vat_number').getValue());
			company_record.set('company_province', form.findField('company_province').getValue());

			// Tell the store to update the server via it's REST proxy
			companyStore.sync();
                }
	}, {
		itemId:		'createButton',
        	text: 		'#intranet-sencha-ticket-tracker.Save_New_Company#',
		hidden:		true,			// only show when in "adding mode"
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			var combo = form.findField('company_id');
			var values = form.getFieldValues();
			var company_name = values.company_name;
			values.company_id = null;

			var company = Ext.ModelManager.create(values, 'TicketBrowser.Company');
			company.phantom = true;
			company.save();

			// add the form values to the store.
			companyStore.add(company);
			// the store should create a new object now (does he?)

			// Tell the store to update the server via it's REST proxy
			companyStore.sync();

			// force reload of the drop-down
			delete combo.lastQuery;

			// set the combo to the new company
			var new_company = companyStore.findRecord('company_name',company_name);
			var new_company_id = new_company.get('company_id');
			combo.setValue(new_company_id);

			// Disable this button and re-enable the "New Company" button
			var addButton = this.ownerCt.child('#addButton');
                        addButton.show();
			this.hide();

			// Re-enable the "Save Changes" button
			var createButton = this.ownerCt.child('#saveButton');
			createButton.show();
                }
        }],

	// For a new ticket reset the values of the form.
	newTicket: function() {
                var form = this.getForm();
                form.reset();
	},

	loadTicket: function(rec){
		// Customer ID, may be NULL
		var customer_id = rec.data.company_id;
		var cust = companyStore.findRecord('company_id',customer_id);
	        if (cust == null || typeof cust == "undefined") { return; }

		// load the customer's information into the form.
		this.loadRecord(cust);
	}

});


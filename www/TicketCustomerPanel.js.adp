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
	extend:	'Ext.form.Panel',
        alias:	'widget.ticketCustomerPanel',
        id:	'ticketCustomerPanel',
	title:	'#intranet-sencha-ticket-tracker.Ticket_Customer#',
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
		
			// Inform the TicketCustomerPanel about the new company
			var contactPanel = Ext.getCmp('ticketContactPanel');
			contactPanel.loadCustomer(cust);
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
                fieldLabel:     '#intranet-core.VAT_Number#'
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
		itemId:		'viewButton',
        	text: 		'#intranet-sencha-ticket-tracker.Show_Customer#',
		handler:	function() {
			var form = this.ownerCt.ownerCt.getForm();
			var company_id = form.findField('company_id').getValue();
			var redirect = '/intranet/companies/view?company_id='+company_id; 
			window.open(redirect, '_blank');
		}
	}, {
		itemId:		'addButton',
        	text: 		'#intranet-sencha-ticket-tracker.button_New_Company#',
		width: 		120,
        	handler: function(){
                        var form = this.ownerCt.ownerCt.getForm();
                        form.reset();                   // empty fields to allow for entry of new contact
                        var combo = form.findField('company_id');

			// Enable the button to save the new company
			var createButton = this.ownerCt.child('#createButton');
			createButton.show();
			
			// Disable the "Save Changes" and "View Company" button
			var createButton = this.ownerCt.child('#saveButton');
			createButton.hide();
			var viewButton = this.ownerCt.child('#viewButton');
			viewButton.hide();
			
			// Diable this button
			this.hide();
                }
	}, {
		itemId:		'saveButton',
        	text: 		'#intranet-core.Save_Changes#',
		width: 		120,
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

			// Write the new company (if any...) to the ticket store
			var ticket_form = Ext.getCmp('ticketForm');
			var ticket_id = ticket_form.getForm().findField('ticket_id').getValue();
			var rec = ticketStore.findRecord('ticket_id',ticket_id);
			rec.set('company_id', company_id);
			ticketStore.sync();

			// Tell all panels to load the data of the newly created object
			var compoundPanel = Ext.getCmp('ticketCompoundPanel');
			compoundPanel.loadTicket(ticket_model);	
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

			// create a new company
			var company_record = Ext.ModelManager.create(values, 'TicketBrowser.Company');
			company_record.phantom = true;
			company_record.save({
				scope: Ext.getCmp('ticketForm'),
				success: function(record, operation) {
					// This code is called once the reply from the server has arrived.
					// The server response includes data.object_id for the new object.
					try {
						var resp = Ext.decode(operation.response.responseText);
						var company_id = resp.data[0].object_id + '';
					} catch (ex) {
						alert('Error creating object.\nThe server returned:\n' + operation.response.responseText);
						return;
					}

					// Store the new company_id into the ticketForm
					var ticketForm = Ext.getCmp('ticketForm');
					var ticket_id_field = ticketForm.getForm().findField('ticket_id');
					var ticket_id = ticket_id_field.getValue();
					var ticket_model = ticketStore.findRecord('ticket_id',ticket_id);

					// Store the company_id into the ticket model and update the REST server
					ticket_model.set('company_id', company_id);
					ticket_model.save();

					// Tell all panels to load the data of the newly created object
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticket_model);	
				}
			});
                }
        }],

	// For a new ticket reset the values of the form.
	newTicket: function() {
                var form = this.getForm();
                form.reset();

		// Don't show this form for new tickets
		this.hide();
	},

	loadTicket: function(rec){

		// Customer ID, may be NULL
		var customer_id;
		if (rec.data.hasOwnProperty('company_id')) { customer_id = rec.data.company_id; }

		var cust = companyStore.findRecord('company_id',customer_id);
	        if (cust == null || typeof cust == "undefined") { return; }

		// load the customer's information into the form.
		this.loadRecord(cust);

		// Show the form
		this.show();
	}

});


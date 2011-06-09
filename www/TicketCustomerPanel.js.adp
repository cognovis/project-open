/**
 * intranet-sencha-ticket-tracker/www/TicketCustomerPanel.js
 * Shows the ticket's customer and allows to create a new customer.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketCustomerPanel.js.adp,v 1.3 2011/06/09 17:04:29 mcordova Exp $
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
                fieldLabel:     '#intranet-core.Customer#',
                allowBlank:     false
        }, {
                name:           'vat_number',
        	xtype:          'textfield',
                fieldLabel:     '#intranet-core.VAT_Number#',
        },{
                name:           'company_type_id',
                xtype:          'combobox',
                fieldLabel:     '#intranet-core.Customer_Type#',
                value:          '',
                valueField:     'category_id',
                displayField:   'category',
                store:          companyTypeStore
        }, {
                xtype:          'textfield',
                fieldLabel:     'Province',
                name:           'ticket_province'
        }],
        buttons: [{
        	text: '#intranet-core.Add_a_new_Company#',
        	handler: function(){
                        alert ('Not implemented Yet')
                }
        }],

	// For a new ticket reset the values of the form.
	onNewTicket: function() {
		this.reset();
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


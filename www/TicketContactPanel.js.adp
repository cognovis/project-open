/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
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


Ext.define('TicketBrowser.TicketContactPanel', {
	extend: 'Ext.form.Panel',
	frame:true,
	title: 'Ticket Contact',
        alias: 'widget.ticketContact',
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 125
	},
        items: [{
        	xtype:          'textfield',
                fieldLabel:     'Razon social',
                name:           'ticket_company_name',
                allowBlank:     false
        }, {
        	xtype:          'textfield',
                fieldLabel:     'DNI/NIF',
                name:           'nif_cif'
        }, {
                xtype:          'radiofield',
                name:           'ticket_language',
                value:          'eu_EU',
                fieldLabel:     'Idioma',
                boxLabel:       'Euskera'
        }, {
                xtype:          'radiofield',
                name:           'ticket_language',
                value:          'es_ES',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false,
                boxLabel:       'Castellano'
        },{
                xtype:          'combobox',
                fieldLabel:     'Tipo de Sociedad',
                name:           'company',
                value:          '',
                valueField:     'category_id',
                displayField:   'category',
                store:          companyTypeStore
        }, {
                xtype:          'textfield',
                fieldLabel:     'Province',
                name:           'ticket_province'
        }, {
                // Here a fieldset?
                xtype:          'textfield',
                fieldLabel:     '#intranet-core.First_names#',
                name:           'ticket_first_contact_name',
                allowBlank:     false
        },
        {
                xtype:          'textfield',
                fieldLabel:     '(Last name)',
                name:           'ticket_first_contact_last_name'
        },
        {
                xtype:          'radiofield',
                name:           'ticket_sex',
                value:          '1',
                fieldLabel:     'Genre',
                boxLabel:       'male'
        },
        {
                xtype:          'radiofield',
                name:           'ticket_sex',
                value:          '0',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false,
                boxLabel:       'female'
        }],
        buttons: [{
        	text: 'New Company',
        	handler: function(){
                        alert ('Not implemented Yet')
                }
        }, {
        	text: 'New Contact',
        	handler: function(){
                        alert ('Not implemented Yet')
                }
        }],

	loadTicket: function(rec){

		// Customer ID, may be NULL
		var customer_id = rec.data.ticket_customer_contact_id;
		var cust = employeeStore.findRecord('user_id',customer_id);
	        if (cust == null || typeof cust == "undefined") { return; }

		this.loadRecord(cust);
	}

});


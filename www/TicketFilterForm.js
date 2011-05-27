/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
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

var ticketFilterForm = Ext.define('TicketBrowser.TicketFilterForm', {
	extend: 'Ext.form.Panel',	
	alias: 'widget.ticketfilterform',
	title: 'Ticket Filters',
	bodyStyle:'padding:5px 5px 0',
	defaultType: 'textfield',
	defaults: { anchor: '100%' },
	minWidth: 200,
	stanardsubmit:true,
	items: [
	{	name: 'vat_number', 
		fieldLabel: 'VAT ID' 
	}, {	
		name: 'company_name', 
		fieldLabel: 'Company Name'
	}, {
		fieldLabel: 'Company Type',
		name: 'company_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: companyTypeStore
	}, {
		fieldLabel: 'Program',
		name: 'program_id',
		xtype: 'combobox',
                valueField: 'project_id',
                displayField: 'project_name',
		forceSelection: true,
		queryMode: 'remote',
		store: programStore
	}, {
		fieldLabel: 'Prio',
		name: 'ticket_prio_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketPriorityStore
	}, {
		fieldLabel: 'SLA',
		name: 'parent_id',
		xtype: 'combobox',
                valueField: 'project_id',
                displayField: 'project_name',
		allowBlank: true,
		forceSelection: true,
		queryMode: 'remote',
		store: ticketSlaStore
	}
	],

	buttons: [
	{
            text: 'Clear Form',
	    handler: function(){
		var form = this.up('form').getForm();
		form.reset();
	    }
	}, {
            text: 'Submit',
	    handler: function(){
		var form = this.up('form').getForm();
		var filterValues = form.getFieldValues();
		var panel = this.up('form');

		// tell the grid to get new tickets with filter variables
		panel.ownerCt.ownerCt.filterTickets(filterValues);
	    }
	}
	]
});

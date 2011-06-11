/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketFilterForm.js.adp,v 1.11 2011/06/10 14:24:05 po34demo Exp $
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
	extend:		'Ext.form.Panel',	
	alias:		'widget.ticketFilterForm',
	title:		'Ticket Filters',
	id:		'ticketFilterForm',
	bodyStyle:	'padding:5px 5px 0',
	defaultType:	'textfield',
	defaults:	{ anchor: '100%' },
	minWidth:	200,
	standardsubmit:	true,
	items: [
	{	name: 'group', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Group#'
	}, {	name: 'user', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Assigned_to#'
	}, {	name: 'vat_number', 
		fieldLabel: '#intranet-core.VAT_Number#'
	}, {	
		name: 'company_name', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Name#'
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Type#',
		name: 'company_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: companyTypeStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Program#',
		name: 'program_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: requestAreaProgramStore
	}, {	name: 'ticket_file', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Ticket_File_Number#'
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Area#',
		name: 'ticket_area_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: requestAreaStore
	}, {
		fieldLabel: '#intranet-helpdesk.SLA#',
		name: 'parent_id',
		xtype: 'combobox',
                valueField: 'project_id',
                displayField: 'project_name',
		allowBlank: true,
		forceSelection: true,
		queryMode: 'remote',
		store: ticketSlaStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Ticket_Type#',
		name: 'ticket_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
	}, {
		fieldLabel: '#intranet-helpdesk.Ticket_Nr#',
		name: 'project_nr'
	}, {
		fieldLabel: '#intranet-helpdesk.Status#',
		name: 'ticket_status_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketStatusStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Incoming_Channel#',
		name: 'ticket_channel_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketChannelStore
	}, {
		fieldLabel: '#intranet-core.Prio#',
		name: 'ticket_prio_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketPriorityStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Date_Since#',
		name: 'start_date',
		xtype: 'datefield',
		format: 'Y-m-d',
		submitFormat: 'Y-m-d'
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Date_Until#',
		name: 'end_date',
		xtype: 'datefield',
		format: 'Y-m-d',
		submitFormat: 'Y-m-d'
	}
	],

	buttons: [{
            text: '#intranet-sencha-ticket-tracker.Clear_Form#',
	    handler: function(){
		var form = this.up('form').getForm();
		form.reset();
	    }
	}, {
            text: '#intranet-sencha-ticket-tracker.button_Search#',
	    handler: function() {
		var form = this.up('form').getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('ticketGrid');
		grid.filterTickets(filterValues);
	}

	}],

	afterRender: function() {
		var filterForm = Ext.getCmp('ticketFilterForm');
		var form = filterForm.getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('ticketGrid');
		grid.filterTickets(filterValues);
		return true;
	}

});



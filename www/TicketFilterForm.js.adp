/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketFilterForm.js.adp,v 1.22 2011/06/23 09:47:53 po34demo Exp $
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
	title:		'#intranet-sencha-ticket-tracker.Ticket_Filters#',
	id:		'ticketFilterForm',
	bodyStyle:	'padding:5px 5px 0',
	defaultType:	'textfield',
	defaults:	{ anchor: '100%' },
	fieldDefaults:	{
		enableKeyEvents: true
	},
	minWidth:	200,
	standardsubmit:	true,
	items: [
	{	name: 'assigned_queue_id', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Group#',
		xtype: 'combobox',
                valueField: 'group_id',
                displayField: 'group_name',
		emptyText: '#intranet-sencha-ticket-tracker.My_Groups#',
		forceSelection: true,
		queryMode: 'remote',
		store: profileStore,
		width: 300,
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		name: 'creation_user',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Creation_User#',
                xtype:          'combobox',
                valueField:     'user_id',
                displayField:   'name',
                store:          userStore,
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		name: 'vat_number', 
		fieldLabel: '#intranet-core.VAT_Number#',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {	
		name: 'company_name', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Name#',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Type#',
		name: 'company_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: companyTypeStore,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Program#',
		name:		'ticket_area_id',
		xtype:		'combobox',
		displayField:	'category_translated',
		valueField:	'category_id',
		store:		ticketAreaStore,
		queryMode:	'remote',
        	width: 		300,
		forceSelection: true,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function() { alert('key'); }
		}
	}, {
		name: 'ticket_file', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Ticket_File_Number#',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_Type#',
		name:		'ticket_type_id',
		xtype:		'combobox',
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection:	true,
		queryMode:	'remote',
		store:		ticketTypeStore,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel: '#intranet-helpdesk.Ticket_Nr#',
		name: 'project_name',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel:	'#intranet-helpdesk.Status#',
		name:		'ticket_status_id',
		xtype:		'combobox',
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection:	true,
		queryMode:	'remote',
		store:		ticketStatusStore,
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel:	'#intranet-sencha-ticket-tracker.Incoming_Channel#',
		name:		'ticket_incoming_channel_id',
		xtype:		'combobox',
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		queryMode:	'remote',
		store: ticketChannelStore,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners: {
			'change': function(field, values) { if (null == values) { this.reset(); }},
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel:	'#intranet-sencha-ticket-tracker.Date_Since#',
		name:		'start_date',
		xtype:		'datefield',
		format:		'Y-m-d',
		submitFormat:	'Y-m-d',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Date_Until#',
		name: 'end_date',
		xtype: 'datefield',
		format: 'Y-m-d',
		submitFormat: 'Y-m-d',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}],

	buttons: [{
            text: '#intranet-sencha-ticket-tracker.Clear_Form#',
	    handler: function(){
		var form = this.up('form').getForm();
		form.reset();
	    }
	}, {
            text: '#intranet-sencha-ticket-tracker.button_Search#',
	    handler: function() {
		var panel = this.up('form');
		panel.onSearch();
	    }

	}],

	onSearch: function() {
		var form = this.getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('ticketGrid');
	
		grid.filterTickets(filterValues);
	},

	afterRender: function() {
		var filterForm = Ext.getCmp('ticketFilterForm');
		var form = filterForm.getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('ticketGrid');
		grid.filterTickets(filterValues);
		return true;
	}

});



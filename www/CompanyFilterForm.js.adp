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

var companyFilterForm = Ext.define('TicketBrowser.CompanyFilterForm', {
	extend:		'Ext.form.Panel',	
	alias:		'widget.companyFilterForm',
	title:		'#intranet-sencha-ticket-tracker.Company_Filters#',
	id:		'companyFilterForm',
	bodyStyle:	'padding:5px 5px 0',
	defaultType:	'textfield',
	defaults:	{ anchor: '100%' },
	fieldDefaults:	{
		enableKeyEvents:	true,
		typeAhead:		true,
		triggerType:		'all'
	},
	minWidth:	200,
	standardsubmit:	true,
	items: [{
		name: 'creation_user',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Creation_User#',
                xtype:          'combobox',
                valueField:     'user_id',
                displayField:   'name',
		queryMode:	'local',
                store:          userEmployeeStore,
		listeners: {
			'change': function(field, values) { 
				if (null == values) { this.reset(); }
			},
			'keypress': function(field, key) {
				if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } 
			}
		}
	}, {
		name: 'vat_number', 
		fieldLabel: '#intranet-sencha-ticket-tracker.VAT_Number#',
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
		fieldLabel:	'#intranet-sencha-ticket-tracker.Company_Type#',
		name:		'company_type_id',
		xtype:		'combobox',
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		queryMode:	'local',
		store:		companyTypeStore,
		typeAhead:	true,
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
		fieldLabel:	'#intranet-sencha-ticket-tracker.Telephone#',
		name:		'ticket_telephone',	
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}	
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Nr#',
		name: 'project_name',
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel:	'#intranet-sencha-ticket-tracker.Status#',
		name:		'company_status_id',
		xtype:		'combobox',
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection:	true,
		queryMode:	'local',
		store:		companyStatusStore,
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
		startDay:	1,
		listeners: {
			'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
		}
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Date_Until#',
		name: 'end_date',
		xtype: 'datefield',
		format: 'Y-m-d',
		submitFormat: 'Y-m-d',
		startDay:	1,
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
		var grid = Ext.getCmp('companyGrid');
	
		grid.filterCompanies(filterValues);
	},

	afterRender: function() {
		var filterForm = Ext.getCmp('companyFilterForm');
		var form = filterForm.getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('companyGrid');
		grid.filterCompanies(filterValues);
		return true;
	}

});



/**
 * intranet-sencha-ticket-tracker/www/CompanyContactBizObjectMemberGrid.js
 * Shows the members of a business object (company, project, ticket or office).
 *
 * @author David Blanco (david.blanco@grupoversia.com)
 * @creation-date 2011-08
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

var companyContactBizObjectMemberStore = Ext.create('Ext.data.Store', {
    model: 'TicketBrowser.BizObjectMember',
    storeId: 'companyContactbizObjectMemberStore',
    autoLoad: false,
    remoteSort: false,
    remoteFilter: false,
    pageSize: 5				// Enable pagination
});

companyContactBizObjectMemberStore.on({
	'load':{
	    fn: function(store, records, options){
	        var grid = Ext.getCmp('companyContactBizObjectMemberGrid');
			var num = companyContactBizObjectMemberStore.data.length;
			grid.height = grid.minHeight + num*20;
	    },
	    scope:this
	}
});

var companyContactBizObjectMemberGrid = Ext.define('TicketBrowser.CompanyContactBizObjectMemberGrid', {
    extend:	'Ext.grid.Panel',
    alias:	'widget.companyContactBizObjectMemberGrid',
    id:		'companyContactBizObjectMemberGrid',
    store: 	companyContactBizObjectMemberStore,
    minWidth:	300,
    minHeight:	60,
    iconCls:	'icon-grid',

    listeners: {
		itemdblclick: function(view, record, item, index, e) {
			// Open the User in the TicketContactForm
			var contact_id = record.get('object_id_two');
	
	        var contact_record = userStore.findRecord('user_id',contact_id);
	        if (contact_record == null || typeof contact_record == "undefined") { return; }
	
	        // load the information from the record into the form
			var companyContactContactForm = Ext.getCmp('companyContactContactForm');
			companyContactContactForm.loadUser(contact_record);
		}
    },

    dockedItems: [{
		dock: 'bottom',
		xtype: 'pagingtoolbar',
		store: companyContactBizObjectMemberStore,
		displayInfo: true,
		displayMsg: '#intranet-sencha-ticket-tracker.Displaying_versions_0_1_of_2_#',
		emptyMsg: '#intranet-sencha-ticket-tracker.No_items#',
		beforePageText: '#intranet-sencha-ticket-tracker.Page#'
    }],
    columns: [{
	header:		'#intranet-sencha-ticket-tracker.Contact#',
	minWidth:	100,
	flex:		1,
	renderer: function(value, o, record) {
	    return userStore.name_from_id(record.get('object_id_two'));
	},
	sortable:	false
    }, {
	header: 	'#intranet-sencha-ticket-tracker.Object_Member_Role#',
	renderer: function(value, o, record) {
	    return bizObjectRoleStore.category_from_id(record.get('object_role_id'));
	},
	sortable:	false
    }],

    loadCompany: function(rec){
		// Load the company's contacts into the form.
		var customer_id = rec.get('company_id');
		this.loadCompany(customer_id);
    },

    // Load new data if the user has selected a new customer
    loadCompany: function(customer){
		var customer_id =  customer;
		switch (typeof customer) {
			case 'string':
				customer_id = customer;
				break;
			case 'number':
				customer_id = customer + '';
				break;
			default:
				// We probably got the entire customer_model here
				var customer_id = customer.get('company_id');
				break;
		}
	
		// Save the property in the proxy, which will pass it directly to the REST server
		companyContactBizObjectMemberStore.proxy.extraParams['object_id_one'] = customer_id;
		companyContactBizObjectMemberStore.load();
    },

    newCompany: function() {
    	companyContactBizObjectMemberStore.removeAll();
		companyContactBizObjectMemberStore.proxy.extraParams['object_id_one'] = "null";
		companyContactBizObjectMemberStore.load();
    }
});
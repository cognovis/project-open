/**
 * intranet-sencha-ticket-tracker/www/BizObjectMemberGrid.js
 * Shows the members of a business object (company, project, ticket or office).
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: BizObjectMemberGrid.js.adp,v 1.2 2011/06/17 09:57:06 po34demo Exp $
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


// Local store definition. We have to redefine the store every time we show the grid
var bizObjectMemberStore = Ext.create('Ext.data.Store', {
    model: 'TicketBrowser.BizObjectMember',
    storeId: 'bizObjectMemberStore',
    autoLoad: false,
    remoteSort: false,
    remoteFilter: false,
    pageSize: 10,			// Enable pagination
    sorters: [{
	property: 'object_role_id',
	direction: 'DESC'
    }]
});

var bizObjectMemberGrid = Ext.define('TicketBrowser.BizObjectMemberGrid', {
    extend:	'Ext.grid.Panel',
    alias:	'widget.bizObjectMemberGrid',
    id:		'bizObjectMemberGrid',
    store: 	bizObjectMemberStore,
    minWidth:	300,
    minHeight:	200,
    frame:	true,
    iconCls:	'icon-grid',

    listeners: {
	itemdblclick: function(view, record, item, index, e) {
		// Open the User in the TicketContactForm
		var contact_id = record.get('object_id_two');

                var contact_record = userStore.findRecord('user_id',contact_id);
                if (contact_record == null || typeof contact_record == "undefined") { return; }

                // load the information from the record into the form
		var ticketContactForm = Ext.getCmp('ticketContactForm');
		ticketContactForm.loadUser(contact_record);
	}
    },

    dockedItems: [{
		dock: 'bottom',
		xtype: 'pagingtoolbar',
		store: bizObjectMemberStore,
		displayInfo: true,
		displayMsg: '#intranet-sencha-ticket-tracker.Displaying_versions_0_1_of_2_#',
		emptyMsg: '#intranet-sencha-ticket-tracker.No_items#',
		beforePageText: '#intranet-sencha-ticket-tracker.Page#'
    }],
    columns: [{
	header:		'#intranet-core.Contact#',
	minWidth:	100,
	flex:		1,
	renderer: function(value, o, record) {
	    return userStore.name_from_id(record.get('object_id_two'));
	}
    }, {
	header: 	'#intranet-sencha-ticket-tracker.Object_Member_Role#',
	renderer: function(value, o, record) {
	    return bizObjectRoleStore.category_from_id(record.get('object_role_id'));
	}
    }],

    loadTicket: function(rec){
	// Show this list of members. A new ticket doesn't need this list...
	this.show();

	// Save the property in the proxy, which will pass it directly to the REST server
	var company_id = rec.get('company_id');
	bizObjectMemberStore.proxy.extraParams['object_id_one'] = company_id;
	bizObjectMemberStore.load();
    },

    // Somebody pressed the "New Ticket" button:
    // We don't have to show this list until the object has been created.
    newTicket: function() {
	this.hide();
    }

});





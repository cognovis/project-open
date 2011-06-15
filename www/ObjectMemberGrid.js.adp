/**
 * intranet-sencha-ticket-tracker/www/ObjectMemberGrid.js
 * Shows the members of a business object (company, project, ticket or office).
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: ObjectMemberGrid.js.adp,v 1.1 2011/06/15 14:51:52 po34demo Exp $
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
var objectMemberStore = Ext.create('Ext.data.Store', {
    model: 'TicketBrowser.ObjectMember',
    storeId: 'objectMemberStore',
    autoLoad: false,
    remoteSort: true,
    remoteFilter: true,
    pageSize: 10,			// Enable pagination
    sorters: [{
	property: 'member_name',
	direction: 'DESC'
    }],
    proxy: {
	type: 'rest',
	url: '/intranet-sencha-ticket-tracker/object-member-datasource',
	appendId: true,
	extraParams: { format: 'json', object_id: 0 },
	reader: { type: 'json', root: 'data' }
    }
});

var objectMemberGrid = Ext.define('TicketBrowser.ObjectMemberGrid', {
    extend:	'Ext.grid.Panel',
    alias:	'widget.objectMemberGrid',
    id:		'objectMemberGrid',
    store: 	objectMemberStore,
    minWidth:	300,
    minHeight:	200,
    frame:	true,
    iconCls:	'icon-grid',

    dockedItems: [{
		dock: 'bottom',
		xtype: 'pagingtoolbar',
		store: objectMemberStore,
		displayInfo: true,
		displayMsg: '#intranet-sencha-ticket-tracker.Displaying_versions_0_1_of_2_#',
		emptyMsg: '#intranet-sencha-ticket-tracker.No_items#',
		beforePageText: '#intranet-sencha-ticket-tracker.Page#'
    }],
    columns: [{
	header: '#intranet-core.Contact#',
	renderer: function(value, o, record) {
	    return userStore.name_from_id(record.get('object_id_two'));
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Role#',
	renderer: function(value, o, record) {
	    return bizObjectRoleStore.category_from_id(record.get('object_role_id'));
	}
    }],

    loadTicket: function(rec){
	// Show this list of members. A new ticket doesn't need this list...
	this.show();

	// Save the property in the proxy, which will pass it directly to the REST server
	var ticket_id = rec.data.ticket_id;
	objectMemberStore.proxy.extraParams['object_id_one'] = ticket_id;
	objectMemberStore.load();
    },

    // Somebody pressed the "New Ticket" button:
    // We don't have to show this list until the object has been created.
    newTicket: function() {
	this.hide();
    }

});





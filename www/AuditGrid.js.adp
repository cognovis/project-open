/**
 * intranet-sencha-ticket-tracker/www/AuditGrid.js
 * Grid table for ]po[ file storage
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


var auditGridSelModel = Ext.create('Ext.selection.CheckboxModel', {
    listeners: {
	selectionchange: function(sm, selections) {
	    // var grid = this.view;
	    // grid.down('#removeButton').setDisabled(selections.length == 0);
	}
    }
});


// Local store definition. We have to redefine the store every time we show
// files for a different ticket
var auditStore = Ext.create('Ext.data.Store', {
    model: 'TicketBrowser.TicketAudit',
    storeId: 'auditStore',
    autoLoad: false,
    remoteSort: true,
    remoteFilter: true,
    pageSize: 10,			// Enable pagination
    sorters: [{
	property: 'audit_date',
	direction: 'DESC'
    }],
    proxy: {
	type: 'rest',
	url: '/intranet-sencha-ticket-tracker/object-audit-datasource',
	appendId: true,
	extraParams: { format: 'json', object_id: 0 },
	reader: { type: 'json', root: 'data' }
    }
});


var auditGrid = Ext.define('TicketBrowser.AuditGrid', {
    extend:	'Ext.grid.Panel',
    alias:	'widget.auditGrid',
    id:		'auditGrid',
    store: 	auditStore,
    minWidth:	300,
    minHeight:	100,
    frame:	true,
    iconCls:	'icon-grid',

    dockedItems: [{
		dock: 'bottom',
		xtype: 'pagingtoolbar',
		store: auditStore,
		displayInfo: true,
		displayMsg: '#intranet-sencha-ticket-tracker.Displaying_tickets_0_1_of_2_#',
		emptyMsg: '#intranet-sencha-ticket-tracker.No_items#',
		beforePageText: '#intranet-sencha-ticket-tracker.Page#'
    }],
    columns: [
	      {
		  header: '#intranet-sencha-ticket-tracker.Request#',
		  dataIndex: 'ticket_request',
		  sortable: false, 
		  flex: 1,
		  minWidth: 100,
		  renderer: function(value, o, record) {
		      var name = record.get('ticket_request');
		      return name;
		  }
	      }, {
		  header: '#intranet-sencha-ticket-tracker.Resolution#',
		  dataIndex: 'ticket_solution',
		  flex: 1,
		  sortable: false, 
		  minWidth: 100,
		  renderer: function(value, o, record) {
		      var name = record.get('ticket_solution');
		      return name;
		  }
	      }, {
			header: '#intranet-helpdesk.Status#',
			dataIndex: 'ticket_status_id',
			width: 60,
			sortable: true, 
			renderer: function(value, o, record) {
				return ticketStatusStore.category_from_id(record.get('ticket_status_id'));
			}
	      },
	      {text: "#intranet-core.Date#", sortable: true, dataIndex: 'audit_date'},
	      {
			header: "#intranet-core.User#", 
			sortable: true, 
                        renderer: function(value, o, record) {
                                return userStore.name_from_id(record.get('audit_user_id'));
                        }
		}
	 ],
    columnLines: true,
    selModel: auditGridSelModel,

    // Load the files for the new ticket
    loadTicket: function(rec){

	// Save the property in the proxy, which will pass it directly to the REST server
	var ticket_id = rec.data.ticket_id;
	auditStore.proxy.extraParams['object_id'] = ticket_id;
	auditStore.load();
    },

    // Somebody pressed the "New Ticket" button:
    // Prepare the form for entering a new ticket
    newTicket: function() {
	this.loadTicket({data: {object_id: 0}});
	this.hide();
    }

});





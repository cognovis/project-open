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


// Local store definition. We have to redefine the store every time we show
// files for a different ticket
var auditStore = Ext.create('Ext.data.Store', {
    model: 'TicketBrowser.TicketAudit',
    storeId: 'auditStore',
    autoLoad: false,
    remoteSort: true,
    remoteFilter: true,
    pageSize: 5,			// Enable pagination
    sorters: [{
		property: 'audit_date',
		direction: 'DESC'
    }]
});

auditStore.on({
    'load':{
        fn: function(store, records, options){
            //store is loaded, now you can work with it's records, etc.
            var grid = Ext.getCmp('auditGrid');
			var num = auditStore.data.length;
			grid.height = grid.minHeight + num*20;
        },
        scope:this
    }
});

var auditGrid = Ext.define('TicketBrowser.AuditGrid', {
    extend:	'Ext.grid.Panel',
    alias:	'widget.auditGrid',
    id:		'auditGrid',
    store: 	auditStore,
    minHeight:	75,
	listeners:	{
		itemdblclick: function(view, record, item, index, e) {
			Ext.create('Ext.window.Window', {
			    title: 'Detalle '+record.get('audit_date').substring(0,19),
			    //layout: 'fit',
			    height: 400,
			    width: 800,		
				defaults: {		
					margin: '5 10 0 0'				
				},			    	    
				layout: {
				    type: 'table',
				    columns: 4
				},	    
			    items: [
			    {  
					name:		'audit_audit_date',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Audit_Date#',
					value:		record.get('audit_date').substring(0,19),
					colspan: 2
			    }, 			    {  
					name:		'audit_ticket_status_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Status#',
					value:		record.get('ticket_status_id').substring(0,19),
					colspan: 2
			    }, {
					name:		'audit_ticket_request',
					xtype:		'textareafield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Request#',
					labelAlign:	'top',
					value:		record.get('ticket_request').split('\\n').join('\n'),
					colspan: 2
			    }, {
					name:		'audit_ticket_resolution',
					xtype:		'textareafield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Resolution#',
					labelAlign:	'top',
					value: 		record.get('ticket_resolution').split('\\n').join('\n'),
					colspan: 2
				}]
			}).show();
		}
	},    
    dockedItems: [{
		dock: 'bottom',
		xtype: 'pagingtoolbar',
		store: auditStore,
		displayInfo: true,
		displayMsg: '#intranet-sencha-ticket-tracker.Displaying_versions_0_1_of_2_#',
		emptyMsg: '#intranet-sencha-ticket-tracker.No_items#',
		beforePageText: '#intranet-sencha-ticket-tracker.Page#'
    }],
    columns: [{
		text: "#intranet-sencha-ticket-tracker.Audit_Date#", 
		sortable: true, 
		minWidth: 50,
		hidden: false,
		dataIndex: 'audit_date',
		renderer: function(value, o, record) {
			// Only seconds
		    return value.substring(0,19);
		}	
    }, {
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
	dataIndex: 'ticket_resolution',
	flex: 1,
	sortable: false, 
	minWidth: 100,
	renderer: function(value, o, record) {
	    var name = record.get('ticket_resolution');
	    return name;
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Status#',
	dataIndex: 'ticket_status_id',
	width: 60,
	sortable: true, 
	renderer: function(value, o, record) {
	    return ticketStatusStore.category_from_id(record.get('ticket_status_id'));
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Type#',
	dataIndex: 'ticket_type_id',
	width: 60,
	sortable: true, 
	hidden: true,
	renderer: function(value, o, record) {
	    return ticketTypeStore.category_from_id(record.get('ticket_type_id'));
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Escalated#',
	dataIndex: 'ticket_queue_id_pretty',
	width: 60,
	sortable: true, 
	renderer: function(value, o, record) {
	    var queueName = profileStore.name_from_id(record.get('ticket_queue_id'));
	    if ("Employees" == queueName) { queueName = ''; }
	    return queueName;
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Area#',
	width: 60,
	hidden: true,
	renderer: function(value, o, record) {
	    return ticketAreaStore.category_from_id(record.get('ticket_area_id'));
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Customer#',
	dataIndex: 'company_id',
	width: 60,
	hidden: true,
	renderer: function(value, o, record) {
	    return companyStore.name_from_id(record.get('company_id'));
	}
    }, {
	header: '#intranet-core.Contact#',
	dataIndex: 'ticket_customer_contact_id',
	hidden: true,
	renderer: function(value, o, record) {
	    return userStore.name_from_id(record.get('ticket_customer_contact_id'));
	}
    }, {
	header: '#intranet-sencha-ticket-tracker.Ticket_File_Number#',
	hidden: true,
	dataIndex: 'ticket_file'
    },  {
	header: '#intranet-sencha-ticket-tracker.Creation_Date#',
	dataIndex: 'ticket_creation_date'
    }, {
	header: '#intranet-sencha-ticket-tracker.Reaction_Date#',
	dataIndex: 'ticket_reaction_date'
    }, {
	header: '#intranet-sencha-ticket-tracker.Escalation_Date#',
	dataIndex: 'ticket_escalation_date'
    }, {
	header: '#intranet-sencha-ticket-tracker.Close_Date#',
	dataIndex: 'ticket_done_date'
    }, {
	header: '#intranet-sencha-ticket-tracker.Contact#',
	dataIndex: 'ticket_customer_contact_id',
	hidden: true,
	renderer: function(value, o, record) {
	    return userStore.name_from_id(record.get('ticket_customer_contact_id'));
	}
    }, {
	header: "#intranet-sencha-ticket-tracker.Incoming_Channel#", 
	dataIndex: 'ticket_incoming_channel_id',
	renderer: function(value, o, record) {
		var ticket_incoming_channel_id = record.get('ticket_incoming_channel_id');
		
		if (!Ext.isEmpty(ticket_incoming_channel_id)) {
			var channel_record = ticketOriginStore.findRecord('category_id',ticket_incoming_channel_id);
			var tree_sort_key_channel_record_father = channel_record.get('tree_sortkey').substring(0,8);
			
			return ticketOriginStore.category_from_id(tree_sort_key_channel_record_father);
		}
	    return '';
	}
    }, {
	header: "#intranet-sencha-ticket-tracker.Incoming_Channel_Detail#", 
	dataIndex: 'ticket_incoming_channel_id',
	renderer: function(value, o, record) {
	    return ticketOriginStore.category_from_id(record.get('ticket_incoming_channel_id'));
	}
    },{
	header: "#intranet-sencha-ticket-tracker.IP_Address#", 
	hidden: true, 
	dataIndex: 'audit_ip'
    }],

    columnLines: true,

    // Load the files for the new ticket
    loadTicket: function(rec){

		// The panel may have been hidden during newTicket()
		this.show();
	
		// Save the property in the proxy, which will pass it directly to the REST server
		var ticket_id = rec.data.ticket_id;
		auditStore.proxy.extraParams['object_id'] = ticket_id;
		auditStore.loadPage(1);
	    },

    // Somebody pressed the "New Ticket" button:
    // Prepare the form for entering a new ticket
    newTicket: function() {
		this.loadTicket({data: {object_id: 0}});		// Really necessary? Reset the proxy.
		//this.hide();
    }

});





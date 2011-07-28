/**
 * intranet-sencha-ticket-tracker/www/TicketCompoundPanel.js
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


var ticketCompountPanel = Ext.define('TicketBrowser.TicketCompoundPanel', {
    extend:		'Ext.container.Container',
    alias:		'widget.ticketCompoundPanel',
    id:			'ticketCompoundPanel',
    title:		'Loading...',
    layout:		'border',
    deferredRender:	false,
    split:		true,

    items: [{
	itemId:		'center',
	region: 	'center',
	layout: 	'border',
	minWidth:	200,
	split:		true,

	items: [{
		itemId: 'ticketForm',
		xtype: 'ticketForm',
		title: '#intranet-core.Ticket#',
		split:	true,
		region:	'north'
	}, {
		itemId:	'ticketCustomerPanel',
		title:	'#intranet-sencha-ticket-tracker.Company#',
		xtype:	'ticketCustomerPanel',
		split:	true,
		region:	'center'
	}, {
		itemId: 'ticketContactPanel',
		title: '#intranet-core.Contact#',
		xtype: 'ticketContactPanel',
		split:	true,
		region:	'south'
	}]
    }, {
	itemId:	'east',
	region: 'east',
	layout:	'border',
	width:	1050,
	split:	true,
	items: [{
		itemId: 'auditGrid',
		title: '',
		xtype: 'auditGrid',
		split:	true,
		region:	'north',
		minHeight: 100
	}, {
		itemId: 'ticketFormRight',
		title: '',
		xtype: 'ticketFormRight',
		split:	true,
		region:	'center'
	}, {
		itemId: 'fileStorageGrid',
		title: '#intranet-filestorage.Filestorage#',
		xtype: 'fileStorageGrid',
		split:	true,
		region:	'south',
		minHeight: 140
	}]
    }],

    // Create a copy of the currrent ticket
    onCopy: function() {
	var ticketForm = this.child('#center').child('#ticketForm');
	var ticket_id_field = ticketForm.getForm().findField('ticket_id');
	var old_ticket_id = ticket_id_field.getValue();
	ticket_id_field.setValue('');

	// Create a new ticket name
	ticketForm.setNewTicketName();

	// Save the copied ticket(?)
	// ...
	
	// Write out an alert message
	alert('#intranet-sencha-ticket-tracker.A_new_ticket_has_been_created#')
    },

    // Delete the selected ticket
    onDelete: function() {
	
	// Get the ID of the current ticket
	var ticketForm = this.child('#center').child('#ticketForm');
	var ticket_id_field = ticketForm.getForm().findField('ticket_id');
	var ticket_id = ticket_id_field.getValue();
	if (null == ticket_id || '' == ticket_id) { return; }

	// Get the 
	var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);

	// Delete the ticket. This triggers a DELETE server request
	ticketModel.destroy({
		success: function(record, operation) {
	 		console.log('Ticket #'+ticketModel.get('project_nr')+' was destroyed.');
			ticketStore.remove(ticketModel);
		},
		failure: function(record, operation) {
			Ext.Msg.alert('Error borrando Ticket #'+ticketModel.get('project_nr')+':\nSolo administradores tienen permisso para borrar tickets.', operation.request.scope.reader.jsonData["message"]);
		}
	});

	// Switch back to the ticket list page
	Ext.getCmp('mainTabPanel').setActiveTab(0);
    },

    // Called from the TicketGrid or the TicketActionPanel in order to create 
    // a new ticket
    newTicket: function(){
        this.child('#center').child('#ticketForm').newTicket();
        this.child('#center').child('#ticketCustomerPanel').newTicket();
        this.child('#center').child('#ticketContactPanel').newTicket();
        this.child('#east').child('#auditGrid').newTicket();
        this.child('#east').child('#ticketFormRight').newTicket();
        this.child('#east').child('#fileStorageGrid').newTicket();
    },

    // Called from the TicketGrid if the user has selected a ticket
    loadTicket: function(rec){
        this.child('#center').child('#ticketForm').loadTicket(rec);
        this.child('#center').child('#ticketContactPanel').loadTicket(rec);
        this.child('#center').child('#ticketCustomerPanel').loadTicket(rec);
        this.child('#east').child('#auditGrid').loadTicket(rec);
        this.child('#east').child('#ticketFormRight').loadTicket(rec);
        this.child('#east').child('#fileStorageGrid').loadTicket(rec);
        //Inicialize dirty. There is no changes after load.
				var ticketModel = ticketStore.findRecord('ticket_id',rec.get('ticket_id'));
				ticketModel.dirty = false;        
    },
    
		//If the field value is diferent from store value, set model dirty variable to true
		checkTicketField: function(field,newValue,oldValue,store) { 
			if (field.xtype != 'po_datetimefield_read_only'){ //Exclude date read only
				var ticket_id_field = Ext.getCmp('ticketForm').getForm().findField('ticket_id');
				var ticket_id = ticket_id_field.getValue();
				var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);
				
				if (ticketModel != null && ticketModel != undefined) {
					var ticketModelFieldValue =  ticketModel.get(field.name);
					if (ticketModelFieldValue != null && ticketModelFieldValue != undefined && newValue != ticketModelFieldValue) {						
						ticketModel.setDirty();
					}
				}
			}
		}    

});



/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
<<<<<<< HEAD
 * @cvs-id $Id: TicketCompoundPanel.js.adp,v 1.12 2011/06/14 14:43:34 po34demo Exp $
=======
 * @cvs-id $Id: TicketCompoundPanel.js.adp,v 1.7 2011/06/10 14:24:05 po34demo Exp $
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
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
<<<<<<< HEAD
	itemId:		'center',
	region: 	'center',
	layout: 	'anchor',
	minWidth:	400,
=======
	itemId:	'center',
	region: 'center',
	layout: 'anchor',
	width:	500,
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b

	items: [{
		itemId: 'ticketForm',
		xtype: 'ticketForm',
		title: '#intranet-core.Ticket#'
	}, {
		itemId: 'ticketCustomer',
		title: '#intranet-sencha-ticket-tracker.Company#',
		xtype: 'ticketCustomer'
	}, {
		itemId: 'ticketContact',
		title: '#intranet-core.Contact#',
		xtype: 'ticketContactPanel'
	}, {
		itemId: 'ticketFilestorage',
		title: '#intranet-filestorage.Filestorage#',
		xtype: 'fileStorageGrid'
	}]
    }, {
	itemId:	'east',
	region: 'east',
	layout:	'anchor',
	width:	800,
<<<<<<< HEAD
	items: [{
		itemId: 'auditGrid',
		title: '',
		xtype: 'auditGrid'
	}, {
=======

	items: [{
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
		itemId: 'ticketFormRight',
		title: '',
		xtype: 'ticketFormRight'
	}]
<<<<<<< HEAD
    }],

    // Create a copy of the currrent ticket
    onCopyTicket: function() {
	var ticketForm = this.child('#center').child('#ticketForm');
	var ticket_id_field = ticketForm.getForm().findField('ticket_id');
	var old_ticket_id = ticket_id_field.getValue();
	ticket_id_field.setValue('');

	// Create a new ticket name
	ticketForm.setNewTicketName();

	// Write out an alert message
	alert('#intranet-sencha-ticket-tracker.A_new_ticket_has_been_created#')
    },
=======

    }],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b

    // Called from the TicketGrid if the user has selected a ticket
    newTicket: function(rec){
        this.child('#center').child('#ticketForm').newTicket(rec);
        this.child('#center').child('#ticketContact').newTicket(rec);
        this.child('#center').child('#ticketCustomer').newTicket(rec);
        this.child('#center').child('#ticketFilestorage').newTicket(rec);
<<<<<<< HEAD
        this.child('#east').child('#auditGrid').newTicket(rec);
=======
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
        this.child('#east').child('#ticketFormRight').newTicket(rec);
    },

    // Called from the TicketGrid if the user has selected a ticket
    loadTicket: function(rec){
        this.child('#center').child('#ticketForm').loadTicket(rec);
        this.child('#center').child('#ticketContact').loadTicket(rec);
        this.child('#center').child('#ticketCustomer').loadTicket(rec);
        this.child('#center').child('#ticketFilestorage').loadTicket(rec);
<<<<<<< HEAD
        this.child('#east').child('#auditGrid').loadTicket(rec);
=======
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
        this.child('#east').child('#ticketFormRight').loadTicket(rec);
    }

});



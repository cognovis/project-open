/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
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
	layout: 	'anchor',
	minWidth:	400,

	items: [{
		itemId: 'ticketForm',
		xtype: 'ticketForm',
		title: '#intranet-core.Ticket#'
	}, {
		itemId: 'ticketCustomerPanel',
		title: '#intranet-sencha-ticket-tracker.Company#',
		xtype: 'ticketCustomerPanel'
	}, {
		itemId: 'ticketContactPanel',
		title: '#intranet-core.Contact#',
		xtype: 'ticketContactPanel'
	}]
    }, {
	itemId:	'east',
	region: 'east',
	layout:	'anchor',
	width:	800,
	items: [{
		itemId: 'auditGrid',
		title: '',
		xtype: 'auditGrid'
	}, {
		itemId: 'ticketFormRight',
		title: '',
		xtype: 'ticketFormRight'
	}, {
		itemId: 'fileStorageGrid',
		title: '#intranet-filestorage.Filestorage#',
		xtype: 'fileStorageGrid'
	}]
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

    // Called from the TicketGrid if the user has selected a ticket
    newTicket: function(rec){
        this.child('#center').child('#ticketForm').newTicket(rec);
        this.child('#center').child('#ticketCustomerPanel').newTicket(rec);
        this.child('#center').child('#ticketContactPanel').newTicket(rec);
        this.child('#east').child('#auditGrid').newTicket(rec);
        this.child('#east').child('#ticketFormRight').newTicket(rec);
        this.child('#east').child('#fileStorageGrid').newTicket(rec);
    },

    // Called from the TicketGrid if the user has selected a ticket
    loadTicket: function(rec){
        this.child('#center').child('#ticketForm').loadTicket(rec);
        this.child('#center').child('#ticketContactPanel').loadTicket(rec);
        this.child('#center').child('#ticketCustomerPanel').loadTicket(rec);
        this.child('#east').child('#auditGrid').loadTicket(rec);
        this.child('#east').child('#ticketFormRight').loadTicket(rec);
        this.child('#east').child('#fileStorageGrid').loadTicket(rec);
    }

});



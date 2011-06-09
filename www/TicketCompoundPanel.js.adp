/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketCompoundPanel.js.adp,v 1.3 2011/06/09 17:04:29 mcordova Exp $
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
    extend:	'Ext.container.Container',
    alias:	'widget.ticketCompoundPanel',
    // No id: This is not a singleton object
    id:		'ticketCompoundPanel',
    title:  'Loading...',
    layout: 'border',
    deferredRender: false,

    items: [{
	itemId:	'center',
	region: 'center',
	layout: 'anchor',
	items: [{
		itemId: 'ticketForm',
		xtype: 'ticketForm',
		title: '#intranet-core.Ticket#'
	}, {
		itemId: 'ticketCustomer',
		title: '#intranet-core.Customer#',
		xtype: 'ticketCustomer'
	}, {
		itemId: 'ticketContact',
		title: '#intranet-core.Contact#',
		xtype: 'ticketContactPanel'
	}]
    }, {
	itemId:	'east',
	region: 'east',
	layout:	'anchor',
	items: [{
		itemId: 'ticketFilestorage',
		title: '#intranet-filestorage.Filestorage#',
		xtype: 'fileStorageGrid'
	}]

    }],

    // Called from the TicketGrid if the user has selected a ticket
    loadTicket: function(rec){
        this.child('#center').child('#ticketForm').loadTicket(rec);
        this.child('#center').child('#ticketContact').loadTicket(rec);
        this.child('#center').child('#ticketCustomer').loadTicket(rec);
        this.child('#east').child('#ticketFilestorage').loadTicket(rec);
    }

});



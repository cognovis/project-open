b/**
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


Ext.define('TicketBrowser.TicketTabPanel', {
    extend:	'Ext.tab.Panel',
    alias:	'widget.ticketTabPanel',
    id:		'ticketTabPanel',
    activeTab: 	0,
    tabBar:	{ border: true },
    deferredRender: false,
    items: [{
	itemId: 'ticket',
	xtype: 'ticketForm',
	title: '#intranet-sencha-ticket-tracker.View_Ticket#'
    }, {
	itemId: 'ticketCustomer',
	title: '#intranet-sencha-ticket-tracker.Customer#',
	xtype: 'ticketCustomer'
    }, {
	itemId: 'ticketContact',
	title: '#intranet-sencha-ticket-tracker.Contact#',
	xtype: 'ticketContactPanel'
    }, {
	itemId: 'ticketFilestorage',
	title: '#intranet-sencha-ticket-tracker.Filestorage#',
	xtype: 'fileStorageGrid'
    }],

    // Called from the TicketGrid if the user has selected a ticket
    loadTicket: function(rec){
        this.child('#ticket').loadTicket(rec);
        this.child('#ticketContact').loadTicket(rec);
        this.child('#ticketCustomer').loadTicket(rec);
        this.child('#ticketFilestorage').loadTicket(rec);
    }

});



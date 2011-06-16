/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketContactPanel.js.adp,v 1.17 2011/06/15 15:18:44 po34demo Exp $
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


Ext.define('TicketBrowser.TicketContactPanel', {
	extend:		'Ext.panel.Panel',
        alias:		'widget.ticketContactPanel',
        id:		'ticketContactPanel',
	title:		'#intranet-core.Contact#',
	layout:		'anchor',
	deferredRender:	false,
	items: [{
		title:	'#intranet-sencha-ticket-tracker.Contacts#',
		itemId:	'objectMemberGrid',
		xtype:	'objectMemberGrid',
		preventHeader: true
	}, {
		title:	'#intranet-sencha-ticket-tracker.Contacts#',
		itemId:	'ticketContactForm',
		xtype:	'ticketContactForm',
		preventHeader: true
	}],

    // Called from the TicketGrid if the user has selected a ticket
    newTicket: function(rec){
        this.child('#objectMemberGrid').newTicket(rec);
        this.child('#ticketContactForm').newTicket(rec);
    },

    // Called from the TicketGrid if the user has selected a ticket
    loadTicket: function(rec){
        this.child('#objectMemberGrid').loadTicket(rec);
        this.child('#ticketContactForm').loadTicket(rec);
    }

});


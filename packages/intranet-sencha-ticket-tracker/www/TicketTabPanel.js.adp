/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketTabPanel.js.adp,v 1.3 2011/06/03 10:51:32 mcordova Exp $
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
    extend: 'Ext.tab.Panel',
    alias: 'widget.ticketTabPanel',
    activeTab: 0,
    tabBar: {
	border: true
    },
    items: [{
	itemId: 'ticket',
	xtype: 'ticketInfo',
	title: 'View Ticket'
    }, {
	itemId: 'ticketFilestorage',
	title: '#intranet-filestorage.Filestorage#',
	xtype: 'fileStorageGrid'
    }]   
});
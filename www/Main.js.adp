/**
 * intranet-sencha-ticket-tracker/www/Main.js
 * Main container for the ]po[ Sencha Ticket Browser.
 * The TabPanel container contains a separate tab for every
 * type of business object included.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: Main.js.adp,v 1.6 2011/06/09 10:57:09 po34demo Exp $
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

Ext.define('TicketBrowser.Main', {
	extend: 'Ext.container.Viewport',

	// We need an "outer" container here, because we can't have
	// a viewport with tabs apparently.
	layout: 'border',
	itemId: 'main',
	items: [{
		// Outermost Tab container
		// Here we can add tabs for the various object types.
		region:		'center',
		xtype:		'tabpanel',
		margins:	'5 0 5 5',
		border:		false,
		tabBar:		{ border: true },
		items: [{
			itemId: 'ticket',
			title: '#intranet-helpdesk.Tickets#',
			xtype: 'ticketcontainer'
		}, {
			itemId: 'company',
			title: 	'#intranet-core.Companies#',
			xtype: 'companycontainer'
		}, {
			itemId: 'contact',
			title: '#intranet-core.Contact#',
			xtype: 'contactcontainer'
		}]
	}]
});


/**
 * intranet-sencha-ticket-tracker/www/Main.js
 * Main container for the ]po[ Sencha Ticket Browser.
 * The TabPanel container contains a separate tab for every
 * type of business object included.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: MainPanel.js.adp,v 1.4 2011/06/10 09:50:41 po34demo Exp $
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
	extend:		'Ext.container.Viewport',
	layout:		'border',
	id:		'mainPanel',
	itemId:		'mainPanel',
	title:		'Loading ...',

	// We need an "outer" container here, because we can't have
	// a viewport with tabs apparently.
	items: [{
		// Outermost Tab container
		// Here we can add tabs for the various object types.
		id:		'mainTabPanel',
		region:		'center',
		xtype:		'tabpanel',
		margins:	'5 0 5 5',
		border:		false,
		tabBar:		{ border: true },
		items: [{
			itemId: 'ticket',
			title: '#intranet-helpdesk.Tickets#',
			xtype: 'ticketContainer'
		}, {
			itemId: 'company',
			title: 	'#intranet-sencha-ticket-tracker.Companies#',
			xtype: 'companyContainer'
		}, {
			itemId: 'contact',
			title: '#intranet-sencha-ticket-tracker.Contacts#',
			xtype: 'contactContainer'
		}, {
			itemId: 'sample',
			title: 'Sample',
			xtype: 'ticketCompoundPanel'
		}]
	}]
});



/**
 * intranet-sencha-company-tracker/www/CompanyContainer.js
 * Container for both CompanyGrid and CompanyForm.
 *
 * @author David Blanco (david.blanco@grupoversia.com)
 * @creation-date 2011-08
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

Ext.define('TicketBrowser.ContactPanel', {
	extend: 'Ext.panel.Panel',
	alias: 'widget.contactPanel',
	layout: 'border',

	items: [{
		itemID:	'contactFilter',
		xtype:	'contactFilterForm',
		region:	'west',
		width:	300,
		title:	'#intranet-sencha-ticket-tracker.Filter_Contacts#',
		split:	true,
		margins: '5 0 5 5'
	}, {
		itemId:	'contactPanel2',
		title:	'#intranet-sencha-ticket-tracker.Contacts#',
		region:	'center',
		split:	true,
		items:	[{
			itemId:	'contactGrid',
			xtype:	'contactGrid'
		}]
	}]
});


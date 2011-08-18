/**
 * intranet-sencha-ticket-tracker/www/CompanyCompoundPanel.js
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


var companyCompoundPanel = Ext.define('TicketBrowser.CompanyCompoundPanel', {
	extend:		'Ext.container.Container',
	alias:		'widget.companyCompoundPanel',
	id:		'companyCompoundPanel',
	title:		'Loading...',
	layout:		'border',
	deferredRender:	false,
	minHeight:	200,
	split:		true,
	autoScroll:	true,
	items: [{
		itemId: 'companyForm',
		xtype: 'companyForm',
		title: '#intranet-sencha-ticket-tracker.Company#',
		split:	true,
	}],
});



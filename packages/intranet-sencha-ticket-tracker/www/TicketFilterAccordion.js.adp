/**
 * intranet-sencha-ticket-tracker/www/Main.js
 * Main page for the ]po[ Sencha Ticket Browser.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketFilterAccordion.js.adp,v 1.1 2011/06/03 08:38:00 po34demo Exp $
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


var item2 = Ext.create('Ext.Panel', {
	title: 'Accordion Item 2',
	html: '&lt;empty panel&gt;',
	cls:'empty'
});

Ext.define('TicketBrowser.TicketFilterAccordion', {
	extend: 'Ext.Panel',
	alias: 'widget.ticketfilteraccordion',
	split:true,
	minWidth: 200,
	layout:'accordion',
	items: [ticketFilterForm, slaList, item2]
});
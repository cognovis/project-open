/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketContainer.js.adp,v 1.12 2011/07/18 15:59:24 po34demo Exp $
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


var ticketContainer = Ext.define('TicketBrowser.TicketContainer', {
	extend:	'Ext.container.Container',
	alias:	'widget.ticketContainer',
	id:	'ticketContainer',
	title:	'#intranet-sencha-ticket-tracker.Loading___#',
	layout:	'border',
	deferredRender: false,

	items:	[{
		itemID:	'ticketFilter',
		xtype:	'ticketFilterForm',
		region:	'west',
		width:	300,
		title:	'#intranet-helpdesk.Filter_Tickets#',
		split:	true,
		margins: '5 0 5 5'
	}, {
		itemId:	'main2',
		title:	'#intranet-sencha-ticket-tracker.Tickets#',
		region:	'center',
		layout:	'border',
		split:	true,
		items:	[{
			itemId:	'ticketGrid',
			xtype:	'ticketGrid',
			region:	'center'
		}]
	}],
	
	initComponent: function(){
		this.callParent();
	},

	afterLayout: function() {
		this.callParent();
		// IE6 likes to make the content disappear, hack around it...
		if (Ext.isIE6) { this.el.repaint(); }
	},
	
	loadSla: function(rec) {
		this.tab.setText(rec.get('project_name'));
		this.child('#ticketGrid').loadSla(rec.getId());
	},
	
	filterTickets: function(filterValues) {
		this.tab.setText('Filtered Tickets');
		this.child('#ticketGrid').filterTickets(filterValues);
	},
	
	togglePreview: function(show){
		var preview = this.child('#preview');
		if (show) {
			preview.show();
		} else {
			preview.hide();
		}
	},

	// Inform the TicketInfo Panel to clear values for 
	// entering a new ticket
	onNew: function(){
		var preview = this.child('#preview');
		var infoPanel = preview.child('#ticket');
		infoPanel.onNew();
	},

	toggleGrid: function(show){
		var grid = this.child('#ticketGrid');
		if (show) {
			grid.show();
		} else {
			grid.hide();
		}
	}
});
/**
 * intranet-sencha-ticket-tracker/www/TicketActionBar.js
 * New, Copy and Delete buttons for all tabs
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

Ext.define('TicketBrowser.TicketActionBar', {
	extend:		'Ext.toolbar.Toolbar',
	alias:		'widget.ticketActionBar',
	id:		'ticketActionBar',
	width:		500,
	cls:		'x-docked-noborder-top',

	items: [{
		text:		'#intranet-helpdesk.New_Ticket#',
		iconCls:	'icon-new-ticket',
		handler: function(btn, pressed) {
			// Distribute the event to the selected panel
			var mainTabPanel = Ext.getCmp('mainTabPanel');
			var xtype = mainTabPanel.getActiveTab().xtype;
			switch (xtype) {
				case 'companyContainer':
					// List page for companies - copy the selected company
					Ext.getCmp('companyGrid').onNew(btn, pressed);
					break;
				case 'contactContainer':
					// List page for contacts - copy the selected contact
					Ext.getCmp('contactGrid').onNew(btn, pressed);
					break;
				case 'ticketContainer':
				case 'ticketCompoundPanel':
					// Ticket list or view page
					var ticketCompoundPanel = Ext.getCmp('ticketCompoundPanel');
					ticketCompoundPanel.tab.setText('#intranet-helpdesk.New_Ticket#');
					var mainTabPanel = Ext.getCmp('mainTabPanel');
					mainTabPanel.setActiveTab(ticketCompoundPanel);
					ticketCompoundPanel.newTicket();
					break;
				default:
					alert('Tab not recognized for new operation: ' + xtype);
				break
			}
		}
	}, {
		text:		'#intranet-sencha-ticket-tracker.Copy_Ticket#',
		iconCls:	'icon-new-ticket',
		handler: function(btn, pressed){
			// Distribute the event to the selected panel
			var mainTabPanel = Ext.getCmp('mainTabPanel');
			var xtype = mainTabPanel.getActiveTab().xtype;
			switch (xtype) {
				case 'companyContainer':
					Ext.getCmp('companyGrid').onCopy(btn, pressed);
					break;
				case 'contactContainer':
					Ext.getCmp('contactGrid').onCopy(btn, pressed);
					break;
				case 'ticketContainer':
					Ext.getCmp('ticketGrid').onCopy(btn, pressed);
					break;
				case 'ticketCompoundPanel':
					Ext.getCmp('ticketCompoundPanel').onCopy(btn, pressed);
					break;
				default:
					alert('Tab not recognized for copy operation: ' + xtype);
				break
			}
		}
	}, {
		text:		'#intranet-helpdesk.Remove_checked_items#',
		iconCls:	'icon-new-ticket',
		handler:	function(btn, pressed){
			// Distribute the event to the selected tab
			var mainTabPanel = Ext.getCmp('mainTabPanel');
			var xtype = mainTabPanel.getActiveTab().xtype;
			switch (xtype) {
				case 'companyContainer':
					Ext.getCmp('companyGrid').onDelete(btn, pressed);
					break;
				case 'contactContainer':
					Ext.getCmp('contactGrid').onDelete(btn, pressed);
					break;
				case 'ticketContainer':
					Ext.getCmp('ticketGrid').onDelete(btn, pressed);
					break;
				case 'ticketCompoundPanel':
					Ext.getCmp('ticketCompoundPanel').onDelete(btn, pressed);
					break;
				default:
					alert('Tab not recognized for delete operation: ' + xtype);
				break
			}
		}
	}, '-', {
		text:		'#intranet-core.Summary#',
		iconCls:	'icon-summary',
		enableToggle:	true,
		pressed:	true,
		scope:		this,
		toggleHandler: function(btn, pressed){
			// Show/hide summary in ticketGrid
			var grid = Ext.getCmp('ticketGrid');
			grid.onSummaryChange(btn, pressed);
		}
	}]
});

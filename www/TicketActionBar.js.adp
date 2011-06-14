/**
 * intranet-sencha-ticket-tracker/www/TicketGrid.js
 * Grid table for ]po[ tickets
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
	    text: '#intranet-helpdesk.New_Ticket#',
	    iconCls: 'icon-new-ticket',
	    handler: function() {
		var compoundPanel = Ext.getCmp('ticketCompoundPanel');
	        compoundPanel.tab.setText('#intranet-helpdesk.New_Ticket#');
		var mainTabPanel = Ext.getCmp('mainTabPanel');
		mainTabPanel.setActiveTab(compoundPanel);	
		compoundPanel.newTicket();
	    }
	}, {
	    text: '#intranet-sencha-ticket-tracker.Copy_Ticket#',
	    iconCls: 'icon-new-ticket',
	    handler: function(){
		var mainTabPanel = Ext.getCmp('mainTabPanel');
		var xtype = mainTabPanel.getActiveTab().xtype;
		switch (xtype) {
			// Ticket Container selected - search for selected ticket in Ticket Grid
			case 'companyContainer':
			case 'contactContainer':
				// Ignore the action when working with contacts and companies
			break;
			case 'ticketContainer':
				alert('Copy ticket from grid not implemented yet');
			break;
			case 'ticketCompoundPanel':
				var compoundPanel = Ext.getCmp('ticketCompoundPanel');
				compoundPanel.onCopyTicket();
			break;
			default:
				alert('Tab not recognized for copying tickets: ' + xtype);
			break
		}
	    }
/*
	}, {
	    text: '#intranet-helpdesk.Remove_checked_items#',
	    iconCls: 'icon-new-ticket',
	    handler: function(){
		    alert('Not implemented');
   	    }
*/
	}, '-', {
	    text: '#intranet-core.Summary#',
	    iconCls: 'icon-summary',
	    enableToggle: true,
	    pressed: true,
	    scope: this,
	    toggleHandler: function(btn, pressed){
		// Show/hide summary in ticketGrid
		var grid = Ext.getCmp('ticketGrid');
		grid.onSummaryChange(btn, pressed);
	    }
	}]
});

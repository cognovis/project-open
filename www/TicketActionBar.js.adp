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
		text:		'#intranet-sencha-ticket-tracker.New#',
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
					ticketCompoundPanel.tab.setText('#intranet-sencha-ticket-tracker.New_Ticket#');
					var mainTabPanel = Ext.getCmp('mainTabPanel');
					mainTabPanel.setActiveTab(ticketCompoundPanel);
					ticketCompoundPanel.newTicket();
					ticketCompoundPanel.tab.show();
					break;
				default:
					alert('Tab not recognized for new operation: ' + xtype);
				break
			}
		}
	}, {
		id: 'buttonCopyTicket',
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
		id: 'buttonRemoveSelected',
		text:		'#intranet-sencha-ticket-tracker.Remove_checked_items#',
		iconCls:	'icon-new-ticket',
		handler:	function(btn, pressed){
			//Confimation message
			 Ext.Msg.show({
		     	title:'#intranet-sencha-ticket-tracker.Delete_tittle#',
		     	msg:	'#intranet-sencha-ticket-tracker.Delete_message#',		     	
		    	buttons: Ext.Msg.YESNO,
		    	icon: Ext.MessageBox.QUESTION,
		     fn: function(btn){
		     		if (btn == 'yes'){
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
		     }
			});								
		}
	}, '-', {
		id: 'buttonSummaryTicket',
		text:		'#intranet-sencha-ticket-tracker.Summary#',
		iconCls:	'icon-summary',
		enableToggle:	true,
		pressed:	true,
		scope:		this,
		toggleHandler: function(btn, pressed){
			// Show/hide summary in ticketGrid
			var grid = Ext.getCmp('ticketGrid');
			grid.onSummaryChange(btn, pressed);
		}
	}, {
		xtype : 'tbspacer',
		width: 20
	}, {
		xtype: 'progressbar',
		id: 'progressBar',
		text: '#intranet-sencha-ticket-tracker.Loading___#',
		width: 400,
		listeners: {
			afterrender: function(component,options){
				Ext.getCmp('ticketActionBar').startBar();
			}
		}
	}, {
		xtype : 'tbspacer',
		width: 20
	}, '-', {
		xtype : 'tbspacer',
		width: 20
	}, {
		id: 'buttonLogout',
		text:		'#intranet-sencha-ticket-tracker.Logout#',
		//iconCls:	'icon-new-ticket',
		handler:	function(btn, pressed){		
			//Confirmation message
			Ext.Msg.show({
				title:'#intranet-sencha-ticket-tracker.Logout_tittle#',
		     	msg:	'#intranet-sencha-ticket-tracker.Logout_message#',
		    	buttons: Ext.Msg.YESNO,
		    	icon: Ext.MessageBox.QUESTION,
		     	fn: function(btn){
		     		if (btn == 'yes'){
		     			location.href='../register/logout';
		     		}
		     	}
		    });			
		}
	}],
	
	// Disable, enable,hide or show a button 
	// variable 'disabled' can be the data selection in a grid. If no data, the button will be disabled.
	// Variable 'hide' is optional.
	checkButton: function (button_id,disabled,hide){
		if (disabled.length == 0) {
			disabled = true;
		} if (disabled != true) {
			disabled =false;
		}
		
		var but = this.getComponent(button_id);
		but.setDisabled(disabled);	
		if (hide) {
			but.hide();
		} else {
			but.show();
		}
	},
	
	startBar: function (){
		var progressbar = this.getComponent('progressBar');
	   	progressbar.wait({
	       increment: 60,
	       text: '#intranet-sencha-ticket-tracker.Loading___#',
	       scope: this,
	    });
	},
	
	stopBar: function (){
		var progressbar = this.getComponent('progressBar');
	   	progressbar.reset();
	   	progressbar.updateText('#intranet-sencha-ticket-tracker.Finish_Load#');
	}
		
});

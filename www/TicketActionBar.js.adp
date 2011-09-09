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
				case 'companyContactContainer':
				case 'companyContactCompoundPanel':
					var companyContactCompoundPanel = Ext.getCmp('companyContactCompoundPanel');
					companyContactCompoundPanel.tab.setText('#intranet-sencha-ticket-tracker.New_Customer#');
					var mainTabPanel = Ext.getCmp('mainTabPanel');					
					mainTabPanel.setActiveTab(companyContactCompoundPanel);
					companyContactCompoundPanel.newCompany();
					companyContactCompoundPanel.tab.show();
					break;
				default:
					alert('Pestaña no reconocida para la operación: ' + xtype);
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
					alert('Pestaña no reconocida para la operación: ' + xtype);
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
							case 'companyContactContainer':
								var companyGrid = Ext.getCmp('companyGrid');
								if (companyGrid.getSelectionModel().getSelection().length > 0){
									companyGrid.onDelete();
								}
								var contactGrid =  Ext.getCmp('contactGrid');
								if (contactGrid.getSelectionModel().getSelection().length > 0){
									contactGrid.onDelete();
								}								
								break;								
							default:
								alert('Pestaña no reconocida para la operación: ' + xtype);
							break
						}
		     		}
		     	}
			});								
		}
	}, {id: 'buttonSummaryTicketSeparator', xtype: 'tbseparator'}, {
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
	}, {id: 'buttonSaveSeparator', xtype: 'tbseparator'},  {
		xtype : 'tbspacer',
		width: 20
	}, {
		id: 'buttonReject',
		text: '#intranet-sencha-ticket-tracker.Reject_Button#',
		iconCls:	'icon-reject',
		handler: function(btn, pressed) {
			Ext.getCmp('ticketFormRight').getForm();
			// Get the field information
			var form = Ext.getCmp('ticketFormRight').getForm();
			var ticket_queue_field = form.findField('ticket_queue_id');
			var ticket_last_queue_field = form.findField('ticket_last_queue_id');
			var ticket_last_queue_id = ticket_last_queue_field.getValue();

			// Check that the store contains the value for rejection
			var lastQueueRecord = programGroupStore.findRecord('group_id', ticket_last_queue_id);
			if (null == lastQueueRecord || undefined == lastQueueRecord) {
				// We need to add the group to the store
                var profileModel = profileStore.findRecord('group_id', ticket_last_queue_id);
				programGroupStore.insert(0, profileModel);
			}
			ticket_queue_field.setValue(ticket_last_queue_id);			
		}
	}, {
		id: 'buttonSave',
		text:		'#intranet-sencha-ticket-tracker.button_Save#',
		iconCls:	'icon-save',
		handler: function(btn, pressed) {
			// Distribute the event to the selected panel
			var mainTabPanel = Ext.getCmp('mainTabPanel');
			var xtype = mainTabPanel.getActiveTab().xtype;
			switch (xtype) {
				case 'ticketCompoundPanel':
					var companyValues = Ext.getCmp('ticketCustomerPanel').getValues();
					var contactValues =  Ext.getCmp('ticketContactForm').getValues();
					var ticketValues =  Ext.getCmp('ticketForm').getValues();
					var ticketRightValues =  Ext.getCmp('ticketFormRight').getValues();
					
					if (Function_validateTicket()){
						Function_save(companyValues, contactValues, ticketValues, ticketRightValues, false, true);
					}
					break;
				case 'companyContactCompoundPanel':
					var companyValues = Ext.getCmp('companyContactCustomerPanel').getValues();
					var contactValues =  Ext.getCmp('companyContactContactForm').getValues();
						
					if (Function_validateCompanyContact()){
						Function_save(companyValues, contactValues, false, false, true, false);	
					}
										
					break;
				default:
					alert('Pestaña no reconocida para la operación: ' + xtype);
				break
			}
		}		
	}, {xtype: 'tbseparator'},  {
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
	}, {xtype: 'tbseparator'}, {
		xtype : 'tbspacer',
		width: 20
	}, {
		id: 'buttonLogout',
		text:		'#intranet-sencha-ticket-tracker.Logout#',
		iconCls:	'icon-logout',
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
		var sep = this.getComponent(button_id + 'Separator'); //Separator
		but.setDisabled(disabled);	
		if (!Ext.isEmpty(hide)){
			if (hide) {
				but.hide();
			} else {
				but.show();
			}
		}
		if (!Ext.isEmpty(sep)){
			if (hide) {
				sep.hide();
			} else {
				sep.show();
			}			
		}		
	},
	
	startBar: function (){
		var progressbar = this.getComponent('progressBar');
	   	progressbar.wait({
	       increment: 60,
	       text: '#intranet-sencha-ticket-tracker.Loading___#',
	       scope: this
	    });
	},
	
	stopBar: function (){
		var progressbar = this.getComponent('progressBar');
	   	progressbar.reset();
	   	progressbar.updateText('#intranet-sencha-ticket-tracker.Finish_Load#');
	},
		
	checkButtons: function (rec){
		var rejectButton = Ext.getCmp('ticketActionBar').getComponent('buttonReject');
		var buttonSave = Ext.getCmp('ticketActionBar').getComponent('buttonSave');
		
		rejectButton.show();
		buttonSave.show();		
		if (Ext.isEmpty(rec)){
			rejectButton.disable();
			buttonSave.enable();				
		} else {
			//If the Ticket is close, hide the buttons
			var ticket_status_id = rec.get('ticket_status_id');
			var ticket_last_queue_field = rec.get('ticket_last_queue_id');
		
			if (ticket_status_id == '30001' && currentUserIsAdmin != 1){
				rejectButton.disable();
				buttonSave.disable();
			} else {
				buttonSave.enable();
				// Enable the "Reject" button if last_queue_id exists
				if (Ext.isEmpty(ticket_last_queue_field)){
					rejectButton.disable();
				} else {
					rejectButton.enable();
				}
			}		
		}
	}		
	
});

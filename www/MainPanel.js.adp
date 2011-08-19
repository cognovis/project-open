/**
 * intranet-sencha-ticket-tracker/www/Main.js
 * Main container for the ]po[ Sencha Ticket Browser.
 * The TabPanel container contains a separate tab for every
 * type of business object included.
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

		dockedItems: [{
			dock: 'top',
			xtype: 'ticketActionBar'
		}],
	
		items: [{
			itemId: 'ticket',
			title: '#intranet-sencha-ticket-tracker.Tickets#',
			xtype: 'ticketContainer',
			listeners: {
				activate:  function(){
					Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',Ext.getCmp('ticketGrid').selModel.getSelection());     
					Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',Ext.getCmp('ticketGrid').selModel.getSelection()); 			
					Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,false);
					Ext.getCmp('ticketActionBar').checkButton('buttonSave',true,true);
					Ext.getCmp('ticketActionBar').checkButton('buttonReject',true,true);
					Ext.getCmp('ticketFilterForm').onSearch()
				}
			}				
		}, {
			itemId: 'companyContactContainer',
			title: '#intranet-sencha-ticket-tracker.CompanyContact#',
			xtype:  'companyContactContainer',
			listeners: {
	      		activate:  function(){
					Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',true);
	  				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',Ext.getCmp('contactGrid').selModel.getSelection());
	  				Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,true); 
	  				Ext.getCmp('ticketActionBar').checkButton('buttonSave',true,true);  
	  				Ext.getCmp('ticketActionBar').checkButton('buttonReject',true,true);   				
	      		}
      		}			
		}/*,{
			itemId: 'company',
			title: 	'#intranet-sencha-ticket-tracker.Companies#',
			xtype: 'companyContainer',
      		listeners: {
      		activate:  function(){
					Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',true);
      				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',Ext.getCmp('companyGrid').selModel.getSelection());
      				Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,true);      				
      		}
      }							
		}, {
			itemId: 'contact',
			title: '#intranet-sencha-ticket-tracker.Contacts#',
			xtype: 'contactContainer',
      		listeners: {
      		activate:  function(){
							Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',true);
      				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',Ext.getCmp('contactGrid').selModel.getSelection());
      				Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,true);      				
      		}
      }				
		}*/, {
			itemId: 'TEC',
			title: '#intranet-sencha-ticket-tracker.Tickets#',
			xtype: 'ticketCompoundPanel',
			hidden: true,
			listeners: {
				activate:  function(){
						Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',false);
						Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',false);
						Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,true);
						Ext.getCmp('ticketActionBar').checkButton('buttonSave',true,true);
				},
				deactivate: function(){
					// Show a dialog to save changes in ticket
					var ticket_id_field = Ext.getCmp('ticketForm').getForm().findField('ticket_id');
					var ticket_id = ticket_id_field.getValue();
					var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);			
					//There is a ticked that is not closed and dirty			
					if (ticketModel != undefined && ticketModel.get('ticket_status_id') != '30001' && ticketModel.dirty) {
						Ext.Msg.show({
					     	title:'#intranet-sencha-ticket-tracker.Save_changes_tittle#',
					     	msg:	'#intranet-sencha-ticket-tracker.Save_changes_message#',
					    	buttons: Ext.Msg.OK,
					    	icon: Ext.MessageBox.WARNING,
						});
						ticketModel.dirty = false;
						/*Ext.Msg.show({
					     	title:'#intranet-sencha-ticket-tracker.Save_changes_tittle#',
					     	msg:	'#intranet-sencha-ticket-tracker.Save_changes_message#',
					    	buttons: Ext.Msg.YESNO,
					    	icon: Ext.MessageBox.QUESTION,
					     	fn: function(btn){
					     		var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);	
					     		ticketModel.dirty = false;
					     		if (btn == 'yes'){
					     			var ticketFormValues = Ext.getCmp('ticketForm').getForm().getFieldValues();
					     			var ticketFormRightValues = Ext.getCmp('ticketFormRight').getForm().getFieldValues();
					     			var ticketFormValues = Ext.getCmp('ticketForm').getForm().getFieldValues();
					     			var ticketFormValues = Ext.getCmp('ticketForm').getForm().getFieldValues();
									// Update an existing ticket
									// Loop through all form fields and store into the ticket store
									var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);
									for(var field in ticketFormValues) {
										if (ticketFormValues.hasOwnProperty(field)) {
											value = ticketFormValues[field];
											ticketModel.set(field, value);
										}
									}			
									for(var field in ticketFormRightValues) {
										if (ticketFormRightValues.hasOwnProperty(field)) {
											value = ticketFormRightValues[field];
											ticketModel.set(field, value);
										}
									}													     			
					     			
					     			
					     			
									ticketModel.save({
										scope: Ext.getCmp('ticketForm'),
										success: function(record, operation) {
											// Refresh all forms to show the updated information
											var compoundPanel = Ext.getCmp('ticketCompoundPanel');
											compoundPanel.tab.setText(record.get('project_name'));
											compoundPanel.loadTicket(ticketModel);
										},
										failure: function(record, operation) {
											Ext.Msg.alert('Failed to save ticket', operation.request.scope.reader.jsonData["message"]);
										}
									});										
					     		}
					     	}
						});*/
					}
			  	}
			}			
		}, {
			itemId: 'companyContactCompoundPanel',
			title: '#intranet-sencha-ticket-tracker.EditCompanyContact#',
			xtype: 'companyContactCompoundPanel',
			hidden: true,
			listeners: {
				activate:  function(){
						Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',true);
						Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',true);
						Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,true);
						Ext.getCmp('ticketActionBar').checkButton('buttonSave',false,false);
						Ext.getCmp('ticketActionBar').checkButton('buttonReject',true,true);
				},
				deactivate: function(){
					// Show a dialog to save changes in ticket
					var company_id_field = Ext.getCmp('companyContactCustomerPanel').getForm().findField('company_id');
					var company_id = company_id_field.getValue();
					var companyModel = companyStore.findRecord('company_id',company_id);			
					
					var contactNew = Ext.getCmp('companyContactContactForm').getForm().findField('checkNew').getValue(); 
					if (!contactNew) {			
						var contact_id_field = Ext.getCmp('companyContactContactForm').getForm().findField('user_id');
						var contact_id = contact_id_field.getValue();
						var contactModel = userCustomerStore.findRecord('user_id',contact_id);							
					}					
						
					if ((companyModel != undefined && companyModel.dirty) || (contactModel != undefined && contactModel.dirty)) {
						Ext.Msg.show({
					     	title:'#intranet-sencha-ticket-tracker.Save_changes_tittle#',
					     	msg:	'#intranet-sencha-ticket-tracker.Save_changes_message#',
					    	buttons: Ext.Msg.OK,
					    	icon: Ext.MessageBox.WARNING,
						});
						companyModel.dirty = false;
						contactModel.dirty = false;
					}		
			  	}				
			}		
		}, {
			itemId: 'report',
			title: '#intranet-sencha-ticket-tracker.Reports#'	
		}],
		
		listeners: {
			beforetabchange: function(tabPanel, newCard, oldCard, options){		
				if (newCard.itemId == 'report'){
					window.open('/intranet-reporting/');
					return false;
				} 
				return true;
			}
		}
	}]
});



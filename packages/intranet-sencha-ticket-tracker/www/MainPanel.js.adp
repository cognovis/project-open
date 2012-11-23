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
		}, {
			itemId: 'TEC',
			title: '#intranet-sencha-ticket-tracker.Tickets#',
			xtype: 'ticketCompoundPanel',
			hidden: true,
			listeners: {
				activate:  function(){
						Ext.getCmp('ticketActionBar').checkButton('buttonCopyTicket',false);
						Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',false);
						Ext.getCmp('ticketActionBar').checkButton('buttonSummaryTicket',false,true);
						Ext.getCmp('ticketActionBar').checkButton('buttonSave',false,false);
						//ToDo: si el ticket esta cerrado y no es admin desabilitar boton de salvar
						var date = new Date();
						Ext.getCmp('ticketForm').getForm().findField('datetime').setValue(date.getTime());
				},
				deactivate: function(){
					// Show a dialog to save changes in ticket
					var ticket_id_field = Ext.getCmp('ticketForm').getForm().findField('ticket_id');
					var ticket_id = ticket_id_field.getValue();
					var ticketModel = ticketStore.findRecord('ticket_id',ticket_id);			
					//There is a ticked that is not closed and dirty			
					if (Ext.isEmpty(ticketModel) || (ticketModel.get('ticket_status_id') != '30001' && ticketModel.dirty)) {
						if (!Ext.isEmpty(ticketModel)) {
							ticketModel.dirty = false;
						}
						Ext.Msg.show({
					     	title:'#intranet-sencha-ticket-tracker.Save_changes_tittle#',
					     	msg:	'#intranet-sencha-ticket-tracker.Save_changes_message#',
					    	buttons: Ext.Msg.YESNO,
					    	icon: Ext.MessageBox.QUESTION,
					     	fn: function(btn){
					     		if (btn == 'yes'){
									var companyValues = Ext.getCmp('ticketCustomerPanel').getValues();
									var contactValues =  Ext.getCmp('ticketContactForm').getValues();
									var ticketValues =  Ext.getCmp('ticketForm').getValues();
									var ticketRightValues =  Ext.getCmp('ticketFormRight').getValues();
									
									if (Function_validateTicket()){
										Function_save(companyValues, contactValues, ticketValues, ticketRightValues, false, true);
									}																														     			
					     		}
					     	}
						});
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
					
					var contact_id_field = Ext.getCmp('companyContactContactForm').getForm().findField('user_id');
					var contact_id = contact_id_field.getValue();
					if (!Ext.isEmpty(contact_id)) {			
						var contactModel = userCustomerContactStore.findRecord('user_id',contact_id);							
					}
						
					if (Ext.isEmpty(companyModel) || Ext.isEmpty(contactModel) || (companyModel.dirty) || (contactModel.dirty)) {
						Ext.Msg.show({
					     	title:'#intranet-sencha-ticket-tracker.Save_changes_tittle#',
					     	msg:	'#intranet-sencha-ticket-tracker.Save_changes_message#',
					    	buttons: Ext.Msg.YESNO,
					    	icon: Ext.MessageBox.QUESTION,
					     	fn: function(btn){
					     		if (btn == 'yes'){
									var companyValues = Ext.getCmp('companyContactCustomerPanel').getValues();
									var contactValues =  Ext.getCmp('companyContactContactForm').getValues();
										
									if (Function_validateCompanyContact()){
										Function_save(companyValues, contactValues, false, false, true, false);	
									}																														     			
					     		}
					     	}
						});
						if (!Ext.isEmpty(companyModel)) {
							companyModel.dirty = false;
						}
						if (!Ext.isEmpty(contactModel)) {
							contactModel.dirty = false;
						}
					}		
			  	}				
			}		
		}, {
			itemId: 'report',
			title: '#intranet-sencha-ticket-tracker.Reports#',
			hidden: !currentUserIsAdmin
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



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

		defaults: {
      listeners: {
      		activate:  function(){
      				Ext.getCmp('mainPanel').checkButton('mainTabPanel','ticketActionBar','buttonCopyTicket',true);
      		}
      }		
		},
		
		items: [{
			itemId: 'ticket',
			title: '#intranet-sencha-ticket-tracker.Tickets#',
			xtype: 'ticketContainer'	
		}, {
			itemId: 'company',
			title: 	'#intranet-sencha-ticket-tracker.Companies#',
			xtype: 'companyContainer'	
		}, {
			itemId: 'contact',
			title: '#intranet-sencha-ticket-tracker.Contacts#',
			xtype: 'contactContainer'
		}, {
			itemId: 'sample',
			title: '#intranet-sencha-ticket-tracker.Tickets#',
			xtype: 'ticketCompoundPanel',
      listeners: {
      		activate:  function(){
      				Ext.getCmp('mainPanel').checkButton('mainTabPanel','ticketActionBar','buttonCopyTicket',false);
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
						    //'You are closing a tab that has unsaved changes. Would you like to save your changes?',
						    // buttons: Ext.Msg.YESNO,
						     //icon: Ext.Msg.QUESTION,
						     buttons: Ext.Msg.OK,
						     icon: Ext.Msg.WARNING,
						     fn: function(btn){
						     		ticketModel.dirty = false;
						     		if (btn == 'yes'){
						     			//Save Ticket
											ticketModel.dirty = false;     			
						     		}
						     }
							});
						}
          }
      }			
		}]
	}],
	
	checkButton: function (component_id,docked_component_id,button_id,disabled){
		var bar = Ext.getCmp(component_id).getDockedComponent(docked_component_id);
		var but = bar.getComponent(button_id);
		but.setDisabled(disabled);		
	}
		
});



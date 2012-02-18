/**
 * intranet-sencha-ticket-tracker/www/TicketCompoundPanel.js
 * Container for both TicketGrid and TicketForm.
 *
 * @author David Blanco 
 * @creation-date 2011-07
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
 
Ext.define('TicketBrowser.TicketChangeContactWindow', {
	extend:		'Ext.window.Window',
 	id: 'ticketChangeContactWindow',
 	alias:		'widget.ticketChangeContactWindow',
    title: '#intranet-sencha-ticket-tracker.Delete_Contact#',
    height: 200,
    width: 500,
    layout: 'fit',
    items: [{
    	id: 'ticketChangeContactWindowForm',
    	alias:		'widget.ticketChangeContactWindowForm',
 		xtype: 'form',
 		bodyStyle:	'padding:5px 5px 0',
		fieldDefaults: {
			msgTarget: 'side',
			labelWidth: 150
		},
		defaultType:	'textfield', 			
      	items: [
          	{
          		id: 'contact_id',
          		name:		'contact_id',
              	xtype: 'combo',
              	forceSelection: true,
             	fieldLabel:	'#intranet-sencha-ticket-tracker.Contact_To_Delete#',
              	anchor: '100%',
				allowBlank:	false,
				store:		userCustomerStore,
				queryMode:	'local',
				valueField:	'user_id',
				displayField:   'name'													          
          	},
          	{
				id: 'contact_id_replacement',
				name:		'contact_id_replacement',
              	xtype: 'combo',
              	forceSelection: true,
              	fieldLabel:	'#intranet-sencha-ticket-tracker.Contact_To_Change#',
              	anchor: '100%',
				allowBlank:	false,
				store:		userCustomerStore,
				queryMode:	'local',
				valueField:	'user_id',
				displayField:   'name'						            
          	}
    ],    
	buttons: [	          
          	{
              	xtype: 'button',
              	text: '#intranet-sencha-ticket-tracker.Change#',
              	formBind:	true,
 				handler: function() {
					// Make sure the form is valid
					var form = this.up('form').getForm();
					var company_id = form.findField('contact_id');
					if(!form.isValid()) { return; }

					// Submit to the server side script
					form.submit({
						url:	'contact-delete-replace',
						method:	'GET',
						success: function(form, action) {
							userCustomerStore.clearFilter();
							var contact_id_value=form.findField('contact_id').getValue();
							//var contactModel = contactGridStore.findRecord('user_id',contact_id_value);
							contactGridStore.remove(contactGridStore.findRecord('user_id',contact_id_value));
							userCustomerStore.remove(userCustomerStore.findRecord('user_id',contact_id_value));
							Ext.Msg.show({
							     title :"Exito borrando/replazando contacto:",
							     msg: 'Borrado y sustitución realizado correctamente',
							     buttons: Ext.Msg.OK,
							     icon: Ext.Msg.INFO
							});	
							Ext.getCmp('ticketChangeContactWindow').close();
						},
						failure: function(form, action) {
							var status = action.response.status;
							
							if (status == 200){
								var message = action.result.errors;
							} else {
								var message = action.response.responseText;
							}
							Ext.Msg.show({
							     title : 'Error borrando/replazando contacto:',
							     msg: message,
							     buttons: Ext.Msg.OK,
							     icon: Ext.Msg.ERROR
							});			
							Ext.getCmp('ticketChangeContactWindow').close();				
						}
					});
					userCustomerStore.clearFilter();
			    }                     
          	},
          	{
              	xtype: 'button',
              	text: '#intranet-sencha-ticket-tracker.Cancel#',
			    handler: function() {
			    	this.up('window').close();
			    }              
         	}
    		],
			renderTo: Ext.getBody()         	
	}]
});
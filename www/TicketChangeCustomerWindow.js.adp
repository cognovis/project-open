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
 
Ext.define('TicketBrowser.TicketChangeCustomerWindow', {
	extend:		'Ext.window.Window',
	id: 		'ticketChangeCustomerWindow',
	alias:		'widget.ticketChangeCustomerWindow',
	title:		'#intranet-sencha-ticket-tracker.Delete_Customer#',
	height:		200,
	width:		500,
	layout:		'fit',
	items: [{
		id: 	'ticketChangeCustomerWindowForm',
		alias:	'widget.ticketChangeCustomerWindowForm',
 		xtype:		'form',
 		bodyStyle:	'padding:5px 5px 0',
		fieldDefaults: {
			msgTarget: 'side',
			labelWidth: 150
		},
		defaultType:	'textfield', 			
		items: [
		{
			id:		'company_id',
			name:		'company_id',
			xtype:		'combobox',
			forceSelection: true,
			fieldLabel:	'#intranet-sencha-ticket-tracker.Customer_To_Delete#',
			anchor:		'100%',
			allowBlank:	false,
			store:		companyStore,
			queryMode:	'local',
			valueField:	'company_id',
			displayField:   'company_name'															
		}, {
			id: 		'company_id_replacement',
			name:		'company_id_replacement',
			xtype:		'combobox',
			forceSelection: true,
			fieldLabel:	'#intranet-sencha-ticket-tracker.Customer_To_Change#',
			anchor:		'100%',
			allowBlank:	false,
			store:		companyStore,
			queryMode:	'local',
			valueField:	'company_id',
			displayField:   'company_name'									
		}
	],	
			buttons: [			
		{
			xtype: 'button',
			text: '#intranet-sencha-ticket-tracker.Change#',
			formBind:	true,
			handler: function() {
	 				//selected customer is changed in all ticket
 					//if the change was OK, selected customer must be deleted

					// Make sure the form is valid
					var form = this.up('form').getForm();
					var company_id = form.findField('company_id');
					if(!form.isValid()) { return; }

					// Submit to the server side script
					form.submit({
						url:	'company-delete-replace',
						method:	'GET',
						success: function(form, action) {
							var customer_id_value=form.findField('company_id').getValue();
							var companyModel = contactGridStore.findRecord('user_id',customer_id_value);
							companyStore.remove(companyModel);
							Ext.Msg.show({
							     title :"Exito borrando/replazando entidad:",
							     msg: 'Borrado y sustitución realizado correctamente',
							     buttons: Ext.Msg.OK,
							     icon: Ext.Msg.INFO
							});		
							Ext.getCmp('ticketChangeCustomerWindow').close();							
						},
						failure: function(form, action) {
							var status = action.response.status;
							
							if (status == 200){
								var message = action.result.errors;
							} else {
								var message = action.response.responseText;
							}
							Ext.Msg.show({
							     title : 'Error borrando/replazando entidad:',
							     msg: message,
							     buttons: Ext.Msg.OK,
							     icon: Ext.Msg.ERROR
							});	
							Ext.getCmp('ticketChangeCustomerWindow').close();	
						}
					});
			}
		}, {
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
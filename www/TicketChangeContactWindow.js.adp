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
   // title: '#intranet-sencha-ticket-tracker.Change_Contact#',
    title: 'Borrar contacto',
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
				labelWidth: 100
			},
			defaultType:	'textfield', 			
      items: [
          {
          		id: 'contactDeleteCombo',
              xtype: 'combo',
             	fieldLabel:	'Contacto a borrar',
              anchor: '100%',
							allowBlank:	false,
							store:		contactGridStore,
							valueField:	'user_id',
							displayField:   'name'													          
          },
          {
          		id: 'contactChangeCombo',
              xtype: 'combo',
              fieldLabel:	'Contacto sustituto',
              anchor: '100%',
							allowBlank:	false,
							store:		contactGridStore,
							valueField:	'user_id',
							displayField:   'name'						            
          }
      ],    
			buttons: [	          
          {
              xtype: 'button',
              text: 'Cambiar',
              formBind:	true,
 							handler: function() {
 									//selected contact is changed in all ticket
 									//if the change was OK, selected contact must be deleted
			            alert('Ops!, not implemented yet');
			        }                     
          },
          {
              xtype: 'button',
              text: 'Cancelar',
			        handler: function() {
			            this.up('window').close();
			        }              
          }
      ],
			renderTo: Ext.getBody()         	
		}]
});
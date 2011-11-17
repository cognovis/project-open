/**
 * intranet-sencha-ticket-tracker/www/AuditGrid.js
 * Grid table for ]po[ file storage
 *
 * @author David Blanco (david.blanco@grupoversia.com)
 * @creation-date 2011-11
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

Ext.define('TicketBrowser.AuditDetailWindow', {
				extend: 	'Ext.window.Window',	
				alias: 		'widget.auditDetailWindow',
				id:		'auditDetailWindow',
			    title: 'Detalle ',
			    //layout: 'fit',
			    height: 600,
			    width: 800,		
				defaults: {		
					margin: '10 20 5 5'				
				},			    	    
				layout: {
				    type: 'table',
				    columns: 2
				},	    
				listeners: {
					beforeclose: function(panel, eOpts ) {
						this.hide();
						return false;
					}
				},
			    items: [
			    {  
					name:		'audit_audit_date',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Audit_Date#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_status_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Status#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_type_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Type#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_queue_id_pretty',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Escalated#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_area_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Area#',
					readOnly: true
			    }, {  
					name:		'audit_company_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Customer#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_customer_contact_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Contact#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_file',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_File_Number#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_creation_date',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Creation_Date#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_reaction_date',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Reaction_Date#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_escalation_date',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Escalation_Date#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_done_date',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Close_Date#',
					readOnly: true
			    }, {  
					name:		'audit_ticket_incoming_channel_id',
					xtype:		'textfield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Incoming_Channel#',
					readOnly: true,
					colspan: 2
			    }, {
					name:		'audit_ticket_request',
					xtype:		'textareafield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Request#',
					readOnly: true,
					labelAlign:	'top',
					colspan: 4,
					width:  700,
					height: 120
			    }, {
					name:		'audit_ticket_resolution',
					xtype:		'textareafield',
					fieldLabel:	'#intranet-sencha-ticket-tracker.Resolution#',
					readOnly: true,
					labelAlign:	'top',
					colspan: 4,	
					width:  700,		
					height: 120									
				}],
				
	loadAuditDetail: function(record) {
		/*var v2 = this.getChildByElement('audit_audit_date');
		var v1 = this.getComponent('audit_audit_date');*/
		this.setTitle('Detalle ' + record.get('audit_date').substring(0,19));
		//v1.setValue(record.get('audit_date').substring(0,19));
		this.items.items[0].setValue(record.get('audit_date').substring(0,19));
		this.items.items[1].setValue(ticketStatusStore.category_from_id(record.get('ticket_status_id')));
		this.items.items[2].setValue(ticketTypeStore.category_from_id(record.get('ticket_type_id')));
		this.items.items[3].setValue(profileStore.name_from_id(record.get('ticket_queue_id')));
		this.items.items[4].setValue(ticketAreaStore.category_from_id(record.get('ticket_area_id')));
		this.items.items[5].setValue(companyStore.name_from_id(record.get('company_id')));
		this.items.items[6].setValue(userStore.name_from_id(record.get('ticket_customer_contact_id')));
		this.items.items[7].setValue(record.get('ticket_file'));
		this.items.items[8].setValue(record.get('ticket_creation_date'));
		this.items.items[9].setValue(record.get('ticket_reaction_date'));
		this.items.items[10].setValue(record.get('ticket_escalation_date'));
		this.items.items[11].setValue(record.get('ticket_done_date'));
		this.items.items[12].setValue(ticketOriginStore.category_from_id(record.get('ticket_incoming_channel_id')));
		this.items.items[13].setValue(record.get('ticket_request').split('\\n').join('\n'));
		this.items.items[14].setValue(record.get('ticket_resolution').split('\\n').join('\n'));
		
	}				
});	

var auditDetailWindow = new TicketBrowser.AuditDetailWindow();		
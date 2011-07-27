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

var ticketGridSelModel = Ext.create('Ext.selection.CheckboxModel', {
	mode:	'SINGLE',
	listeners: {
		selectionchange: function(sm, selections) {
			if (selections.length > 0){
				Ext.getCmp('mainPanel').checkButton('mainTabPanel','ticketActionBar','buttonCopyTicket',false);
			} else {
				Ext.getCmp('mainPanel').checkButton('mainTabPanel','ticketActionBar','buttonCopyTicket',true);
			}
			// var grid = this.view;
			// grid.down('#removeButton').setDisabled(selections.length == 0);
		}
	}
});

var ticketGrid = Ext.define('TicketBrowser.TicketGrid', {
	extend:		'Ext.grid.Panel',	
	alias:		'widget.ticketGrid',
	id:		'ticketGrid',
	minHeight:	200,
	store:		ticketStore,	
	iconCls:	'icon-grid',
	columnLines:	true,
	selModel:	ticketGridSelModel,

	listeners:	{
	itemdblclick: function(view, record, item, index, e) {

		// Open the ticket in a separate tab
		var compoundPanel = Ext.getCmp('ticketCompoundPanel');
		compoundPanel.loadTicket(record);
		var title = record.get('project_name');
		compoundPanel.tab.setText(title);
	
		var mainTabPanel = Ext.getCmp('mainTabPanel');
		mainTabPanel.setActiveTab(compoundPanel);

	}
	},

	initComponent: function(){
		Ext.apply(this, {
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
					clicksToEdit:	1
				})
			],
				viewConfig:	{
					plugins:	[{
						pluginId:	'preview',
						ptype:	'preview',
						bodyField:	'ticket_request',
						expanded:	true
					}]
				},
				columns:	[
			{
				header:	'#intranet-sencha-ticket-tracker.Ticket#',
				dataIndex:	'project_name',
				flex:	1,
				minWidth:	150,
				width:	200,
				renderer: function(value, o, record) {
					var	user_name = userStore.name_from_id(record.get('creation_user'));
					return Ext.String.format('<div class="ticket"><b>{0}</b><span class="author">{1}</span></div>',value, user_name);
				}
			}, {
				header:	'#intranet-sencha-ticket-tracker.Creation_Date#',
				dataIndex:	'ticket_creation_date',
				width:	80
			}, {
				header:	'#intranet-core.VAT_Number#',
				dataIndex:	'vat_number',
				renderer: function(value, o, record) {
					return companyStore.vat_id_from_id(record.get('company_id'));
				}
			}, {
				header:	'#intranet-core.Customer#',
				dataIndex:	'company_id',
				renderer: function(value, o, record) {
					return companyStore.name_from_id(record.get('company_id'));
				}
			}, {
				header:	'#intranet-sencha-ticket-tracker.Program#',
				dataIndex:	'ticket_area_id',
				renderer: function(value, o, record) {
					return ticketAreaStore.category_from_id(record.get('ticket_area_id'));
				}
			}, {
				header:	'#intranet-sencha-ticket-tracker.Incoming_Channel#',
				dataIndex:	'ticket_incoming_channel_id',
				renderer: function(value, o, record) {
					return ticketOriginStore.category_from_id(record.get('ticket_incoming_channel_id'));
				}
			}, {
				header:	'#intranet-helpdesk.Status#',
				dataIndex:	'ticket_status_id',
				width:	60,
				renderer: function(value, o, record) {
					return ticketStatusStore.category_from_id(record.get('ticket_status_id'));
				},
				field:	{
					xtype:	'combobox',
					typeAhead:	false,
					triggerAction:	'all',
					selectOnTab:	true,
					queryMode:	'local',
					store:	ticketStatusStore,
					displayField:	'category',
					valueField:	'category_id'
				}
			}, {
				header:	'#intranet-helpdesk.Queue#',
				dataIndex:	'ticket_queue_id',
				width:	60,
				sortable:	true, 
				renderer: function(value, o, record) {
				    var queueName = profileStore.name_from_id(record.get('ticket_queue_id'));
				    if ('Employees' == queueName) { queueName = ''; }
				    return queueName;
				}
			}, {
				header:	'#intranet-helpdesk.Creator#',
				dataIndex:	'creation_user',
				width:	100,
				renderer: function(value, o, record) {
					return userStore.name_from_id(record.get('creation_user'));
				}
			}, {
				header:	'#intranet-sencha-ticket-tracker.Request#',
				dataIndex:	'ticket_request'
			}, {
				header:	'#intranet-sencha-ticket-tracker.Resolution#',
				dataIndex:	'ticket_resolution'
			}, {
				header:	'#intranet-core.Contact#',
				dataIndex:	'ticket_customer_contact_id',
				renderer: function(value, o, record) {
					return userStore.name_from_id(record.get('ticket_customer_contact_id'));
				}
			}, {
				header:	'#intranet-sencha-ticket-tracker.Closed_in_1st_Contact#',
				dataIndex:	'ticket_closed_in_1st_contact_p'
			}
		],
		dockedItems:	[{
			dock:	'bottom',
			xtype:	'pagingtoolbar',
			store:	ticketStore,
			displayInfo:	true,
			displayMsg:	'#intranet-sencha-ticket-tracker.Displaying_tickets_0_1_of_2_#',
			emptyMsg:	'#intranet-sencha-ticket-tracker.No_items#',
			beforePageText:	'#intranet-sencha-ticket-tracker.Page#'
		}]
	});
	this.callParent();

	// Translate the column headers
	// http://www.extjs.com.br/forum/index.php?topic=4812.0
	if (Ext.grid.header.Container) {
		Ext.apply(Ext.grid.header.Container.prototype, {
			sortAscText:	'#intranet-sencha-ticket-tracker.Sort_Ascending#',
			sortDescText:	'#intranet-sencha-ticket-tracker.Sort_Descending#',
			sortClearText:	'#intranet-sencha-ticket-tracker.Clear#',
			columnsText:	'#intranet-sencha-ticket-tracker.Columns#'
		});
	}


	},

	loadSla: function(id){
		var store = this.store;
		store.getProxy().extraParams.parent_id = id;
		store.loadPage(1);
	},
	
	// Called from TicketFilterForm in order to limit the list of
	// tickets according to filter variables.
	// filterValues is a key-value list (object).
	filterTickets: function(filterValues){
		var store = this.store;
		var proxy = store.getProxy();
		var value = '';
		var query = '1=1';
	
		// Special logic for assigned_queue_id:	Set to '' (=My Queues) if empty
		if (null === filterValues.assigned_queue_id) {
			filterValues.assigned_queue_id = 'my_groups'; 
		}
		
		// delete filters added by other accordion filters
		delete proxy.extraParams['query'];
		delete proxy.extraParams['parent_id'];
	
		// Apply the filter values directly to the proxy.
		// This only works if the filters are named according
		// to the REST interface specs.
		for(var key in filterValues) {
			if (filterValues.hasOwnProperty(key)) {
	
			value = filterValues[key];
			if (value == '' || value == undefined || value == null) {
				// Delete the filter
				delete proxy.extraParams[key];
			} else {
	
				// special treatment for special filter variables
				switch (key) {
				case 'assigned_queue_id':
					// The "my groups" information is not part of the REST information.
					switch (value) {
						case 'my_groups':
							// default query:	all of my groups
							query = query + ' and ticket_queue_id in (select group_id from group_distinct_member_map where member_id in ( ' + currentUserId +'))';
							break;
						case 'all_groups':
							// Do nothing.
							break;
						default:
							// assigned_queue_id contains a group_id
							query = query + ' and ticket_queue_id = ' + value;
							break;
					}
	
					key = 'query';
					value = query;
					
					break;
				case 'project_name':
					// Fuzzy search for the name of the ticket
					value = value.toLowerCase();
					query = query + ' and project_name like \'%' + value + '%\'';
					key = 'query';
					value = query;
					break;
				case 'vat_number':
					// The customer's VAT number is not part of the REST
					// ticket fields. So translate into a query:
					value = value.toLowerCase();
					query = query + ' and company_id in (select company_id from im_companies where lower(vat_number) like \'%' + value + '%\')';
					key = 'query';
					value = query;
					break;
				case 'company_type_id':
					// The customer's company type is not part of the REST ticket fields.
					query = query + ' and company_id in (select company_id from im_companies where company_type_id in (select im_sub_categories from im_sub_categories(' + value + ')))';
					key = 'query';
					value = query;
					break;
				case 'company_name':
					// The customer's company name is not part of the REST
					// ticket fields. So translate into a query:
					value = value.toLowerCase();
					query = query + ' and company_id in (select company_id from im_companies where lower(company_name) like \'%' + value + '%\')';
					key = 'query';
					value = query;
					break;
				case 'start_date':
					// I can't get the proxy to quote (') the date, so we do it manually here:
					var	year = '' + value.getFullYear(),
						month =  '' + (1 + value.getMonth()),
						day = '' + value.getDate();
					if (month.length < 2) { month = '0' + month; }
					if (day.length < 2) { day = '0' + day; }
					value = '\'' + year + '-' + month + '-' + day + '\'';
					// console.log(value);
					query = query + ' and ticket_creation_date >= ' + value;
					key = 'query';
					value = query;
					break;
				case 'end_date':
					// I can't get the proxy to quote (') the date, so we do it manually here:
					var	year = '' + value.getFullYear(),
						month =  '' + (1 + value.getMonth()),
						day = '' + value.getDate();
					if (month.length < 2) { month = '0' + month; }
					if (day.length < 2) { day = '0' + day; }
					value = '\'' + year + '-' + month + '-' + day + '\'';
					// console.log(value);
					query = query + ' and ticket_creation_date <= ' + value;
					key = 'query';
					value = query;
					break;
				break;
				}
	
				// Save the property in the proxy, which will pass it directly to the REST server
				proxy.extraParams[key] = value;
			}
			}
		}
		
		store.loadPage(1);
	},
	
	onPreviewChange: function(btn, pressed){
		this.ownerCt.togglePreview(pressed);
	},
	
	// Received from TicketActionBar:
	// Prepare to create a new ticket.
	onNew: function(){
		var panel = this.ownerCt.ownerCt;
		panel.ownerCt.onNew();
	},

	onGridChange: function(btn, pressed){
		this.ownerCt.toggleGrid(pressed);
	},
	
	onSummaryChange: function(btn, pressed){
		this.getView().getPlugin('preview').toggleExpanded(pressed);
	},

	// Delete the currently selected ticket
	onDelete: function(btn, pressed){

		// Get the selected ticket (only one!)
		var selection = this.selModel.getSelection();
		var ticketModel = selection[0];

		// Send a GET request to the server in order to
		// destroy the ticket. DELETE on REST may cause
		// problems because session information is not
		// defined in DELETE
		Ext.Ajax.request({
			scope:	this,
			url:	'/intranet-sencha-ticket-tracker/delete-ticket',
			success: function(response) {
		 		console.log('Ticket #'+ticketModel.get('project_nr')+' was destroyed.');
				ticketStore.remove(ticketModel);
			},
			failure: function(response) {
				Ext.Msg.alert('Error borrando Ticket #'+ticketModel.get('project_nr')+':\nSolo administradores tienen permisso para borrar tickets.', response.responseText);
			}
		});
	},

	onCopy: function() {
		var selection = this.selModel.getSelection();
		var ticketModel = selection[0];

		// Ticket list or view page
		var ticketCompoundPanel = Ext.getCmp('ticketCompoundPanel');
		ticketCompoundPanel.tab.setText('#intranet-helpdesk.New_Ticket#');
		var mainTabPanel = Ext.getCmp('mainTabPanel');
		mainTabPanel.setActiveTab(ticketCompoundPanel);

		// Tell the compound panel to create a copy of the old ticket
		ticketCompoundPanel.loadTicket(ticketModel);
		ticketCompoundPanel.onCopy();
	}

});

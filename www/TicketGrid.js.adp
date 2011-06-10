/**
 * intranet-sencha-ticket-tracker/www/TicketGrid.js
 * Grid table for ]po[ tickets
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketGrid.js.adp,v 1.13 2011/06/10 14:24:06 po34demo Exp $
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


var ticketGrid = Ext.define('TicketBrowser.TicketGrid', {
    extend:	'Ext.grid.Panel',    
    alias:	'widget.ticketGrid',
    id:		'ticketGrid',
    minHeight:	200,
    store:	ticketStore,    
    iconCls:	'icon-grid',

    listeners: {
	itemdblclick: function(view, record, item, index, e) {
		var mainTabPanel = Ext.getCmp('mainTabPanel');
		var tab = mainTabPanel.add({
        	    title:	'Tab ' + (mainTabPanel.items.length + 1),
		    xtype:	'ticketCompoundPanel'
        	});
		tab.doLayout();
		tab.loadTicket(record);
	}
    },

    initComponent: function(){
        Ext.apply(this, {
	    plugins: [
		Ext.create('Ext.grid.plugin.CellEditing', {
        	    clicksToEdit: 1
        	})
	    ],
            viewConfig: {
                plugins: [{
                    pluginId: 'preview',
                    ptype: 'preview',
                    bodyField: 'ticket_description',
                    expanded: true
                }]
            },
            selModel: Ext.create('Ext.selection.RowModel', {
                mode: 'MULTI',
                listeners: {
                    scope: this,
                    select: this.onSelect
                }    
            }),
            columns: [
		{
			header: 'Ticket',
			dataIndex: 'project_name',
			flex: 1,
			minWidth: 150,
			width: 200,
			renderer: function(value, o, record) {
				var	user_name = userStore.name_from_id(record.get('creation_user'));
				return Ext.String.format('<div class="ticket"><b>{0}</b><span class="author">{1}</span></div>',value, user_name);
			}
		}, {
			header: '#intranet-sencha-ticket-tracker.Creation_Date#',
			dataIndex: 'ticket_creation_date',
			width: 80
		}, {
			header: '#intranet-core.VAT_Number#',
			dataIndex: 'vat_number',
			renderer: function(value, o, record) {
				return companyStore.vat_id_from_id(record.get('company_id'));
			}
		}, {
			header: '#intranet-core.Customer#',
			dataIndex: 'company_id',
			renderer: function(value, o, record) {
				return companyStore.name_from_id(record.get('company_id'));
			}
		}, {
			header: '#intranet-sencha-ticket-tracker.Program#',
			dataIndex: 'ticket_program_id'
		}, {
			header: '#intranet-sencha-ticket-tracker.Incoming_Channel#',
			dataIndex: 'ticket_channel_id',
			hidden: true
		}, {
			header: '#intranet-helpdesk.Status#',
			dataIndex: 'ticket_status_id',
			width: 60,
			renderer: function(value, o, record) {
				return ticketStatusStore.category_from_id(record.get('ticket_status_id'));
			},
			field: {
				xtype: 'combobox',
				typeAhead: false,
				triggerAction: 'all',
				selectOnTab: true,
				queryMode: 'local',
				store: ticketStatusStore,
				displayField: 'category',
				valueField: 'category_id'
			}
		}, {
			header: '#intranet-helpdesk.Prio#',
			dataIndex: 'ticket_prio_id',
			width: 40,
			renderer: function(value, o, record) {
				return ticketPriorityStore.category_from_id(record.get('ticket_prio_id'));
			},
			field: {
				xtype: 'combobox',
				typeAhead: false,
				triggerAction: 'all',
				selectOnTab: true,
				queryMode: 'local',
				store: Ext.create('Ext.data.Store', {
				    fields: ['id', 'category'],
				    data : ticketPriorityData
				}),
				displayField: 'category',
				valueField: 'id'
			}
		}, {
			header: '#intranet-helpdesk.Creator#',
			dataIndex: 'creation_user',
			width: 100,
			renderer: function(value, o, record) {
				return userStore.name_from_id(record.get('creation_user'));
			}
		}, {
			header: '#intranet-sencha-ticket-tracker.Replies#',
			dataIndex: 'replycount',
			width: 70,
			align: 'right'
		}, {
			header: '#intranet-core.Assignee#',
			dataIndex: 'ticket_assignee_id',
			renderer: function(value, o, record) {
				return userStore.name_from_id(record.get('ticket_assignee_id'));
			}
		}, {
			header: '#intranet-core.Contact#',
			dataIndex: 'ticket_customer_contact_id',
			renderer: function(value, o, record) {
				return userStore.name_from_id(record.get('ticket_customer_contact_id'));
			}
		}, {
			header: '#intranet-helpdesk.Queue#',
			dataIndex: 'ticket_queue_id'
		}, {
			header: '#intranet-sencha-ticket-tracker.Department#',
			dataIndex: 'ticket_dept_id'
		}, {
			header: '#intranet-sencha-ticket-tracker.Service#',
			dataIndex: 'ticket_service_id'
		}, {
			header: '#intranet-sencha-ticket-tracker.Alarm_Date#',
			dataIndex: 'ticket_alarm_date'
		}, {
			header: '#intranet-sencha-ticket-tracker.Alarm_Action#',
			dataIndex: 'ticket_alarm_action'
		}, {
			header: '#intranet-helpdesk.Conf_Item_type_Hardware#',
			dataIndex: 'ticket_hardware_id'
		}, {
			header: '#intranet-sencha-ticket-tracker.Application#',
			dataIndex: 'ticket_application_id'
		}, {
			header: '#intranet-helpdesk.Conf_Item#',
			dataIndex: 'ticket_conf_item_id'
		}, {
			header: '#intranet-sencha-ticket-tracker.Customer_Deadline#',
			dataIndex: 'ticket_customer_deadline'
		}, {
			header: '#intranet-core.lt_Closed_in_1st_Contact#',
			dataIndex: 'ticket_closed_in_1st_contact_p'
		}
	    ],
	    dockedItems: [{
		xtype: 'toolbar',
		cls: 'x-docked-noborder-top',
		items: [{
		    text: '#intranet-helpdesk.New_Ticket#',
		    iconCls: 'icon-new-ticket',
		    handler: function() {
			var compoundPanel = Ext.getCmp('ticketCompoundPanel');
		        compoundPanel.tab.setText('#intranet-helpdesk.New_Ticket#');
			var mainTabPanel = Ext.getCmp('mainTabPanel');
			mainTabPanel.setActiveTab(compoundPanel);	
			compoundPanel.newTicket();
		    }
		}, {
		    text: '#intranet-sencha-ticket-tracker.Copy_Ticket#',
		    iconCls: 'icon-new-ticket',
		    handler: function(){
			alert('Not implemented');
		    }
		},    {
    		    text: '#intranet-helpdesk.Remove_checked_items#',
    		    iconCls: 'icon-new-ticket',
    		    handler: function(){
    			alert('Not implemented');
    		    }
		}, '-', {
		    text: '#intranet-core.Summary#',
		    iconCls: 'icon-summary',
		    enableToggle: true,
		    pressed: true,
		    scope: this,
		    toggleHandler: this.onSummaryChange
		}]
	    }, {
		dock: 'bottom',
		xtype: 'pagingtoolbar',
		store: ticketStore,
		displayInfo: true,
		displayMsg: '#intranet-sencha-ticket-tracker.Displaying_tickets_0_1_of_2_#',
		emptyMsg: '#intranet-sencha-ticket-tracker.No_items#'
	    }]
	});
	this.callParent();
    },

    onSelect: function(selModel, rec){
	var compoundPanel = Ext.getCmp('ticketCompoundPanel');
	compoundPanel.loadTicket(rec);
	var title = rec.get('project_name');
        compoundPanel.tab.setText(title);

	var mainTabPanel = Ext.getCmp('mainTabPanel');
	mainTabPanel.setActiveTab(compoundPanel);
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

	// delete filters added by other accordion filters
	delete proxy.extraParams['query'];
	delete proxy.extraParams['parent_id'];

	// Apply the filter values directly to the proxy.
	// This only works if the filters are named according
	// to the REST interface specs.
	for(var key in filterValues) {
	    if (filterValues.hasOwnProperty(key)) {

		value = filterValues[key];
		// console.log('TicketGrid: "'+key+'" = "' + value + '"');
	
		if (value == '' || value == undefined || value == null) {

		    // Delete the filter
		    // console.log('TicketGrid: Deleting key="'+key+'"');
		    delete proxy.extraParams[key];

		} else {

		    // special treatment for special filter variables
		    switch (key) {
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
    
    onNewTicket: function(dummy){
        var panel = this.ownerCt.ownerCt;
	panel.ownerCt.onNewTicket();
    },

    onGridChange: function(btn, pressed){
	this.ownerCt.toggleGrid(pressed);
    },
    
    onSummaryChange: function(btn, pressed){
	this.getView().getPlugin('preview').toggleExpanded(pressed);
    }

});

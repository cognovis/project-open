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


var ticketGrid = Ext.define('TicketBrowser.TicketGrid', {
    extend: 'Ext.grid.Panel',    
    alias: 'widget.ticketGrid',
    minHeight: 200,
    store: ticketStore,    
    iconCls: 'icon-grid',

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
                mode: 'SINGLE',
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
			minWidth: 100,
			width: 200,
			renderer: function(value, o, record) {
				var	user_name = employeeStore.name_from_id(record.get('creation_user'));
				return Ext.String.format('<div class="ticket"><b>{0}</b><span class="author">{1}</span></div>',value, user_name);
			}
		}, {
			header: 'Creation Date',
			dataIndex: 'ticket_creation_date',
			width: 80
		}, {
			header: 'VAT ID',
			dataIndex: 'vat_number',
			renderer: function(value, o, record) {
				return companyStore.vat_id_from_id(record.get('company_id'));
			}
		}, {
			header: 'Customer',
			dataIndex: 'company_id',
			renderer: function(value, o, record) {
				return companyStore.name_from_id(record.get('company_id'));
			}
		}, {
			header: 'Program',
			dataIndex: 'ticket_program_id'
		}, {
			header: 'Channel',
			dataIndex: 'ticket_channel_id',
			hidden: true
		}, {
			header: 'Status',
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
			header: 'Prio',
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
			header: 'Creator',
			dataIndex: 'creation_user',
			width: 100,
			renderer: function(value, o, record) {
				return employeeStore.name_from_id(record.get('creation_user'));
			}
		}, {
			header: 'Replies',
			dataIndex: 'replycount',
			width: 70,
			align: 'right'
		}, {
			header: 'Assignee',
			dataIndex: 'ticket_assignee_id',
			renderer: function(value, o, record) {
				return employeeStore.name_from_id(record.get('ticket_assignee_id'));
			}
		}, {
			header: 'Contact',
			dataIndex: 'ticket_customer_contact_id',
			renderer: function(value, o, record) {
				return employeeStore.name_from_id(record.get('ticket_customer_contact_id'));
			}
		}, {
			header: 'Queue',
			dataIndex: 'ticket_queue_id'
		}, {
			header: 'Dept',
			dataIndex: 'ticket_dept_id'
		}, {
			header: 'Service',
			dataIndex: 'ticket_service_id'
		}, {
			header: 'Alarm Date',
			dataIndex: 'ticket_alarm_date'
		}, {
			header: 'Alarm Action',
			dataIndex: 'ticket_alarm_action'
		}, {
			header: 'Hardware',
			dataIndex: 'ticket_hardware_id'
		}, {
			header: 'Application',
			dataIndex: 'ticket_application_id'
		}, {
			header: 'Conf Item',
			dataIndex: 'ticket_conf_item_id'
		}, {
			header: 'Customer Deadline',
			dataIndex: 'ticket_customer_deadline'
		}, {
			header: '1st CC',
			dataIndex: 'ticket_closed_in_1st_contact_p'
		}
	    ],
	    dockedItems: [{
		xtype: 'toolbar',
		cls: 'x-docked-noborder-top',
		items: [{
		    text: 'New Ticket',
		    iconCls: 'icon-new-ticket',
		    handler: this.onNewTicket
		}, {
		    text: 'Copy Ticket',
		    iconCls: 'icon-new-ticket',
		    handler: function(){
			alert('Not implemented');
		    }
		},    {
    		    text: 'Remove Ticket',
    		    iconCls: 'icon-new-ticket',
    		    handler: function(){
    			alert('Not implemented');
    		    }
    		}, '-', {
		    text: 'Show Grid',
		    iconCls: 'icon-preview',
		    enableToggle: true,
		    pressed: true,
		    scope: this,
		    toggleHandler: this.onGridChange
    		}, '-', {
		    text: 'Show Ticket',
		    iconCls: 'icon-preview',
		    enableToggle: true,
		    pressed: true,
		    scope: this,
		    toggleHandler: this.onPreviewChange
		}, {
		    text: 'Summary',
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
		displayMsg: 'Displaying tickets {0} - {1} of {2}',
		emptyMsg: 'No tickets to display'
	    }]
	});
	this.callParent();
    },
    
    onSelect: function(selModel, rec){
	this.ownerCt.onSelect(rec);
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




/**
 * intranet-sencha-project-tracker/www/ProjectGrid.js
 * Grid table for ]po[ projects
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
 * @creation-date 2011-05
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


var projectGrid = Ext.define('ProjectBrowser.ProjectGrid', {
    extend: 'Ext.grid.Panel',    
    alias: 'widget.projectgrid',
    minHeight: 200,
    store: projectStore,

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
                    bodyField: 'project_description',
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
			header: 'Project',
			dataIndex: 'project_name',
			flex: 1,
			minWidth: 100,
			width: 200,
			renderer: function(value, o, record) {
				var	user_name = employeeStore.name_from_id(record.get('creation_user'));
				return Ext.String.format('<div class="project"><b>{0}</b><span class="author">{1}</span></div>',value, user_name);
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
			dataIndex: 'project_status_id',
			width: 60,
			renderer: function(value, o, record) {
				return projectStatusStore.category_from_id(record.get('project_status_id'));
			},
			field: {
				xtype: 'combobox',
				typeAhead: false,
				triggerAction: 'all',
				selectOnTab: true,
				queryMode: 'local',
				store: projectStatusStore,
				displayField: 'category',
				valueField: 'category_id'
			}
		}, {
			header: 'Prio',
			dataIndex: 'project_prio_id',
			width: 40,
			renderer: function(value, o, record) {
				return projectPriorityStore.category_from_id(record.get('project_prio_id'));
			},
			field: {
				xtype: 'combobox',
				typeAhead: false,
				triggerAction: 'all',
				selectOnTab: true,
				queryMode: 'local',
				store: Ext.create('Ext.data.Store', {
				    fields: ['id', 'category'],
				    data : projectPriorityData
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
			dataIndex: 'project_assignee_id',
			renderer: function(value, o, record) {
				return employeeStore.name_from_id(record.get('project_assignee_id'));
			}
		}, {
			header: 'Contact',
			dataIndex: 'project_customer_contact_id',
			renderer: function(value, o, record) {
				return employeeStore.name_from_id(record.get('project_customer_contact_id'));
			}
		}, {
			header: 'Queue',
			dataIndex: 'project_queue_id'
		}, {
			header: 'Dept',
			dataIndex: 'project_dept_id'
		}, {
			header: 'Service',
			dataIndex: 'project_service_id'
		}, {
			header: 'Alarm Date',
			dataIndex: 'project_alarm_date'
		}, {
			header: 'Alarm Action',
			dataIndex: 'project_alarm_action'
		}, {
			header: 'Hardware',
			dataIndex: 'project_hardware_id'
		}, {
			header: 'Application',
			dataIndex: 'project_application_id'
		}, {
			header: 'Conf Item',
			dataIndex: 'project_conf_item_id'
		}, {
			header: 'Customer Deadline',
			dataIndex: 'project_customer_deadline'
		}, {
			header: '1st CC',
			dataIndex: 'project_closed_in_1st_contact_p'
		}
	    ],
	    dockedItems: [{
		xtype: 'toolbar',
		cls: 'x-docked-noborder-top',
		items: [{
		    text: 'New Project',
		    iconCls: 'icon-new-project',
		    handler: function(){
			alert('Not implemented');
		    }
		}, '-', {
		    text: 'Preview Pane',
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
		store: projectStore,
		displayInfo: true,
		displayMsg: 'Displaying projects {0} - {1} of {2}',
		emptyMsg: 'No projects to display'
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
    
    onPreviewChange: function(btn, pressed){
	this.ownerCt.togglePreview(pressed);
    },
    
    onSummaryChange: function(btn, pressed){
	this.getView().getPlugin('preview').toggleExpanded(pressed);
    }
});

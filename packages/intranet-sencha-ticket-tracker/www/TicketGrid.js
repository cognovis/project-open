
Ext.define('TicketBrowser.TicketGrid', {
    extend: 'Ext.grid.Panel',    
    alias: 'widget.ticketgrid',
    minHeight: 200,

    initComponent: function(){
        var store = Ext.create('Ext.data.Store', {
            model: 'TicketBrowser.Ticket',
            remoteSort: true,
            sorters: [{
                property: 'creation_date',
                direction: 'DESC'
            }],
            proxy: {
                type: 'rest',
                url: '/intranet-rest/im_ticket',
		extraParams: {
		    format: 'json',		// Tell the ]po[ REST to return JSON data.
		    format_variant: 'sencha'	// Tell the ]po[ REST to return all columns
                },
                reader: {
                    type: 'json',		// Tell the Proxy Reader to parse JSON
                    root: 'data'		// Where do the data start in the JSON file?
                },
                writer: {
                    type: 'json'
                }
            }
        });
        
        Ext.apply(this, {
            store: store,
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
			renderer: function(value, o, record) {
				var	user_id = record.get('creation_user'),
					creation_user_idx = customerContactStore.find('user_id',user_id),
					user_record = customerContactStore.getAt(creation_user_idx),
					user_name = 'User #' + user_id;
				if (typeof user_record != "undefined") { user_name = user_record.get('name'); }
				return Ext.String.format('<div class="ticket"><b>{0}</b><span class="author">{1}</span></div>',
				       value, user_name);
			}
		}, {
			header: 'Prio',
			dataIndex: 'ticket_prio_id',
			width: 40,
			renderer: function(value, o, record) {
				// Show the dereferenced category
				var	category_id = record.get('ticket_prio_id'),
					category_idx = ticketPriorityStore.find('category_id',category_id),
					category_record = ticketPriorityStore.getAt(category_idx),
					category = 'Category #' + category_id;
				if (typeof category_record != "undefined") { category = category_record.get('category'); }
				return category;
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
			width: 100
		}, {
			header: 'Replies',
			dataIndex: 'replycount',
			width: 70,
			align: 'right'
		}, {
			header: 'Creation Date',
			dataIndex: 'creation_date',
			width: 150
		}
	    ],
	    dockedItems: [{
		xtype: 'toolbar',
		cls: 'x-docked-noborder-top',
		items: [{
		    text: 'New Ticket',
		    iconCls: 'icon-new-ticket',
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
		store: store,
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
    
    onPreviewChange: function(btn, pressed){
	this.ownerCt.togglePreview(pressed);
    },
    
    onSummaryChange: function(btn, pressed){
	this.getView().getPlugin('preview').toggleExpanded(pressed);
    }
});

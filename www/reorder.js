Ext.require([
    'Ext.tree.*',
    'Ext.data.*',
    'Ext.tip.*'
]);

Ext.onReady(function() {
    Ext.QuickTips.init();

    var model = Ext.define('Project', {
	    extend: 'Ext.data.Model',
	    fields: ['id', 'text']
    });
    
    var store = Ext.create('Ext.data.TreeStore', {
	model: model,
        proxy: {
		type: 'rest',
		url: '/intranet-sencha-ticket-tracker/sla-projects',
		extraParams: {
			format: 'json',
			format_variant: 'sencha'
		},
		reader: {
			type: 'json',
			root: 'data'
		}
        },
        root: {
            text: 'Ext JS',
            id: 'all',
            expanded: true
        },
        folderSort: true,
        sorters: [{
            property: 'text',
            direction: 'ASC'
        }]
    });

    var tree = Ext.create('Ext.tree.Panel', {
        store: store,
        viewConfig: {
            plugins: {
                ptype: 'treeviewdragdrop'
            }
        },
        renderTo: 'tree-div',
        height: 300,
        width: 250,
        title: 'Files',
        useArrows: true,
	displayField: 'id',
        dockedItems: [{
            xtype: 'toolbar',
            items: [{
                text: 'Expand All',
                handler: function(){
                    tree.expandAll();
                }
            }, {
                text: 'Collapse All',
                handler: function(){
                    tree.collapseAll();
                }
            }]
        }]
    });
});


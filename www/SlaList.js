Ext.define('TicketBrowser.SlaList', {

    extend: 'Ext.tree.Panel',   
    alias: 'widget.slalist',
    rootVisible: true,
    lines: false,
    defaultSla: 53349,
    minWidth: 200,
    displayField: 'project_name',
    
    initComponent: function(){
        Ext.apply(this, {
            viewConfig: {
                getRowClass: function(record) {
                    if (!record.get('leaf')) {
                        return 'sla-parent';
                    }
                }
            },
            store: Ext.create('Ext.data.TreeStore', {
                model: 'TicketBrowser.Sla',
                proxy: {
                    type: 'rest',
                    url: '/intranet-sencha-ticket-tracker/sla-datasource',
		    appendId: true,
                    reader: {
                        type: 'json',
                        root: 'data'
                    }
                },
                root: {
		    text: 'All',
		    id: '',
		    project_id: '',
                    expanded: true
                },
                listeners: {
                    single: true,
                    scope: this,
                    load: this.onFirstLoad
                }
            })
        });
        this.callParent();
        this.getSelectionModel().on({
            scope: this,
            select: this.onSelect
        });
    },
    
    onFirstLoad: function(){
        var rec = this.store.getNodeById(this.defaultSla);
        this.getSelectionModel().select(rec);
    },
    
    onSelect: function(selModel, rec){
	// if (rec.get('leaf')) { }		// Disable the check for leaf elements only
        this.ownerCt.loadSla(rec);		// In the list of SLAs every SLA is a leaf...
    }
});


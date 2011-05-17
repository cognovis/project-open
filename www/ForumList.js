Ext.define('ForumBrowser.ForumList', {

    extend: 'Ext.tree.Panel',   
    alias: 'widget.forumlist',
    rootVisible: true,
    lines: false,
    defaultForum: 53349,
    minWidth: 200,
    
    initComponent: function(){
        Ext.apply(this, {
            viewConfig: {
                getRowClass: function(record) {
                    if (!record.get('leaf')) {
                        return 'forum-parent';
                    }
                }
            },
            store: Ext.create('Ext.data.TreeStore', {
                model: 'ForumBrowser.Forum',
                proxy: {
                    type: 'rest',
                    url: '/intranet-sencha-ticket-tracker/sla-projects',
		    appendId: true,
                    reader: {
                        type: 'json',
                        root: 'data'
                    }
                },
                root: {
		    text: 'All',
		    id: '',
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
        var rec = this.store.getNodeById(this.defaultForum);
        this.getSelectionModel().select(rec);
    },
    
    onSelect: function(selModel, rec){

        this.ownerCt.loadForum(rec);
//        if (rec.get('leaf')) {        }
    }
});
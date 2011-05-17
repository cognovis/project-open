
var forumStore = Ext.create('Ext.data.TreeStore', {
    root: {
        expanded: true, 
        text:"",
        user:"",
        status:"", 
        children: [
            { text:"detention", leaf: true },
            { text:"homework", expanded: true, 
                children: [
                    { text:"book report", leaf: true },
                    { text:"alegrbra", leaf: true}
                ]
            },
            { text: "buy lottery tickets", leaf:true }
        ]
    }
});

Ext.define('ForumBrowser.ForumList', {
    extend: 'Ext.tree.Panel',
    alias: 'widget.forumlist',
    
    rootVisible: false,
    lines: false,
    defaultForum: 40,
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
            store: forumStore
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
        if (rec.get('leaf')) {
            this.ownerCt.loadForum(rec);
        }
    }
});
Ext.define('TicketBrowser.TicketContainer', {
    extend: 'Ext.container.Container',
    alias: 'widget.ticketcontainer',
    title: 'Loading...',

    initComponent: function(){
        Ext.apply(this, {
            layout: 'border',
            items: [{
                itemId: 'grid',
                xtype: 'ticketgrid',
                region: 'center'
            }, {
                itemId: 'preview',
		xtype: 'ticketform',
                region: 'south',
                split: true,
                title: 'View Ticket'
            }]
        });
        this.callParent();
    },

    afterLayout: function() {
        this.callParent();
        // IE6 likes to make the content disappear, hack around it...
        if (Ext.isIE6) { this.el.repaint(); }
    },
    
    loadSla: function(rec) {
        this.tab.setText(rec.get('project_name'));
        this.child('#grid').loadSla(rec.getId());
    },
    
    onSelect: function(rec) {
        this.child('#preview').update({
            title: rec.get('project_name')
        });
        this.child('#preview').loadTicket(rec);
    },
    
    togglePreview: function(show){
        var preview = this.child('#preview');
        if (show) {
            preview.show();
        } else {
            preview.hide();
        }
    }
});
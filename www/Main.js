Ext.define('TicketBrowser.Main', {
    extend: 'Ext.container.Viewport',
    
    initComponent: function(){
        Ext.apply(this, {
            layout: 'border',
            itemId: 'main',
            items: [{
                xtype: 'slalist',
                region: 'west',
                width: 300,
                title: 'Service Level Agreements',
                split: true,
                margins: '5 0 5 5'
            }, {
                region: 'center',
                xtype: 'tabpanel',
                margins: '5 5 5 0',
                minWidth: 400,
                border: false,
                tabBar: {
                    border: true
                },
                items: {
                    itemId: 'ticket',
                    xtype: 'ticketcontainer'
                }
            }]
        });
        this.callParent();
    },
    
    loadSla: function(rec){
        this.down('#ticket').loadSla(rec);
    }  
});
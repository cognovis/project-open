Ext.define('ProjectOpen.view.project.Card', {
    extend: 'Ext.NavigationView',
    xtype: 'projectContainer',
    config: {
        title: 'Projects',
        iconCls: 'time',
        autoDestroy: false,
        items: [
            {
                xtype: 'projects',
                store: 'Projects',
                grouped: true,
                pinHeaders: false
            }
        ]
    }
});

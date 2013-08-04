Ext.define('PO.view.HourList', {
    extend: 'Ext.List',
    xtype: 'hourList',
    requires: ['PO.store.HourOneProjectStore'],
    
    config: {
	title: 'Hour List',
	iconCls: 'star',
	itemTpl: '<div class="contact2">{project_id} {user_id} {hours} {note} </div>',
	disclosure: true,
	grouped: false,
	indexBar: true,
	store: 'HourOneProjectStore',
	onItemDisclosure: true
    }
});


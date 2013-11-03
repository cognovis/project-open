Ext.define('PO.view.HourList', {
    extend: 'Ext.List',
    xtype: 'hourList',
    requires: ['PO.store.HourOneProjectStore'],
    
    config: {
	title: 'Hour List',
	iconCls: 'star',
	itemTpl: '<div class="contact2">{date} {hours} {note} </div>',
	disclosure: true,
	grouped: true,
	indexBar: true,
	store: 'HourOneProjectStore',
	onItemDisclosure: true
    }
});


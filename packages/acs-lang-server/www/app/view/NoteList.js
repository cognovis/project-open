Ext.define('PO.view.NoteList', {
	extend: 'Ext.List',
	xtype: 'noteList',
	requires: ['PO.store.NoteStore'],

	config: {
		title: 'Note List',
		iconCls: 'star',
		itemTpl: '<div class="contact2">{note}</div>',
		disclosure: true,
		grouped: true,
		indexBar: true,
		store: 'NoteStore',
		onItemDisclosure: true
	}
});


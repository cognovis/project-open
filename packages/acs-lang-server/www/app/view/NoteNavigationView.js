Ext.define('PO.view.NoteNavigationView', {
	extend: 'Ext.navigation.View',
	xtype: 'noteNavigationView',
	requires: [
		   'PO.view.NoteList',
		   'PO.view.NoteDetail'
	],
	config: {
	    title: 'Notes',
	    iconCls: 'star',
	    items: [{
		    xtype: 'noteList'
	    }]
	}
});

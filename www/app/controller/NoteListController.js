Ext.define('PO.controller.NoteListController', {
        extend: 'Ext.app.Controller',
	xtype: 'noteListController',
	config: {
	    refs: {
	    },
	    control: {
		'noteList': {
		    activate: 'onActivate'
		}
	    }
	},

	// Load the store on-demand in order to fix iPhone loading issue
	onActivate: function() {
	    Ext.getStore('NoteStore').load();
	}

});


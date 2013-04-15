Ext.define('PO.controller.NoteNavigationController', {
        extend: 'Ext.app.Controller',
	xtype: 'noteNavigationController',
	config: {
	    refs: {
	    	  noteNavigationView: 'noteNavigationView'
	    },
	    control: {
		'noteList': {
		    disclose: 'showDetail'
		}
	    }
	},

	showDetail: function(list, record) { 
	    console.log('disclose details'); 
	    var view = this.getNoteNavigationView();
	    view.push({
		xtype: 'noteDetail',
		title: record.data.note,
		data: record.data
	    });
	}
});


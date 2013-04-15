Ext.define('PO.controller.NoteNavigationController', {
        extend: 'Ext.app.Controller',
	xtype: 'noteNavigationController',
	config: {
	    refs: {
	    	  noteNavigationView: 'noteNavigationView'
	    },
	    control: {
		'noteNavigationView': {
		    initialize: 'onInitializeNavigationView'
		},
		'noteList': {
		    disclose: 'showDetail'
		}
	    }
	},

	// Initialization of the Container - add a button
	// The NavigationView itself doesn't seem to allow for this type of customization
	onInitializeNavigationView: function(navView) {
	    var navBar = Ext.ComponentQuery.query('noteNavigationView')[0].getNavigationBar();
	    navBar.add({
		        xtype: 'button',
			text: 'New Note',
			align: 'right',
			handler: function() {
			    console.log('NoteListController: New Note button pressed');
			    navView.push({
				    xtype: 'noteDetail'
			    });
		    }
	    });
	},

	// "Disclose" Event - somebody pressed on the -> button at the list
	// Create a new instance of the noteDetail page and push on the top
	// of the stack
	showDetail: function(list, record) { 
	    var view = this.getNoteNavigationView();
	    view.push({
		xtype: 'noteDetail',
		title: record.data.note,
		record: record
	    });
	}

});


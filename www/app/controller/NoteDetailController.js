Ext.define('PO.controller.NoteDetailController', {
        extend: 'Ext.app.Controller',
	xtype: 'noteDetailController',
	config: {
	    refs: {
		noteDetail: 'noteDetail'
	    },
	    control: {
		'noteDetail': {
		    activate: 'onActivate'
		}
	    }
	},

	onActivate: function(obj, rec) {
	    var form = this.getNoteDetail();
	    var data = form.getData();
	    console.log('NoteDetailController.onActivate: data=' + data);
	    form.setValues(data);
	    form.setRecord(rec);
	}

});

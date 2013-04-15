Ext.define('PO.controller.UserNavigationController', {
        extend: 'Ext.app.Controller',
	xtype: 'userNavigationController',
	config: {
	    refs: {
	    	  userNavigationView: 'userNavigationView'
	    },
	    control: {
		'userList': {
		    disclose: 'showDetail'
		}
	    }
	},

	showDetail: function(list, record) { 
	    console.log('disclose details'); 
	    var view = this.getUserNavigationView();
	    view.push({
		xtype: 'userDetail',
		title: record.fullName(),
		data: record.data
	    });
	}

});


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

	showDetail: function() { 
	    console.log('disclose details'); 
	    var view = this.getUserNavigationView();
	    view.push({
		xtype: 'userDetail'
	    });
	}

});


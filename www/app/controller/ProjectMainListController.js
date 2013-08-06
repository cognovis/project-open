Ext.define('PO.controller.ProjectMainListController', {
    extend: 'Ext.app.Controller',
    xtype: 'projectMainListController',
    config: {
	profile: Ext.os.deviceType.toLowerCase(),
	refs: {
	    projectMainListNavigationView: 'projectMainListNavigationView',
	    projectMainList: 'projectMainList',
	    hourList: 'hourList',
	    hourDetailListContainer: 'hourDetailListContainer'
	},

	control: {
	    'projectMainList': {
		activate: 'onActivate',
		itemtap: 'onItemTap',
	    }
	}
    },
    
    onActivate: function() {
	console.log('Main container is active');
    },
 
    onItemTap: function(view, index, target, record, event) {
	console.log('Item was tapped on the Data View');
	console.log(view, index, target, record, event);
	if(event.target.type == "button"){

	    // load the right data into the store
	    var store = Ext.data.StoreManager.lookup('HourOneProjectStore');
	    store.load({
		params : { 
		    'project_id': record.get('project_id'),
		    'user_id': '624'
		}
	    })

	    // push an HourList to the NavigationView page
	    var navView = this.getProjectMainListNavigationView();
            var hourList = Ext.create("PO.view.HourList");
	    hourList.setStore(store);
	    var list = navView.push(hourList);
	}
	else {
	    // Tapped on the main item
            var view = this.getProjectMainListNavigationView();
            view.push({
		xtype: 'projectPanelDetail',
		record: record
            });
	}
    }
});


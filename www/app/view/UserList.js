Ext.define('PO.view.UserList', {
	extend: 'Ext.List',
	xtype: 'userList',
	requires: ['PO.store.UserStore'],

	config: {
	    
		title: 'UserList',
		iconCls: 'star',
		itemTpl: '<div class="contact2"><strong>{first_names}</strong> {last_name}</div>',
		disclosure: true,
		grouped: true,
		indexBar: true,
		store: 'UserStore',
		onItemDisclosure: true

	}

    });


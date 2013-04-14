Ext.define('PO.view.UserList', {
	extend: 'Ext.List',
	xtype: 'userList',
	requires: ['PO.store.Users'],

	config: {
	    
		title: 'Users',
		iconCls: 'star',
		itemTpl: '<div class="contact2"><strong>{first_names}</strong> {last_name}</div>',
		disclosure: true,
		grouped: true,
		indexBar: true,
		store: 'Users',
		onItemDisclosure: true

	}

    });


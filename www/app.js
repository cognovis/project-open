
Ext.application({
    name: 'PO',
    models: ['Note'],
    stores: ['Notes', 'Users', 'Contacts'],
    views: ['UserList', 'UserDetail', 'BlogList', 'UserNavigationView'],
    controllers: ['UserNavigationController'],

    requires: [
        'Ext.MessageBox',
        'Ext.data.Store',
        'Ext.List',
        'Ext.plugin.PullRefresh'
    ],

    launch: function() {
	Ext.create("Ext.tab.Panel", {
	    fullscreen: true,
	    tabBarPosition: 'bottom',

	    items: [{
		    title: 'Home',
		    iconCls: 'home',
		    html: [
			'<center><img src="/senchatouch-notes/resources/startup/320x460.png"/></center>',
			'<h1>]project-open[ Sencha Touch Notes</h1>',
			"<p>This demo shows how to build Sencha Touch applications using ]po[."
		    ].join("")
	     }, {
		    xtype: 'blogList',
	     }, {
		    xtype: 'userList',
	     }, {
		    xtype: 'userNavigationView',
		}, {
                    title: 'Contact',
                    iconCls: 'user',
                    xtype: 'formpanel',
                    url: 'contact.php',
                    layout: 'vbox',

                    items: [{
                            xtype: 'fieldset',
                            title: 'Contact Us',
                            instructions: '(email address is optional)',
                            items: [
                                {
                                    xtype: 'textfield',
                                    label: 'Name'
                                },
                                {
                                    xtype: 'emailfield',
                                    label: 'Email'
                                },
                                {
                                    xtype: 'textareafield',
                                    label: 'Message'
                                }
                            ]
                        },
                        {
                            xtype: 'button',
                            text: 'Send',
                            ui: 'confirm',
                            handler: function() {
                                this.up('formpanel').submit();
                            }
                        }
                    ]
                }


	    ]
	});
    }
});
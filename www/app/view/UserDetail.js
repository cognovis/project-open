Ext.define('PO.view.UserDetail', {
	extend: 'Ext.Panel',
	xtype: 'userDetail',
	config: {

	    styleHtmlContent: true,
	    scrollable: 'vertical',
	    title: 'User Details',
	    tpl: 'Hello, {first_names}'

	}
});

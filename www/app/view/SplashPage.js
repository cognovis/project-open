Ext.define('PO.view.SplashPage', {
	extend: 'Ext.Panel',
	xtype: 'splashPage',
	config: {

		title: 'Home',
		iconCls: 'home',
		scrollable: 'vertical',
		//	    styleHtmlContent: true,
		html: [
			'<center><img src="/senchatouch-notes/resources/startup/320x460.png"/></center>',
			'<h1>]project-open[ Sencha Touch Notes</h1>',
			"<p>This demo shows how to build Sencha Touch applications using ]po[."
		].join("")

	}
});




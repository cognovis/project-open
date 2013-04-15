Ext.define('PO.view.SplashPage', {
	extend: 'Ext.Panel',
	xtype: 'splashPage',
	config: {

		title: 'Home',
		iconCls: 'home',
		scrollable: 'vertical',
		//	    styleHtmlContent: true,
		html: [
			'<br>&nbsp;<br>&nbsp;<br>',
			'<center>',
			'<img src="/senchatouch-notes/resources/startup/project_open.250x91.gif"/>',
			'<br>&nbsp;<br>',
			'<h1>]po[ Sencha Touch Notes</h1>',
			'<br>&nbsp;<br>',
			'<p>This demo shows how to list, update and create notes objects using a ]po[ backend.',
			'</center>',
		].join("")

	}
});




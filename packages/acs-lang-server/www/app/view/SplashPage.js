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
			'<img src="/senchatouch-timesheet/resources/startup/project_open.250x91.gif"/>',
			'<br>&nbsp;<br>',
			'<h1>]po[ Sencha Touch Timesheet</h1>',
			'<br>&nbsp;<br>',
			'<p>This demo shows how to list hierarchical projects and to log hours into a ]po[ backend.',
			'</center>',
		].join("")

	}
});




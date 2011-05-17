<html> 
<head> 
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
	<meta name='generator' lang='en' content='OpenACS version 5.6.0'>
	<title>]project-open[ AJAX Ticket Tracker</title> 

	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>
	<link rel="stylesheet" type="text/css" href="forum.css" /> 

	<script type="text/javascript" src="/intranet-sencha/js/ext-all-debug-w-comments.js"></script> 
	<script type="text/javascript" src="Models.js"></script> 
	<script type="text/javascript" src="ForumList.js"></script> 
	<script type="text/javascript" src="TopicContainer.js"></script> 
	<script type="text/javascript" src="TopicGrid.js"></script> 
	<script type="text/javascript" src="PreviewPlugin.js"></script> 
	<script type="text/javascript" src="Main.js"></script> 

	<script type="text/javascript"> 
		Ext.Loader.setConfig({enabled: true});
		Ext.Loader.setPath('Ext', '/intranet-sencha/');
//		Ext.Loader.setPath('Ext.ux', '/intranet-ticket-tracker/ux/');
		Ext.require([
			'Ext.grid.*',
			'Ext.tree.*',
			'Ext.data.*',
			'Ext.toolbar.*',
			'Ext.tab.Panel',
			'Ext.layout.container.Border'
		]);
		Ext.onReady(function(){
			Ext.QuickTips.init();
			new ForumBrowser.Main();
		});
	</script> 
</head> 
<body> 
</body> 
</html> 


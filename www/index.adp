<html> 
<head> 
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
	<meta name='generator' lang='en' content='OpenACS version 5.6.0'>
	<title>]project-open[ AJAX Ticket Tracker</title> 

	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>
	<link rel="stylesheet" type="text/css" href="ticketbrowser.css" /> 

	<script type="text/javascript" src="/intranet-sencha/js/ext-all-debug-w-comments.js"></script> 
	<script type="text/javascript" src="Models.js"></script> 
	<script type="text/javascript" src="Stores.js"></script> 
	<script type="text/javascript" src="SlaList.js"></script> 
	<script type="text/javascript" src="TicketContainer.js"></script> 
	<script type="text/javascript" src="TicketGrid.js"></script> 
 	<script type="text/javascript" src="Panels.js"></script>
	<script type="text/javascript" src="TicketForm.js"></script> 
	<script type="text/javascript" src="TicketFilterForm.js"></script> 
	<script type="text/javascript" src="TicketFilterAccordion.js"></script> 
	<script type="text/javascript" src="PreviewPlugin.js"></script> 
	<script type="text/javascript" src="Main.js"></script> 

	<script type="text/javascript">
		Ext.Loader.setConfig({enabled: true});
		Ext.Loader.setPath('Ext', '/intranet-sencha/');
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
			new TicketBrowser.Main();
		});
	</script> 
</head> 
<body> 
</body> 
</html> 


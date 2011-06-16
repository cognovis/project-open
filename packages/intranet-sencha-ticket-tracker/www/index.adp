<html> 
<head> 
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
	<meta name='generator' lang='en' content='OpenACS version 5.6.0'>
	<title>]project-open[ AJAX Ticket Tracker</title> 

	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>
	<link rel="stylesheet" type="text/css" href="ticketbrowser.css" /> 

	<!-- ------------------------------- Infrastructure ---------------------------------- -->
	<script type="text/javascript" src="/intranet-sencha/js/ext-all-debug-w-comments.js"></script> 
	<script type="text/javascript" src="Models.js"></script> 
	<script type="text/javascript" src="Stores.js"></script> 
	<script type="text/javascript" src="RowExpander.js"></script> 
	<script type="text/javascript" src="ProjectSlaList.js"></script> 
	<script type="text/javascript" src="AuditGrid.js"></script> 
	<script type="text/javascript" src="FileStorageGrid.js"></script> 

	<!-- ------------------------------- Tickets ---------------------------------------- -->
	<script type="text/javascript" src="TicketContainer.js"></script> 
 	<script type="text/javascript" src="Panels.js"></script>
	<script type="text/javascript" src="TicketActionBar.js"></script> 
	<script type="text/javascript" src="TicketGrid.js"></script> 
	<script type="text/javascript" src="TicketForm.js"></script> 
	<script type="text/javascript" src="TicketFormRight.js"></script> 
	<script type="text/javascript" src="TicketFilterForm.js"></script> 
	<script type="text/javascript" src="TicketContactForm.js"></script> 
	<script type="text/javascript" src="ObjectMemberGrid.js"></script> 
	<script type="text/javascript" src="TicketContactPanel.js"></script> 
	<script type="text/javascript" src="TicketCustomerPanel.js"></script> 
	<script type="text/javascript" src="TicketCompoundPanel.js"></script> 
	<script type="text/javascript" src="TicketPreviewPlugin.js"></script> 

	<!-- ------------------------------- Tickets ---------------------------------------- -->
	<script type="text/javascript" src="CompanyContainer.js"></script> 
	<script type="text/javascript" src="CompanyGrid.js"></script> 
	<script type="text/javascript" src="ContactContainer.js"></script> 
	<script type="text/javascript" src="ContactGrid.js"></script> 

	<script type="text/javascript" src="MainPanel.js"></script> 

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


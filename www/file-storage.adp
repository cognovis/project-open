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
	<script type="text/javascript" src="FileStorageGrid.js"></script>


        <script type="text/javascript">
                Ext.Loader.setConfig({enabled: true});
                Ext.Loader.setPath('Ext', '/intranet-sencha/');
                Ext.Loader.setPath('Ext.ux', '/intranet-sencha/ext-4.0.0/examples/ux');
                Ext.require([
			'Ext.ux.RowExpander',
			'Ext.selection.CheckboxModel',
                        'Ext.grid.*',
                        'Ext.tree.*',
                        'Ext.data.*',
                        'Ext.toolbar.*',
                        'Ext.tab.Panel',
                        'Ext.layout.container.Border'
                ]);


	</script>

</head> 
<body> 
    <h1>Grid Plugins Examples</h1> 
    <p>This example demonstrates several plugins.  Note that the js is not minified so it is readable.
    See <a href="grid-plugins.js">grid-plugins.js</a>.</p> 

<div id="file-storage"></div>

</body> 
</html> 


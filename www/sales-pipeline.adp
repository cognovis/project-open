<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<link rel='stylesheet' href='/intranet-sencha/css/example.css' type='text/css' media='screen'>
	<script type="text/javascript" src="/intranet-sencha/js/bootstrap.js"></script>
	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>
<!--	
	Uncomment this line and remove the line above (bootstrap.js) in order to enable JS debugging.
	<script type="text/javascript" src="/intranet-sencha/js/ext-all-debug-w-comments.js"></script> 
-->
</head>

<body id="docbody">
<script type="text/javascript">

Ext.define('PipelineModel', {
	extend: 'Ext.data.Model',
	fields: ['project_status', 'value']
});


Ext.onReady(function(){
    var store = Ext.create('Ext.data.Store', {
	autoLoad:			true,
	model:				'PipelineModel',
	proxy: {
		type:			'rest',
		url:			'/intranet-reporting/view',
		extraParams:		{format: 'json', report_code: 'rest_presales_pipeline'},
		reader:			{type: 'json', root: 'data'}
	}
    });

    var win = Ext.create('Ext.Window', {
	width:				400,
	height:				300,
	hidden:				false,
	title:				'Presales Pipeline',
	renderTo:			Ext.getBody(),
	layout:				'fit',
	items: {
		xtype:			'chart',
		animate:		true,
		shadow:			true,
		store:			store,
		axes: [{
			type:			'Numeric',
			position:		'bottom',
			fields:			['value'],
			label:			{renderer: Ext.util.Format.numberRenderer('0,0')},
			title:			'Value',
			grid:			true,
			minimum:		0
		}, {
			type:			'Category',
			position:		'left',
			fields:			['project_status'],
			title:			'Project Status'
		}],
		series: [{		
			type:			'bar',
			axis:			'bottom',
			highlight:		true,
			xField:			'category',
			yField:			['value']
		}]
	}
    });

});
</script>


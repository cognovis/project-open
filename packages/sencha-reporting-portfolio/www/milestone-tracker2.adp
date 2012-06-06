<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <title>Milestone Tracker</title>
    <link rel="stylesheet" type="text/css" href="/sencha-v407/ext-all.css" />
    <link rel="stylesheet" type="text/css" href="/sencha-v407/examples/shared/example.css" />
    <script type="text/javascript" src="/sencha-v407/ext-all-debug-w-comments.js"></script>
</head>
<body id="docbody">
<h1>Milestone Tracker</h1>
<div id=milestone_tracker_41290226></div>
<script type='text/javascript'> 

Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);
Ext.require(['Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store = Ext.create('Ext.data.JsonStore', {
        fields: ['date', 'm18232'],
        data: [
	   {date: '2010-07', m18232: 383},
	   {date: '2011-02', m18232: 343},
	   {date: '2012-04', m18232: 310}	
	]
    });
 
Ext.onReady(function () {
    
    chart = new Ext.chart.Chart({
        width: 600,
        height: 400,
        animate: false,
        store: store,
        renderTo: 'milestone_tracker_41290226',
        legend: { position: 'right' },
        axes: [{
                type: 'Numeric',
                position: 'left',
		fields: ['m18232'],
                minimum: 0,
                maximum: 400
        }, {
                type: 'Category',
                position: 'bottom',
                fields: 'date'
        }],
	series: [{
                type: 'line',
                axis: 'left',
		highlight: true,
                xField: 'date',
                yField: 'm18232',
                markerConfig: { type: 'circle', radius: 5, size: 5 }
	}]
    }
)});
</script> 

</body>
</html>


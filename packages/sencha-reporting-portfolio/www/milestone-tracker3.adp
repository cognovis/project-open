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
        fields: ['date', 'm18232', 'm18239', 'm18245'],
        data: [
             {date: new Date(2010, 06, 19), m18232: 3, m18239: 336, m18245: 69, m27466: 362},
             {date: new Date(2011, 02, 07), m18232: 383, m18239: 336, m18245: 69, m27466: 0},
             {date: new Date(2012, 04, 03), m18232: 310, m18239: 198, m18245: 349, m27466: 114}
	]
    });
 
Ext.onReady(function () {
    
    chart = new Ext.chart.Chart({
        width: 600,
        height: 400,
        animate: false,
        store: store,
        renderTo: 'milestone_tracker_41290226',
//        legend: { position: 'right' },
        axes: [{
                type: 'Numeric',
                position: 'left',
		fields: ['m18232'],
                minimum: 0,
                maximum: 400
        }, {
	    type: 'Time',
	    position: 'bottom',
	    fields: 'date',
    	    title: 'Day',
    	    dateFormat: 'Y M',
	    groupBy: 'year,month,day',
            aggregateOp: 'sum',
    	    constrain: false,
//	    majorTickSteps: 8,
	    step: [Ext.Date.MONTH, 3],
    	    fromDate: new Date(2010, 1, 1),
    	    toDate: new Date(2013, 1, 1)
        }],
	series: [{
                type: 'line',
                axis: ['left','bottom'],
		highlight: true,
                xField: 'date',
                yField: 'm18232',
                markerConfig: { radius: 5, size: 5 }
	}]
    }
)});
</script> 

</body>
</html>


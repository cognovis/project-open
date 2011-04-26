
<div id=@diagram_id@></div>

<script type='text/javascript'>

Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store1 = Ext.create('Ext.data.JsonStore', {
        fields: ['x_axis', 'y_axis'],
        data: @data_json;noquote@
    });


Ext.onReady(function () {
    
    chart = new Ext.chart.Chart({
        width: 200,
        height: 200,
        animate: false,
        store: store1,
        renderTo: '@diagram_id@',
	axes: [{
	    type: 'Numeric',
	    position: 'left',
	    fields: ['y_axis'],
	    grid: true
	}, {
	    type: 'Numeric',
	    position: 'bottom',
	    fields: ['x_axis']
	}],
	series: [{
	    type: 'scatter',
	    axis: 'left',
	    xField: 'x_axis',
	    yField: 'y_axis',
	    markerConfig: {
		type: 'circle',
		size: 5
	    }
	}]
    }
)});

	    
</script>


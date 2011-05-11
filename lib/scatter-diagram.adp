<div id=@diagram_id@></div>
<script type='text/javascript'>
Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store1 = Ext.create('Ext.data.JsonStore', {
        fields: ['x_axis', 'y_axis', 'color', 'diameter', 'caption'],
        data: @data_json;noquote@
    });

    function createHandler(fieldName) {
        return function(sprite, record, attr, index, store) {
            return Ext.apply(attr, {
                radius: record.get('diameter'),
                fill: record.get('color')
            });
        };
    }

Ext.onReady(function () {
    
    chart = new Ext.chart.Chart({
        width: 200,
        height: 200,
        animate: true,
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
	    highlight: true,
	    renderer: createHandler('xxx'),
	    label: {
                display: 'middle',
                field: 'caption',
                'text-anchor': 'middle',
                contrast: true
            },
	    markerConfig: {
		type: 'circle'
	    }
	}]
    }
)});
</script>


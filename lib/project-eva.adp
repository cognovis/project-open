<if @show_diagram_p@>

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
    
    var fields = [@project_json;noquote@];

    chart = new Ext.chart.Chart({
        width: @diagram_width@,
        height: @diagram_height@,
        animate: false,
        store: store1,
        renderTo: '@diagram_id@',
	legend: { position: 'right' },
	axes: [{
	    type: 'Numeric',
	    position: 'left',
	    fields: fields,
	    grid: true
	}, {
	    type: 'Category',
	    position: 'bottom',
	    fields: ['date']
	}],
	series: [{
	    type: 'area',
	    axis: 'left',
	    xField: 'name',
	    yField: fields,
	    highlight: true
	}]
    }
)});
</script>

</if>


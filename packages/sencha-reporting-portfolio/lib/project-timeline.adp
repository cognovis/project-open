<div id=@diagram_id@></div>
<script type='text/javascript'>
Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store_@diagram_id@ = Ext.create('Ext.data.JsonStore', {
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
    
    var object_fields = [@object_fields_json;noquote@];
    var all_fields = [@all_fields_json;noquote@];

    chart = new Ext.chart.Chart({
        width: @diagram_width@,
        height: @diagram_height@,
        animate: false,
        store: store_@diagram_id@,
        renderTo: '@diagram_id@',
	legend: { position: 'right' },
	axes: [{
	    type: 'Numeric',
	    position: 'left',
	    fields: all_fields,
	    grid: true
	}, {
	    type: 'Category',
	    position: 'bottom',
	    fields: ['date'],
	    label: { rotate: { degrees: 315 } }	
	}],
	series: [
<if "" ne @diagram_availability@>
	{
            type: 'line',
            title: 'Available Resources',
            axis: 'left',
            smooth: true,
            fill: false,
            xField: 'date',
            yField: 'availability',
            markerConfig: {
                    type: 'circle',
                    size: 1,
                    fill: 'red'
            }
        }, 
</if>
	{
	    type: 'area',
	    axis: 'left',
	    xField: 'name',
	    yField: object_fields,
	    highlight: true
	}]
    }
)});
</script>

<if @object_count@ ge 1>
</if>


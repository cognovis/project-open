<if @project_count@ ge 2>

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
        width: @diagram_width@,
        height: @diagram_height@,
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
	    markerConfig: { type: 'circle' },
	    renderer: createHandler('xxx'),
	    label: {
                display: 'under',
                field: 'caption',
                'text-anchor': 'left',
		color: '#000'
            },
	    tips: {
	        trackMouse: false,
		anchor: 'right',
  		width: 120,
  		height: 25,
  		renderer: function(storeItem, item) {
  		    this.setTitle(storeItem.get('x_axis') + ' / ' + storeItem.get('y_axis'));
 	        }
            }
	}]
    }
)});
</script>

</if>


<if @show_diagram_p@>

<div id=@diagram_id@></div>
<script type='text/javascript'>
Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store1 = Ext.create('Ext.data.JsonStore', {
        fields: ['date', 'planned_work', 'planned_work_accumulated' @attributes_js;noquote@],
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
    
    var fields = [@fields_json;noquote@];

    chart = new Ext.chart.Chart({
        width: @diagram_width@,
        height: @diagram_height@,
        animate: false,
        store: store1,
        renderTo: '@diagram_id@',
	legend: { position: 'right' },
	axes: [{
	    type: 'Numeric',
	    title: 'Value',
	    position: 'left',
	    fields: ['planned_work', 'planned_work_accumulated', 'reported_hours_cache'],
	    grid: true
	}, {
	    type: 'Category',
	    title: 'Date',
	    position: 'bottom',
	    fields: ['date']
	}],
	series: [{
	    type: 'area',
	    axis: 'left',
	    xField: 'date',
	    yField: fields,
	    highlight: true
	}, {
	    type: 'scatter',
	    axis: 'left',
	    xField: 'date',
	    yField: 'planned_work_accumulated',
	    markerConfig: {
                    type: 'circle',
                    size: 5
            }
	}, {
	    type: 'line',
	    title: 'Planned Value',
	    axis: 'left',
	    smooth: true,
	    fill: true,
	    xField: 'planned_work_accumulated',
	    yField: 'planned_work_accumulated',
	    markerConfig: {
                    type: 'circle',
                    size: 5,
		    fill: 'red'
            }
	}, {
	    type: 'line',
	    title: 'Logged Hours',
	    axis: 'left',
	    xField: 'reported_hours_cache',
	    yField: 'reported_hours_cache',
	    markerConfig: {
                    type: 'circle',
                    size: 5,
		    fill: 'blue'
            }
	}, {
	    type: 'line',
	    title: 'Expenses',
	    axis: 'left',
	    xField: 'cost_expense_logged_cache',
	    yField: 'cost_expense_logged_cache',
	    markerConfig: {
                    type: 'circle',
                    size: 5,
		    fill: 'yellow'
            }
	}]
    }
)});
</script>

</if>

<!--
	}, {
	    type: 'column',
	    axis: 'left',
	    xField: 'date',
	    yField: 'planned_work_accumulated'
-->
<!--
	}, {
	    type: 'column',
	    axis: 'left',
	    xField: 'date',
	    yField: 'planned_work_accumulated'


	}, {
	    type: 'scatter',
	    axis: 'left',
	    xField: 'date',
	    yField: 'planned_work_accumulated',
	    markerConfig: {
                    type: 'circle',
                    size: 5,
		    fill: 'green'
            }

-->

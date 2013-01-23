<if "" ne @data_list@>
<div id=@diagram_id@></div>
<script type='text/javascript'>

Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store = Ext.create('Ext.data.JsonStore', {
        fields: @fields_json;noquote@,
        data: @data_json;noquote@
    });

Ext.onReady(function () {
    
    chart = new Ext.chart.Chart({
        width: @diagram_width@,
        height: @diagram_height@,
        animate: false,
        store: store,
        renderTo: '@diagram_id@',
        axes: [{
                type: 'Numeric',
                position: 'left',
		fields: [@fields_joined;noquote@],
                minimum: 0,
                maximum: 100
        }, {
                type: 'Time',
                position: 'bottom',
                fields: 'date',
                dateFormat: 'M d',
                groupBy: 'year,month,day',
                aggregateOp: 'sum',
                constrain: true,
                fromDate: @audit_start_date_js;noquote@,
                toDate: @audit_end_date_js;noquote@
        }],
	series: [{
                type: 'line',
                axis: 'left',
		highlight: true,
                xField: 'date',
                yField: 'm18232',
                markerConfig: {
			type: 'circle',
			radius: 5,
			size: 5
                }

	}]
    }
)});
</script>
</if>


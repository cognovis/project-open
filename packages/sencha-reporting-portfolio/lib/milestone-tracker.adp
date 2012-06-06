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
	width: 600,
	height: 300,
	animate: false,
	store: store,
	renderTo: '@diagram_id@',
	legend: { position: 'right' },
	axes: [{
		type: 'Time',
		position: 'left',
		fields: [@fields_joined;noquote@],
		dateFormat: 'M Y',
		constrain: false,
		step: [Ext.Date.MONTH, 2],
		fromDate: @y_axis_min_date_js;noquote@,
		toDate: @y_axis_max_date_js;noquote@,
	}, {
		type: 'Time',
		position: 'bottom',
		fields: 'date',
		dateFormat: 'M Y',
		constrain: false,
		step: [Ext.Date.MONTH, 2],
		fromDate: @audit_start_date_js;noquote@,
		toDate: @audit_end_date_js;noquote@
	}],
	series: [@series_json@]
    }
)});
</script>
</if>


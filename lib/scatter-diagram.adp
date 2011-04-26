
<div id=@diagram_id@></div>

<script type='text/javascript'>

Ext.require(['Ext.chart.*', 'Ext.Window', 'Ext.fx.target.Sprite', 'Ext.layout.container.Fit']);

    window.store1 = Ext.create('Ext.data.JsonStore', {
        fields: ['x_axis', 'y_axis'],
        data: @data_json;noquote@
    });


Ext.onReady(function () {

    var win = Ext.create('Ext.Window', {
        width: 200,
        height: 200,
        hidden: false,
	floating: false,
	draggable: false,
        maximizable: true,
        title: '@title;noquote@',
        renderTo: @diagram_id@,
        layout: 'fit',
        items: {
            id: 'chartCmp',
            xtype: 'chart',
            style: 'background:#fff',
            animate: false,
            theme: 'Category1',
            store: store1,
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
    });
});

</script>


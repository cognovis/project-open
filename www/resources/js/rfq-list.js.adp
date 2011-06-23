// General Settings

Ext.Loader.setConfig({
    enabled: true
});

// set local blank image 
Ext.BLANK_IMAGE_URL = '/intranet/images/cleardot.gif';

Ext.require([
    'Ext.form.field.File',
    'Ext.form.Panel',
    'Ext.window.MessageBox',
    'Ext.selection.CellModel',
    'Ext.grid.*',
    'Ext.data.*',
    'Ext.util.*',
    'Ext.state.*',
    'Ext.form.*'
]);


Ext.onReady(function(){

	// ************** Grid Inquiries:  *** //

	Ext.define('listRFQ', {
	    extend: 'Ext.data.Model',
	    fields: [
        	{name: 'id', type: 'number'},
        	{name: 'inquiry_id', type: 'string'},
	        {name: 'title', type: 'string'},
	        {name: 'inquiry_date',  type: 'date', dateFormat: 'Y-m-d'},
        	{name: 'status_id',  type: 'string'},
		{name: 'cost_name', type: 'string' },
                {name: 'amount', type: 'string', },
                {name: 'currency', type: 'string' },
                {name: 'action_column', type: 'string'}

	    ]
	});

	var rfqCustomerPortalStore = new Ext.data.Store({
	    autoLoad: true,
	    model: 'listRFQ',
	    proxy: {
        	type: 'ajax',
	        url: '/intranet-customer-portal/get-list-rfq',
        	reader: {
	            type: 'json',
        	    root: 'rfq'
	        }
	    }
	});
	
	var grid = Ext.create('Ext.grid.Panel', {
		renderTo: 'gridRFQ',
		store: rfqCustomerPortalStore,
		width: 620,	
		height: 300,
		columns: [
        	    {header: "No", width: 40, dataIndex: 'id', sortable: true},
        	    {header: "Inquiry ID", width: 40, dataIndex: 'inquiry_id', sortable: true,hidden: true, hideable: false },
        	    {header: "Title", width: 200, dataIndex: 'title', sortable: true},
        	    {header: "Date inquired", width: 80, dataIndex: 'inquiry_date', sortable: true, renderer: Ext.util.Format.dateRenderer('d-M-Y')},
        	    // {header: "Status", width: 50, dataIndex: 'status_id', sortable: true},
        	    {header: "Status", width: 100, dataIndex: 'cost_name', sortable: true},
        	    {header: "Amount", width: 60, dataIndex: 'amount', sortable: true, align: 'right'},
        	    {header: "Currency", width: 60, dataIndex: 'currency', sortable: true, align: 'left'},
        	    {header: "Action", width: 60, dataIndex: 'action_column', sortable: true}
        	]
	});
	// rfqCustomerPortalStore.load();
});









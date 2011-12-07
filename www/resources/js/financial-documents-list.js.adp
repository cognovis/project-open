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

	Ext.define('listFinancialDocuments', {
	    extend: 'Ext.data.Model',
	    fields: [
        	{name: 'id', type: 'number'},
	        {name: 'title', type: 'string'},
	        {name: 'doc_date',  type: 'date', dateFormat: 'Y-m-d'}, 
        	{name: 'status_id',  type: 'string'},
                {name: 'amount', type: 'string'},
                {name: 'currency', type: 'string'},
                {name: 'project_nr', type: 'string'}
	    ]
	});

	var financialDocumentStore = new Ext.data.Store({
	    model: 'listFinancialDocuments',
	    pageSize: 50,
	    proxy: {
        	type: 'ajax',
	        url: '/intranet-customer-portal/financial-document-store',
        	reader: {
	            type: 'json',
        	    root: 'docs',
		    totalProperty: 'totalCount'
	        }, 
		simpleSortMode: true
	    },
	    sorters: [{
            	property: 'doc_date',
	        direction: 'DESC'
            }]
	})
	
	financialDocumentStore.load({
        	params: {
            		start: 0,
		        limit: 50
       		}
   	});

	var gridPanelDocs = Ext.create('Ext.grid.Panel', {
		renderTo: 'gridFinancialDocuments',
		store: financialDocumentStore,
		remoteSort: true,
		width: 685,	
		height: 200,
		columns: [
        	    {header: "No", width: 80, dataIndex: 'id', sortable: true},
        	    {header: "Title", width: 120, dataIndex: 'title', sortable: true},
        	    {header: "Date created", width: 80, dataIndex: 'doc_date', sortable: true, renderer: Ext.util.Format.dateRenderer('d-M-Y')},
        	    {header: "Status", width: 100, dataIndex: 'status_id', sortable: true},
        	    {header: "Amount", width: 100, dataIndex: 'amount', sortable: true, align: 'right'},
        	    {header: "Currency", width: 60, dataIndex: 'currency', sortable: true, align: 'left'},
        	    {header: "Project No.", width: 130, sortable: true, dataIndex: 'project_nr'}
        	],
		bbar: Ext.create('Ext.PagingToolbar', {
			store: financialDocumentStore,
		        displayInfo: true,
		        displayMsg: 'Displaying topics {0} - {1} of {2}',
			emptyMsg: "No topics to display"
		        /*
		        items:[
		                '-', {
                		text: 'Show Preview',
		                pressed: pluginExpanded,
		                enableToggle: true,
		                toggleHandler: function(btn, pressed) {
		                var preview = Ext.getCmp('gv').getPlugin('preview');
                		preview.toggleExpanded(pressed);
                		}
            		}]
			*/
        	})
	});
});









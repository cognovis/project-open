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


// create namespace
Ext.namespace('RFQPortlet');

RFQPortlet.app = function() {


   return {
    // public properties, e.g. strings to translate

    // public methods
    init: function() {

	// ************** Grid Inquiries:  *** //

	Ext.define('listRFQ', {
	    extend: 'Ext.data.Model',
	    fields: [
        	{name: 'id', type: 'number'},
        	{name: 'inquiry_id', type: 'string'},
	        {name: 'title', type: 'string'},
	        {name: 'inquiry_date',  type: 'date', dateFormat: 'Y-m-d'},
        	{name: 'status_id',  type: 'string'},
		{name: 'company_name', type: 'string'},
		{name: 'cost_name', type: 'string'},
                {name: 'amount', type: 'string'},
                {name: 'currency', type: 'string'},
                {name: 'action_column', type: 'string'},
                {name: 'project_id', type: 'number'}
	    ]
	});

	var rfqCustomerPortalStore = new Ext.data.Store({
	    autoLoad: true,
	    model: 'listRFQ',
	    proxy: {
        	type: 'ajax',
	        url: '/intranet-customer-portal/rfqCustomerPortalStore',
        	reader: {
	            type: 'json',
        	    root: 'rfq'
	        }
	    }
	});
	
	var gridPanel = Ext.create('Ext.grid.Panel', {
		renderTo: 'gridRFQ',
		store: rfqCustomerPortalStore,
		width: 730,	
		height: 200,
		columns: [
        	    {header: "No", width: 40, dataIndex: 'id', sortable: true},
        	    {header: "Inquiry ID", dataIndex: 'inquiry_id',hidden: true},
        	    {header: "Title", width: 200, dataIndex: 'title', sortable: true},
		    // {header: "Company", width: 150, dataIndex: 'company_name', sortable: true},
        	    {header: "Date inquired", width: 80, dataIndex: 'inquiry_date', sortable: true, renderer: Ext.util.Format.dateRenderer('d-M-Y')},
        	    // {header: "Status", width: 50, dataIndex: 'status_id', sortable: true},
        	    {header: "Status", width: 100, dataIndex: 'status_id', sortable: true},
        	    {header: "Quote", width: 100, dataIndex: 'cost_name', sortable: true},
        	    {header: "Amount", width: 60, dataIndex: 'amount', sortable: true, align: 'right'},
        	    {header: "Currency", width: 60, dataIndex: 'currency', sortable: true, align: 'left'},
        	    {header: "Project Id", dataIndex: 'project_id',hidden: true},
            	    {
	                xtype: 'actioncolumn',
			header: 'Accept/Reject',
        	        width: 90,
			dataIndex: 'action_column',
                	items: [{
	                    icon   : '/resources/themes/images/default/dd/drop-yes.gif',  // Use a URL in the icon config
        	            tooltip: 'Accept Quote',
                	    handler: function(grid, rowIndex, colIndex) {
                        	var rec = gridPanel.getStore().getAt(rowIndex);
 				clickHandlerCustomerDecisionQuote(rec.get('inquiry_id'), rec.get('project_id'),'accept');
		                Ext.Msg.show({
					title: '', 
					msg:'Thanks for your order.',
                                        closable:true
				});
				rfqCustomerPortalStore.load();
	       	            }, 
                    	    getClass: function(v, meta, rec) {          // Or return a class from a function
	                        if ( rec.get('action_column') == '') {
				    return 'action-column-icon-hide';
                        	} 
                    	    }
                	}, {
                            icon   : '/resources/themes/images/default/dd/drop-no.gif',  // Use a URL in the icon config
                            tooltip: 'Reject Quote',
                            handler: function(grid, rowIndex, colIndex) {
                                var rec = gridPanel.getStore().getAt(rowIndex);
                                clickHandlerCustomerDecisionQuote(rec.get('inquiry_id'), rec.get('project_id'),'reject');
		                Ext.Msg.show({
					title:'', 
					msg: 'We are sorry to be unable to meet your expectations',
					closable:true
				});
				rfqCustomerPortalStore.load();
                            },
                            getClass: function(v, meta, rec) {          // Or return a class from a function
                                if ( rec.get('action_column') == '') {
                                    return 'action-column-icon-hide';
                                }
                            }
                        }]
		    }
        	]
	});

	// rfqCustomerPortalStore.load();

        var clickHandlerCustomerDecisionQuote = function(inquiry_id, project_id, decision) {
		sParams = {inquiry_id: inquiry_id, project_id: project_id, decision: decision};
		Ext.Ajax.request({
                	url: '/intranet-customer-portal/xhr-handle-customer-decision-quote',
			method: 'POST',
			params: sParams,
			success: function(o) {
				if (o.responseText == 0) {
					field.markInvalid('Email already in use, please login');
				}
			}
		});
        };

   } // end of init

  };

}(); // end of app;

Ext.onReady(RFQPortlet.app.init, RFQPortlet.app);









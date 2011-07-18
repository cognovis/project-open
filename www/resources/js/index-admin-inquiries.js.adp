// General Settings

Ext.Loader.setConfig({
    enabled: true
});

var todays_date = Date();

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

       Ext.define('CustomerPortal.Category', {
            extend: 'Ext.data.Model',
            idProperty: 'category_id',          // The primary key of the category

            fields: [
                {type: 'string', name: 'category_id'},
                {type: 'string', name: 'tree_sortkey'},
                {type: 'string', name: 'category'},
                {type: 'string', name: 'category_type'},
                {type: 'string', name: 'category_translated'},
		{type: 'string', name: 'indent_class',
                // Determine the indentation level for each element in the tree
                convert: function(value, record) {
                        var     category = record.get('category_translated');
                        var     indent = (record.get('tree_sortkey').length / 8) - 1;
                        // return 'extjs-indent-level-' + indent;
                        return 'extjs-indent-level-' + indent;

                }
                }
            ]
        });

        Ext.define('PO.data.CategoryStore', {
                extend: 'Ext.data.Store',
                category_from_id: function(category_id) {
                        if (null == category_id || '' == category_id) { return ''; }
                        var     result = 'Category #' + category_id;
                        var     rec = this.findRecord('category_id',category_id);
                        if (rec == null || typeof rec == "undefined") { return result; }
                        return rec.get('category_translated');
                }
        });

        var projectTypeStore = Ext.create('PO.data.CategoryStore', {
                storeId:        'projectType',
                remoteFilter:   true,
                autoLoad:       true,
                model: 'CustomerPortal.Category',
                proxy: {
                        type: 'rest',
                        url: '/intranet-rest/im_category',
                        appendId: true,
                        extraParams: {
                                format: 'json',
                                category_type: '\'Intranet Project Type\''
                        },
                        reader: { type: 'json', root: 'data' }
                }
        });


	// ************** Grid Inquiries:  *** //

	Ext.define('listInquiries', {
	    extend: 'Ext.data.Model',
	    fields: [
        	{name: 'inquiry_id', type: 'string'},
	        {name: 'name', type: 'string'},
        	{name: 'email', type: 'string'},
	        {name: 'company_name',  type: 'string'},
        	{name: 'phone',  type: 'string'},
		{name: 'prospect_project_type'}
	    ]
	});

	var inquiriesCustomerPortalStore = new Ext.data.Store({
	    autoLoad: true,
	    model: 'listInquiries',
	    proxy: {
        	type: 'ajax',
	        url: '/intranet-customer-portal/get-inquiries.tcl',
        	reader: {
	            type: 'json',
        	    root: 'inquiries'
	        }
	    }
	});
	

	var cellEditing = Ext.create('Ext.grid.plugin.CellEditing', {
	        clicksToEdit: 1
	});

	var grid = Ext.create('Ext.grid.Panel', {
		renderTo: 'gridInquiries',
		store: inquiriesCustomerPortalStore,
		width: 700,
		height: 300,
		columns: [
        	    {header: "ID", width: 25, dataIndex: 'inquiry_id', sortable: true},
        	    {header: "Name", width: 150, dataIndex: 'name', sortable: true},
        	    {header: "Email", width: 100, dataIndex: 'email', sortable: true},
        	    {header: "Company", width: 100, dataIndex: 'company_name', sortable: true},
        	    {header: "Phone", width: 100, dataIndex: 'phone', sortable: true},
        	    {	header: 'Project Type', 
			dataIndex: 'prospect_project_type', 
			width: 200, 
			field: {
		                xtype: 'combobox',
		                // valueField:     'category_id',
		                valueField:     'category_translated',
                		displayField:   'category_translated',
		                typeAhead: true,
	       	        	triggerAction: 'all',
	        	        selectOnTab: true,
 				store: projectTypeStore,
		                listConfig: {
                		        getInnerTpl: function() {
                                		return '<div class={indent_class}>{category_translated}</div>';
                        		}
                		},
        		        lazyRender: true,
                		listClass: 'x-combo-list-small',
	/*
		                listeners: {
                		        // 'change': function(field, values) { if (null == values) { this.reset(); }},
		                        // 'keypress': function(field, key) { if (13 == key.getCharCode()) { this.ownerCt.onSearch(); } }
                		}
*/
			}
		   }
        	],
          	selModel: {
	            selType: 'cellmodel'
       	 	},
		frame: true,
		plugins: [cellEditing]
	});

	inquiriesCustomerPortalStore.load();

       // ************** Panel: UploadedFiles *** //

        // ************** Panel: UploadedFiles Data Grid*** //

        Ext.define('UploadedFiles', {
            extend: 'Ext.data.Model',
            fields: [
                {name: 'inquiry_files_id', type: 'string'},
                {name: 'file_name', type: 'string'},
                {name: 'source_language', type: 'string'},
                {name: 'target_language',  type: 'string'},
                {name: 'deliver_date',  type: 'string'}
            ]
        });

        var uploadedFilesStore = new Ext.data.Store({
            model: 'UploadedFiles',
            proxy: {
                type: 'ajax',
                url: '/intranet-customer-portal/get-uploaded-files',
                reader: {
                    type: 'json',
                    root: 'files'
                }
            }
        });

        var grid = new Ext.grid.GridPanel({
                renderTo: 'gridUploadedFiles',
                store: uploadedFilesStore,
                width: 600,
                height: 300,
                columns: [
                    {header: "ID", width: 25, dataIndex: 'inquiry_files_id', sortable: true},
                    {header: "File", width: 150, dataIndex: 'file_name', sortable: true},
                    {header: "Source Language", width: 100, dataIndex: 'source_language', sortable: true},
                    {header: "Target Languages", width: 100, dataIndex: 'target_language', sortable: true},
                    {header: "Delivery Date", width: 100, dataIndex: 'deliver_date', sortable: true}
                ]
        });

        // uploadedFilesStore.load();
});









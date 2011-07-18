
// General Settings

// set local blank image 
Ext.BLANK_IMAGE_URL = '/intranet/images/cleardot.gif';

Ext.require([
    'Ext.form.field.File',
    'Ext.form.Panel',
    'Ext.window.MessageBox'
]);


Ext.onReady(function(){

	function renderLink(val, meta, rec) {
		var file_id = rec.get('inquiry_files_id');
		return '<a href="/intranet-customer-portal/get-file?file_id=' + file_id + ' "' + val + '">'+ val +'</a>';
	}

	// ************** Panel: UploadedFiles Data Grid*** //

	Ext.define('UploadedFiles', {
	    extend: 'Ext.data.Model',
	    fields: [
        	{name: 'inquiry_files_id', type: 'string'},
	        {name: 'file_name', type: 'string'},
        	{name: 'source_language', type: 'string'},
	        {name: 'target_languages',  type: 'string'},
        	{name: 'deliver_date',  type: 'string'}
	    ]
	});

	uploadedFilesStore = new Ext.data.Store({
	    autoLoad: true,
	    model: 'UploadedFiles',
	    proxy: {
        	type: 'ajax',
	        url: '/intranet-customer-portal/get-uploaded-files?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote@',
        	reader: {
	            type: 'json',
        	    root: 'files',
		    totalProperty: 'totalCount'

	        }
	    }
	});
	
	var grid = new Ext.grid.GridPanel({
		renderTo: 'grid_uploaded_files',
		store: uploadedFilesStore,
		width: 600,
		height: 300,
		columns: [
        	    {header: "ID", width: 40, dataIndex: 'inquiry_files_id', sortable: true},
        	    {header: "File", width: 100, dataIndex: 'file_name', sortable: true, renderer: renderLink },
        	    {header: "Source Language", width: 100, dataIndex: 'source_language', sortable: true},
        	    {header: "Target Languages", width: 200, dataIndex: 'target_languages', sortable: true},
        	    {header: "Expected Delivery Date", width: 150, dataIndex: 'deliver_date', sortable: true}
        	]
	});
	console.log('total:' + uploadedFilesStore.totalProperty);
});









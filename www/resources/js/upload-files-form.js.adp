// General Settings

var todays_date = Date();

// set local blank image 
Ext.BLANK_IMAGE_URL = '/intranet/images/cleardot.gif';

// SuperSelectBox Target Language
var tempIdCounter = 0;

Ext.require([
    'Ext.form.field.File',
    'Ext.form.Panel',
    'Ext.window.MessageBox'
]);


Ext.onReady(function(){

	var transformed = Ext.create('Ext.form.field.ComboBox', {
	    renderTo: 'source_language_placeholder',
	    typeAhead: true,
	    transform: 'source_language_id',
	    // width: 135,
	    forceSelection: true,
	    fieldLabel: 'Source Language',
	    labelAlign: 'left',
	    labelWidth: 150              
	});

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
        	    root: 'files'
	        }
	    }
	});
	
	var grid = new Ext.grid.GridPanel({
		renderTo: 'grid_uploaded_files',
		store: uploadedFilesStore,
		width: 600,
		height: 300,
		columns: [
        	    {header: "ID", width: 25, dataIndex: 'inquiry_files_id', sortable: true},
        	    {header: "File", width: 100, dataIndex: 'file_name', sortable: true},
        	    {header: "Source Language", width: 100, dataIndex: 'source_language', sortable: true},
        	    {header: "Target Languages", width: 200, dataIndex: 'target_languages', sortable: true},
        	    {header: "Delivery Date", width: 100, dataIndex: 'deliver_date', sortable: true}
        	]
	});

	// uploadedFilesStore.load();


        // ************** Target Language *** //

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

        var targetLanguageStore = Ext.create('PO.data.CategoryStore', {
                storeId:        'targetLanguageStore',
                remoteFilter:   true,
                autoLoad:       true,
                model: 'CustomerPortal.Category',
                proxy: {
                        type: 'rest',
                        // url: '/intranet-rest/im_category',
                        url: '/intranet-customer-portal/target-languages.txt',
                        appendId: true,
                        extraParams: {
                                format: 'json',
                                category_type: '\'Intranet Translation Language\''
                        },
                        reader: { type: 'json', root: 'data' }
                }
        });


        targetLanguageForm = new Ext.FormPanel({
            id:                 'targetLanguageForm_id',
            renderTo:           'form_target_languages',
            autoHeight:         true,
            // width:              400,
            height:             50,
            // standardsubmit:     true,
            // bodyStyle: 'padding: 0px 10px 0px 10px;',
		
            items: [{
                id: 'target_language_id',
                // name: 'target_language_id',
                width: 700,
		xtype: 'boxselect',
		fieldLabel: 'Target Languages',
		labelAlign: 'left',
		labelWidth: 150,
                valueField: 'category_id',
		hiddenName: 'target_language_ids',
                displayField: 'category_translated',
                forceSelection: true,
                queryMode: 'remote',
                store: targetLanguageStore,
		listeners: {
		    change: function(targetLanguageForm, value){
		    	var record = targetLanguageForm.findRecord('category_id', value);
			// this.findField('target_language_ids').setValue(record ? record.get('category_id') : '');
			// targetLanguageForm.findField('target_language_ids').setValue(record ? record.get('category_id') : '');
    		    }
  		},
                listConfig: {
                        getInnerTpl: function() {
                                return '<div class={indent_class}>{category_translated}</div>';
                        }
                }
            }]
        });


        // ************** Upload Form *** //

	myuploadform = new Ext.FormPanel({
		renderTo: 'upload_file_placeholder',
                fileUpload: true,
                width: 600,
                autoHeight: true,
                labelWidth: 150,
                defaults: {
                    anchor: '95%',
                    allowBlank: false,
                    msgTarget: 'side'
                },
                items:[
                 {
                    xtype: 'fileuploadfield',
		    id: 'upload_file',
		    name:  'upload_file',
                    // emptyText: 'Select a document to upload...',
		    labelAlign: 'left',
		    fieldLabel: 'File to translate',
		    labelWidth: 150,
                    buttonText: 'Browse',
                    width: 300
                 }
		]
        });


	// ************** Date Picker *** // 

	input_delivery_date = new Ext.form.Date({
	    id: 'delivery_date',
	    renderTo: 'delivery_date_placeholder',
	    fieldLabel: 'Desired Delivery Date',
	    labelAlign: 'left',
	    labelWidth: 150, 
	    format: 'Y-m-d',
	    value: new Date(todays_date),
	    minValue: todays_date,
	    allowBlank: false,
	    anchor : '32%'
	});


        // ************** Form Handling *** //
        var clickHandlerSendFileandMetaData = function() {
		
		var source_language = form_source_language.elements[0].value;
		var target_languages = targetLanguageForm.getForm().findField('target_language_id').getValue();

		// toDo: Improve
		var curr_date = input_delivery_date.getValue().getDate();
		var curr_month = input_delivery_date.getValue().getMonth();
		var curr_year = input_delivery_date.getValue().getFullYear();
		var delivery_date = curr_year + '-' + curr_month + '-' + curr_date;

		if(myuploadform.getForm().isValid()){
			form_action=1;
	                myuploadform.getForm().submit({
        	        	url: '/intranet-customer-portal/upload-files-form-action.tcl',
				params: 'source_language=' + source_language + '&target_languages=' + target_languages + '&delivery_date=' + delivery_date + '&inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote@',
                	        waitMsg: 'Uploading file...',
				success: function(response){
					uploadedFilesStore.load();
				}, 
				failure: function(response){
					Ext.Msg.show({title:'Could not upload file', msg:'<br/>The file you are trying to upload is either too big or you have already uploaded another file with an identical name.'});
				}, 
                 	});

			// reset form values 
                        targetLanguageForm.getForm().findField('target_language_id').setValue('');
                        document.getElementById('delivery_date').value = todays_date;
                        myuploadform.getForm().findField('upload_file').setValue('');
                 }
        };

        //add listener for button click
        Ext.EventManager.on('btnSendFileandMetaData', 'click', clickHandlerSendFileandMetaData);

        // ************** Handle CANCEL case *** //
        // Ext.EventManager.on('cancel', 'click', clickHandlerCancel);
});









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
	    autoLoad: true,
	    model: 'UploadedFiles',
	    proxy: {
        	type: 'ajax',
	        url: '/intranet-customer-portal/get-uploaded-files1?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote@',
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
        	    {header: "File", width: 150, dataIndex: 'file_name', sortable: true},
        	    {header: "Source Language", width: 100, dataIndex: 'source_language', sortable: true},
        	    {header: "Target Languages", width: 100, dataIndex: 'target_language', sortable: true},
        	    {header: "Delivery Date", width: 100, dataIndex: 'deliver_date', sortable: true}
        	]
	});

	uploadedFilesStore.load();

       // ************** Panel: UploadedFiles *** //
/*
       Ext.define('CustomerPortal.UploadedFiles', {
            extend: 'Ext.data.Model',
            idProperty: 'inquiry_files_id',          // The primary key of the category
            fields: [
                {type: 'string', name: 'inquiry_files_id'},
                {type: 'string', name: 'file_name'},
                {type: 'string', name: 'source_language'},
                {type: 'string', name: 'target_languages'},
                {type: 'string', name: 'deliver_date'},
            ]
        });
*/

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
            width:              200,
            height:             100,
            // standardsubmit:     true,
            items: [{
                id: 'target_language_id',
                // name: 'target_language_id',
                xtype: 'boxselect',
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
		renderTo: 'fi-basic',
                fileUpload: true,
                width: 300,
                autoHeight: true,
                // bodyStyle: 'padding: 10px 10px 10px 10px;',
                labelWidth: 50,
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
                    emptyText: 'Select a document to upload...',
                    fieldLabel: 'File',
                    buttonText: 'Browse'
                 }
		]
        });


	// ************** Date Picker *** // 



input_delivery_date = new Ext.form.Date({
    id: 'delivery_date',
    renderTo: 'delivery_date_placeholder',
    // fieldLabel: 'Birth date',
    format: 'Y-m-d',
    value: new Date(todays_date),
    minValue: todays_date,
    // maxValue: '31/01/2009',
    allowBlank: false,
    anchor : '32%'
      });

/*

    	//define select handler
	var selectHandler = function(myDP, date) {
		 myDP.hide();	
	};
  
	// create the date picker
	var myDP = Ext.create('Ext.menu.DatePicker', {
		handler: function(dp, date){
			document.getElementById('dateField').value = Ext.Date.format(date, 'Y-m-d')
			myDP.hide();
       		}
	});
	
	// document.getElementById('dateField').style.visibility='hidden'
	// myDP.show();

	//define click handler
	var clickHandler = function() {
		//show the date picker
		myDP.show();
	};

	//add listener for button click
	// Ext.EventManager.on('openCalendar', 'click', clickHandler);

*/
        // ************** Panel: Files already uploaded *** //
/*

	Ext.create('Ext.Panel', {
		id: 'panel_files_uploaded',
	        width: 600,
        	renderTo: 'panel_files_uploaded_placeholder',
	        // style: "margin:15px",
        	bodyStyle: 'padding:5px;font-size:11px;',
	        title: 'Uploaded Files for this quote:',
        	html: '<p><i>Loading ...</i></p>'
	});


        // ************** Panel: Comments *** //

       handle_file_list = function(){
	       return {
			update_file_list : function() {
			       Ext.Ajax.request({
				  url: '/intranet-customer-portal/get-uploaded-files' + '?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote@',
			        	success: function(r) {
	        				Ext.getCmp('panel_files_uploaded').body.update(r.responseText);
				                Ext.getCmp('panel_files_uploaded').doLayout();
        		  	        }
       				});
			}
		}	
	}();

	handle_file_list.update_file_list();
*/

        // ************** Form Handling *** //
        var clickHandlerSendFileandMetaData = function() {
		
		var source_language = form_source_language.elements[0].value;
		var target_languages = targetLanguageForm.getForm().findField('target_language_id').getValue();

		// toDo: Improve
		var curr_date = input_delivery_date.getValue().getDate();
		var curr_month = input_delivery_date.getValue().getMonth();
		var curr_year = input_delivery_date.getValue().getFullYear();
		var delivery_date = curr_year + '-' + curr_month + '-' + curr_date;

		console.log('DeliveryDate:' + delivery_date);
		if(myuploadform.getForm().isValid()){
			form_action=1;
	                myuploadform.getForm().submit({
        	        	url: '/intranet-customer-portal/upload-files-form-action.tcl',
				params: 'source_language=' + source_language + '&target_languages=' + target_languages + '&delivery_date=' + delivery_date + '&inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
                	        waitMsg: 'Uploading file...',
                        	success: function(form,action){
	                  	      msg('Success', 'Processed file on the server');
				      console.log('Success, Processed file on the server');
        	         	}
                 	});
			console.log('file uploaded!');
			console.log('requesting:' + '/intranet-customer-portal/get-uploaded-files' + '?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote' + '...');
                        targetLanguageForm.getForm().findField('target_language_id').setValue('');
                        document.getElementById('delivery_date').value = todays_date;
                        myuploadform.getForm().findField('upload_file').setValue('');
                        form_source_language.elements[0].value = '';
			// handle_file_list.update_file_list().delay(5000);
                 }
        };

        //add listener for button click
        Ext.EventManager.on('btnSendFileandMetaData', 'click', clickHandlerSendFileandMetaData);

        // ************** Handle CANCEL case *** //
/*
        var clickHandlerCancel = function() {
                if(myuploadform.getForm().isValid()){
                        form_action=1;
                        myuploadform.getForm().submit({
                                url: '/intranet-customer-portal/cancel_inquiry.tcl',
                                params: '&inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
                                waitMsg: 'Uploading file...',
                                success: function(form,action){
                                            msg('Success', 'Processed file on the server');
                                }
                        });
                 }
        };

        // add listener for button CANCEL
        // Ext.EventManager.on('continue', 'click', clickHandlerCancel);

*/

});









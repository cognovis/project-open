// General Settings

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
            })


	// ************** Date Picker *** // 

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
	
	//define click handler
	var clickHandler = function() {
		//show the date picker
		myDP.show();
	};
	//add listener for button click
	Ext.EventManager.on('openCalendar', 'click', clickHandler);


        // ************** Form Handling *** //
        var clickHandlerSendFileandMetaData = function() {
		var source_language = form_source_language.elements[0].value;
		var target_languages = form_target_languages.elements[0].value;
		var delivery_date = document.getElementById('dateField').value;
		if(myuploadform.getForm().isValid()){
			form_action=1;
	                myuploadform.getForm().submit({
        	        	// url: '/intranet-customer-portal/upload-files-form-action.tcl',
				params: 'source_language=' + source_language + '&target_languages=' + target_languages + '&delivery_date=' + delivery_date + '&inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
                	        waitMsg: 'Uploading file...',
                        	success: function(form,action){
	                  	      // msg('Success', 'Processed file on the server');
				      // console.log('Success, Processed file on the server');
        	         	}
                 	});
			console.log('file uploaded!');
/*
			Ext.Ajax.request({
			    url: '/intranet-customer-portal/get-uploaded-files' + '?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
    				success: function(r) {
				Ext.getCmp('panel_files_uploaded').body.update(r.responseText);
				Ext.getCmp('panel_files_uploaded').doLayout(); 
    			}
			});
*/
                 }
        };

        //add listener for button click
        Ext.EventManager.on('btnSendFileandMetaData', 'click', clickHandlerSendFileandMetaData);


        // ************** Panel: Files already uploaded *** //

	Ext.create('Ext.Panel', {
		id: 'panel_files_uploaded',
	        width: 600,
        	renderTo: 'panel_files_uploaded_placeholder',
	        // style: "margin:15px",
        	bodyStyle: 'padding:5px;font-size:11px;',
	        title: 'Uploaded Files for this quote:',
        	html: '<p><i>Loading ...</i></p>'
	});

/*
       Ext.Ajax.request({
	url: '/intranet-customer-portal/get-uploaded-files' + '?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
        success: function(r) {
        	Ext.getCmp('panel_files_uploaded').body.update(r.responseText);
                Ext.getCmp('panel_files_uploaded').doLayout();
        }
       });
*/
        // ************** Panel: Comments *** //

        Ext.create('Ext.Panel', {
                id: 'panel_comments',
                width: 600,
                renderTo: 'panel_comments_placeholder',
                // style: "margin:15px",
                bodyStyle: 'padding:5px;font-size:11px;',
                title: 'Uploaded Files for this quote:',
                html: '<p><i>Loading ...</i></p>'
        });


        // ************** Navegation *** //

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
        Ext.EventManager.on('continue', 'click', clickHandlerCancel);

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
                        url: '/intranet-rest/im_category',
                        appendId: true,
                        extraParams: {
                                format: 'json',
                                category_type: '\'Intranet Translation Language\''
                        },
                        reader: { type: 'json', root: 'data' }
                }
        });

        var targetLanguageForm = new Ext.form.FormPanel({
            extend:             'Ext.form.Panel',
            id:                 'form_target_languages_combo',
            renderTo:           'form_target_languages',
            autoHeight:         true,
            width:              200,
            height:             500,
            standardsubmit:     true,
            items: [
                {
                name: 'target_language_id',
                xtype: 'boxselect',
		// xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
                forceSelection: true,
                queryMode: 'remote',
                store: targetLanguageStore,
                listConfig: {
                        getInnerTpl: function() {
                                return '<div class={indent_class}>{category_translated}</div>';
                        }
                }
                }
            ]
        });

});











// General Settings

//set local blank image 
Ext.BLANK_IMAGE_URL = '/intranet/images/cleardot.gif';


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
        	        	url: '/intranet-customer-portal/upload-files-form-action.tcl',
				params: 'source_language=' + source_language + '&target_languages=' + target_languages + '&delivery_date=' + delivery_date + '&inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
                	        waitMsg: 'Uploading file...',
                        	success: function(form,action){
	                  	      msg('Success', 'Processed file on the server');
        	         	}
                 	});
                 }
        };

        //add listener for button click
        Ext.EventManager.on('btnSendFileandMetaData', 'click', clickHandlerSendFileandMetaData);


        // ************** Upload Form *** //

    Ext.create('Ext.Panel', {
	id: 'panel_files_uploaded',
        width: 600,
        renderTo: 'panel_files_uploaded_placeholder',
        // style: "margin:15px",
        bodyStyle: "padding:5px;font-size:11px;",
        title: 'Uploaded Files for this quote:',
        html: '<p><i>Loading ...</i></p>'
    });

	Ext.Ajax.request({
	    url: '/intranet-customer-portal/get-uploaded-files' + '?inquiry_id=@inquiry_id;noquote@&security_token=@security_token;noquote',
    		success: function(r) {
			Ext.getCmp('panel_files_uploaded').body.update(r.responseText);
			Ext.getCmp('panel_files_uploaded').doLayout(); 
    		}
	});
});









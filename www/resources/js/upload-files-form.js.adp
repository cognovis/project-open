
Ext.require([
    'Ext.form.field.File',
    'Ext.form.Panel',
    'Ext.window.MessageBox'
]);

Ext.onReady(function(){

/*
    var fibasic = Ext.create('Ext.form.field.File', {
        renderTo: 'fi-basic',
        width: 400,
        hideLabel: true
    });

    Ext.create('Ext.form.field.File', {
        renderTo: 'fi-button',
        buttonOnly: true,
        hideLabel: true,
        listeners: {
            'change': function(fb, v){
                var el = Ext.get('fi-button-msg');
                el.update('<b>Selected:</b> '+v);
                if(!el.isVisible()){
                    el.slideIn('t', {
                        duration: 200,
                        easing: 'easeIn',
                        listeners: {
                            afteranimate: function() {
                                el.highlight();
                                el.setWidth(null);
                            }
                        }
                    });
                }else{
                    el.highlight();
                }
            }
        }
    });
*/

myuploadform= new Ext.FormPanel({
		renderTo: 'fi-basic',
                fileUpload: true,
                width: 500,
                autoHeight: true,
                bodyStyle: 'padding: 10px 10px 10px 10px;',
                labelWidth: 50,
                defaults: {
                    anchor: '95%',
                    allowBlank: false,
                    msgTarget: 'side'
                },
                items:[
                 {
                    xtype: 'fileuploadfield',
                    id: 'filedata',
                    emptyText: 'Select a document to upload...',
                    fieldLabel: 'File',
                    buttonText: 'Browse'
                 }
		],
                buttons: [{
		    text: 'Upload',
                    handler: function(){
                        if(myuploadform.getForm().isValid()){
                            form_action=1;
                            myuploadform.getForm().submit({
                                url: 'handleupload.php',
                                waitMsg: 'Uploading file...',
                                success: function(form,action){
                                    msg('Success', 'Processed file on the server');
                                }
                            });
                        }
                    }
                }]
            })
});









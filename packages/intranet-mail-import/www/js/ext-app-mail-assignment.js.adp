Ext.require([
    'Ext.data.*',
    'Ext.form.*'
]);


Ext.onReady(function(){

    Ext.define("Post", {
        extend: 'Ext.data.Model',
        proxy: {
            type: 'jsonp',
            url : '/intranet-mail-import/datasource-mail-dispatcher',
            reader: {
                type: 'json',
                root: 'topics',
                totalProperty: 'totalCount'
            }
        },

        fields: [
            {name: 'object_id', mapping: 'object_id'},
            {name: 'object_type', mapping: 'object_type'},
            {name: 'object_name', mapping: 'object_name'},
            {name: 'object_nr', mapping: 'object_nr'},
        ]
    });

    ds = Ext.create('Ext.data.Store', {
        id: 'ds_store',
        pageSize: 10,
        model: 'Post'
    });

    var panel = Ext.create('Ext.panel.Panel', {
        renderTo: searchbox,
        title: '@search_title@',
        width: 600,
        bodyPadding: 10,
        layout: 'anchor',

        items: [{
            xtype: 'component',
            style: 'margin-top:7px',
            html: '@hint_search;noquote@'
        },
	{
            xtype: 'combo',
            store: ds,
            displayField: 'title',
            typeAhead: false,
            hideLabel: true,
            hideTrigger:true,
            anchor: '100%',

            listConfig: {
                loadingText: 'Searching...',
                emptyText: 'No matching posts found.',
                // Custom rendering template for each item
                getInnerTpl: function() {
		   var remove_mails_box_p = Ext.getCmp('remove_mails_p').getValue();
		   return '<a href="javascript:void(0)" onclick="make_ajax_request_i({object_id},' + remove_mails_box_p + ');">{object_name}</a>';
                }
            },
            pageSize: 10
        }, {
	   xtype: 'checkbox',
           hideLabel: false,
	   boxLabel: '@hint_checkbox;noquote@',
	   id: 'remove_mails_p'
	}]
    });


    // ---------------- Defered Mails -----------------------------


    Ext.define("Defered Mails", {
        extend: 'Ext.data.Model',
        proxy: {
            type: 'jsonp',
            url : '/intranet-mail-import/datasource-defered-mails',
            reader: {
                type: 'json',
                root: 'mails',
                totalProperty: 'totalCount'
            }
        },
        fields: [
            {name: 'msg_name', mapping: 'msg_name'},
            {name: 'from_header', mapping: 'from_header'},
            {name: 'to_header', mapping: 'to_header'},
            {name: 'subject_header', mapping: 'subject_header'},
        ]
    });

    ds_defered_mails = Ext.create('Ext.data.Store', {
        pageSize: 10,
        model: 'Defered Mails',
	autoLoad: true
    });

    var sm = Ext.create('Ext.selection.CheckboxModel');
    var grid = Ext.create('Ext.grid.Panel', {
        id: 'grid_panel_defered_mails',
        store: ds_defered_mails,
        selModel: sm,
        columns: [
            {text: "@message_name@", dataIndex: 'msg_name', hidden: true},
            {text: "@from@", dataIndex: 'from_header'},
            {text: "@to@", dataIndex: 'to_header'},
            {text: "@subject_header@", dataIndex: 'subject_header', width: 365}
        ],
        columnLines: true,
        width: 600,
        height: 300,
        frame: true,
        title: '@title_defered_mails@',
        iconCls: 'icon-grid',
        renderTo: 'grid',
	dockedItems: [{
        	xtype: 'toolbar',
		dock: 'bottom',
	        items : [ {
        	    xtype: 'button',
	            id: 'delete',
	            text: '@delete_button;noquote@',
        	    tooltip: 'Delete checked mails',
		    handler: function() {
		        // alert('You clicked the button!')
			deleteMail();
    		    },
		    enableToggle: true
               }]
       }]
    });

    var deleteMail = function(){
		console.log("deleting");
        	var records = grid.getSelectionModel().getSelection();
        	Ext.each(records, function(record){
	            Ext.Ajax.request({
        	        method: 'POST',
                	url: '/intranet-mail-import/assign-mail-to-object',
        	        params: {
	                        object_id:-1,
                	        email_id:record.get('msg_name'),
                        	remove_mails_p:1
	                },
        	        success: function(response){
                	        var text = response.responseText;
				Ext.getCmp('grid_panel_defered_mails').getStore().load();
                        	alert('Removal successful');
	                }
        	    });
	            // result += record.get(column) * 1;
		    // alert(record.get(column));
        	});
		ds_defered_mails.load();
	        return 0;
    };

    make_ajax_request_i = function(object_id, remove_mails_p){
	var records = grid.getSelectionModel().getSelection();
        Ext.each(records, function(record){
            // result += record.get(column) * 1;
	    // alert(record.get('msg_name'));
	    Ext.Ajax.request({
		method: 'POST',
                url: '/intranet-mail-import/assign-mail-to-object',
                params: {
                        object_id:object_id,
			email_id:record.get('msg_name'),
			remove_mails_p:remove_mails_p
                },
                success: function(response){
                        var text = response.responseText;
                        alert('Assignment successful');
			Ext.getCmp('grid_panel_defered_mails').getStore().load();
                }
            });
        });
    }
});




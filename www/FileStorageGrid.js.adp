/**
 * intranet-sencha-ticket-tracker/www/FileStorageGrid.js
 * Grid table for ]po[ file storage
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: FileStorageGrid.js.adp,v 1.14 2011/06/10 14:24:05 po34demo Exp $
 *
 * Copyright (C) 2011, ]project-open[
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


// The form for uploading a new file
var fileStorageNewForm;

function showFileStorageNewForm(ticket_id) {

    var msg = function(title, msg) {
        Ext.Msg.show({
            title: title,
            msg: msg,
            minWidth: 200,
            modal: true,
            icon: Ext.Msg.INFO,
            buttons: Ext.Msg.OK
        });
    };
    
    // Create the upload form if it isn't defined yet:
    if (!fileStorageNewForm) {
	var form = Ext.widget('form', {
	    itemId: 'ticketUploadForm',
	    layout: { type: 'vbox', align: 'stretch' },
	    border: false,
	    fieldDefaults: { labelAlign: 'top', labelWidth: 100 },
	    defaults: {	margins: '10 10 10 10' },
	    items: [{
		name: 'title',
		xtype: 'textfield',
		id: 'name',
		fieldLabel: '#intranet-core.Name#'
	    }, {
		name: 'ticket_id',
		xtype: 'textfield',
		id: 'ticket_id',
		fieldLabel: 'Ticket ID'
	    }, {
		name: 'upload_file',
		xtype: 'filefield',
		id: 'file',
		emptyText: '#intranet-sencha-ticket-tracker.Select_a_file#',
		fieldLabel: '#intranet-core.Photo#',
		buttonText: '',
		buttonConfig: { iconCls: 'upload-icon' }
	    }],

	    buttons: [{
		text: '#intranet-sencha-ticket-tracker.button_Save#',
		handler: function(){
		    var form = this.up('form').getForm();
		    var form_fields = form.getFieldValues();
		    var ticket_id = form_fields.ticket_id;

		    if(form.isValid()){
			form.submit({
			    url: 'file-add',
			    method: 'POST',
			    params: {
				folder_id: ticket_id
			    },
			    waitMsg: '#intranet-sencha-ticket-tracker.Uploading_your_photo#',
			    success: function(fp, o) {
				// msg('Success', 'Processed file "' + o.result.file + '" on the server');
				fileStorageNewForm.hide();
			    },
			    failure: function(fp, o) {
				// msg('Failure', o.result.errors);
				fileStorageNewForm.hide();
			    }
			});
	
			// reload the store which should update this grid as well
			fileStorageStore.load();
		    }
		}
	    }]
	});

	fileStorageNewForm = Ext.widget('window', {
	    title: '#intranet-filestorage.Upload_File#',
	    closeAction: 'hide',
	    width: 300,
	    height: 400,
	    minHeight: 200,
	    layout: 'fit',
	    resizable: true,
	    modal: true,
	    items: form
	});
    }

    var form = fileStorageNewForm.child('#ticketUploadForm');
    var form2 = form.getForm();
    form2.setValues({ticket_id: ticket_id});
    fileStorageNewForm.show();
}



var fileStorageGridSelModel = Ext.create('Ext.selection.CheckboxModel', {
    listeners: {
	selectionchange: function(sm, selections) {
	    // var grid = this.view;
	    // grid.down('#removeButton').setDisabled(selections.length == 0);
	}
    }
});


// Local store definition.
// We have to redefine the store every time we show
// files for a different ticket
var fileStorageStore = Ext.create('Ext.data.Store', {
    model: 'TicketBrowser.FileStorage',
    storeId: 'fileStorageStore',
    autoLoad: false,
    remoteSort: true,
    pageSize: 10,			// Enable pagination
    sorters: [{
	property: 'name',
	direction: 'DESC'
    }],
    proxy: {
	type: 'rest',
	url: '/intranet-rest/file_storage_object',
	appendId: true,
	extraParams: { format: 'json', parent_id: 0 },
	reader: { type: 'json', root: 'data' }
    }
});

var fileStorageGrid = Ext.define('TicketBrowser.FileStorageGrid', {
    extend:	'Ext.grid.Panel',
    alias:	'widget.fileStorageGrid',
    id:		'fileStorageGrid',
    store: 	fileStorageStore,

    minWidth:	300,
    minHeight:	100,
    frame:	true,
    iconCls:	'icon-grid',

    columns: [
	      {
		  header: '#intranet-filestorage.Filename#',
		  dataIndex: 'name',
		  flex: 1,
		  minWidth: 100,
		  renderer: function(value, o, record) {
		      var name = record.get('name');
		      var item_id = record.get('item_id');
		      var html = '<a href="/fs/view/index?file_id=' + item_id + '" target="_blank">' + name + '</a>';
		      return html;
		  }
	      },
	      {text: "#intranet-core.Description#", sortable: true, dataIndex: 'description'},
	      {text: "#intranet-sencha-ticket-tracker.Creation_Date#", sortable: true, dataIndex: 'creation_date'},
	      {text: "#intranet-core.Size#", sortable: true, dataIndex: 'content_length'},
	      {text: "#intranet-sencha-ticket-tracker.MIME_Type#", sortable: true, dataIndex: 'mime_type', hidden: true}
	 ],
    columnLines: true,
    selModel: fileStorageGridSelModel,

    // inline buttons
    dockedItems: [{
        xtype: 'toolbar',
        dock: 'bottom',
        ui: 'footer',
        layout: {
            pack: 'center'
        },
        items: [{
            minWidth: 80,
            text: '#intranet-sencha-ticket-tracker.button_Save#'
        },{
            minWidth: 80,
            text: '#intranet-sencha-ticket-tracker.button_Cancel#'
        }]
    }, {
        xtype: 'toolbar',
        items: [{
            text:'#file-storage.Upload_New_File#',
            tooltip:'#intranet-sencha-ticket-tracker.Upload_New_Attachment#',
            iconCls:'add',
	    handler: function() {
		var tid = fileStorageStore.proxy.extraParams['ticket_id'];
		showFileStorageNewForm(tid);
	    }
        }, '-', {
            text:'#intranet-sencha-ticket-tracker.Options#',
            tooltip:'#intranet-sencha-ticket-tracker.Set_options#',
            iconCls:'option'
        },'-',{
            itemId: 'removeButton',
            text:'#intranet-sencha-ticket-tracker.Delete_attachment#',
            tooltip:'#intranet-helpdesk.Remove_checked_items#',
            iconCls:'remove',
            disabled: false,
	    handler: function () {
		var selection = fileStorageGridSelModel.getSelection();
		for (var i = 0; i < selection.length; i++) {
		    var file = selection[i].data;
		    Ext.Ajax.request({
			url: 'file-delete',
			method: 'GET',
			params: {
			    item_id: file.item_id
			},
			success: function(response){
			    var text = response.responseText;
			}
		    });
		}
		
		// reload the filestorage
		fileStorageStore.load();
	    }
        }]
    }],

    // Load the files for the new ticket
    loadTicket: function(rec){

	// Reload the store containing the ticket's files
	var folder_id = rec.get('fs_folder_id');
	var ticket_id = rec.get('ticket_id');

	// Replace empty string by "0", because an empty string means no restriction to the server.
        if ("" === folder_id) { folder_id = 0; }

	// Save the property in the proxy, which will pass it directly to the REST server
	fileStorageStore.proxy.extraParams['parent_id'] = folder_id;
	fileStorageStore.proxy.extraParams['ticket_id'] = ticket_id;

        this.ticket_id = ticket_id;
	fileStorageStore.load();
    },

    // Somebody pressed the "New Ticket" button:
    // Prepare the form for entering a new ticket
    newTicket: function() {
	// ToDo: Load empty Filestorage
    }

});





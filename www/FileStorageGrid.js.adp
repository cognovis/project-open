/**
 * intranet-sencha-ticket-tracker/www/FileStorageGrid.js
 * Grid table for ]po[ file storage
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id$
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
			title:		title,
			msg:		msg,
			minWidth:	200,
			modal:		true,
			icon:		Ext.Msg.INFO,
			buttons:	Ext.Msg.OK
		});
	};
	
	Ext.define('example.fielderror', {
		extend:	'Ext.data.Model',
		fields:	['id', 'msg']
	});

	// Create the upload form if it isn't defined yet:
	if (!fileStorageNewForm) {
		var form = Ext.widget('form', {
			itemId:		'ticketUploadForm',
			layout:		{ type: 'vbox', align: 'stretch' },
			border:		false,
			fieldDefaults:	{ labelAlign: 'top', labelWidth: 100 },
			defaults:	{ margins: '10 10 10 10' },
			errorReader: Ext.create('Ext.data.reader.Json', {		// Workaround for Sencha bug parsing JSON replies
				model:			'example.fielderror',
				record:			'field',
				successProperty:	'success'
			}),
	
			items: [{
				name:		'ticket_id',				// We need this field to identify the upload folder
				xtype:		'hiddenfield'
			}, {
				name:		'upload_file',
				xtype:		'filefield',
				id:		'file',
				emptyText:	'#intranet-sencha-ticket-tracker.Select_a_file#',
				fieldLabel:	'#intranet-sencha-ticket-tracker.File#',
				buttonText:	'',
				buttonConfig:	{ iconCls: 'upload-icon' }
			}, {
				name:		'description',
				xtype:		'textfield',
				id:		'title',
				emptyText:	'#intranet-sencha-ticket-tracker.Description#',
				fieldLabel:	'#intranet-sencha-ticket-tracker.Description#'
			}],
		
			buttons: [{
				text:	'#intranet-sencha-ticket-tracker.button_Save#',
				handler: function(){
	
					// Get the ticket_id
					var ticket_form = Ext.getCmp('ticketForm');
					var ticket_id = ticket_form.getForm().findField('ticket_id').getValue();
		
					// Store into local form
					var form = this.up('form').getForm();
					form.findField('ticket_id').setValue(ticket_id);
		
					// Submit the form
					if(form.isValid()){
					form.submit({
						url:	'file-add',
						method:	'GET',
						waitMsg:	'#intranet-sencha-ticket-tracker.Uploading_your_photo#',
						success:	function(form, action) {
			
							// Hide the upload form
							fileStorageNewForm.hide();
							
							// process the result manually
							try {
								var resp = Ext.decode(action.response.responseText);
								var fs_folder_id = resp.result.data[0].fs_folder_id + '';
								var fs_folder_path = resp.result.data[0].fs_folder_path + '';
							} catch (ex) {
								alert('Error creating object: ' + operation.action.responseText);
								return;
							}
			
							// Creating a file might have created a new FS folder in the backend.
							// To get this value, we need to reload the ticket model:
							var ticket_form = Ext.getCmp('ticketForm');
							var ticket_id = ticket_form.getForm().findField('ticket_id').getValue();
							var ticket_model = ticketStore.findRecord('ticket_id',ticket_id);
							ticket_model.set('fs_folder_id', fs_folder_id);
							ticket_model.set('fs_folder_path', fs_folder_path);
	
							// Tell all panels to load the data of the newly created object
							var compoundPanel = Ext.getCmp('ticketCompoundPanel');
							compoundPanel.loadTicket(ticket_model);	
						},
							failure: function(form, action) {
							alert('Error loading file');
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
			title:		'#intranet-sencha-ticket-tracker.Upload_File#',
			closeAction:	'hide',
			width:		300,
			height:		400,
			minHeight:	200,
			layout:		'fit',
			resizable:	true,
			modal:		true,
			items:		form
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
	model:	'TicketBrowser.FileStorage',
	storeId:	'fileStorageStore',
	autoLoad:	false,
	remoteSort:	true,
	pageSize:	5,			// Enable pagination
	sorters:	[{
	property:	'name',
	direction:	'DESC'
	}],
	proxy:	{
	type:	'rest',
	url:	'/intranet-rest/file_storage_object',
	appendId:	true,
	extraParams:	{ format: 'json', parent_id: 0 },
	reader:	{ type: 'json', root: 'data' }
	}
});

fileStorageStore.on({
    'load':{
        fn: function(store, records, options){
            //store is loaded, now you can work with it's records, etc.
            var grid = Ext.getCmp('fileStorageGrid');
			var num = fileStorageStore.data.length;
			grid.height = grid.minHeight + num*20;
        },
        scope:this
    }
});

var fileStorageGrid = Ext.define('TicketBrowser.FileStorageGrid', {
	extend:		'Ext.grid.Panel',
	alias:		'widget.fileStorageGrid',
	id:		'fileStorageGrid',
	store:		fileStorageStore,
	deferredRender:	false,

	minWidth:	300,
	minHeight:	100,
	frame:		true,
	iconCls:	'icon-grid',

	columns: [
		  {
		  header:	'#intranet-sencha-ticket-tracker.Filename#',
		  dataIndex:	'name',
		  flex:	1,
		  minWidth:	100,
		  renderer: function(value, o, record) {
			  var name = record.get('name');
			  var item_id = record.get('item_id');
			  var path = this.ownerCt.folder_path;
			  var html = '<a href="/file-storage/view'+this.fs_folder_path+'/'+name+'" target="_blank">' + name + '</a>';
			  return html;
		  }
		  },
		  {text: "#intranet-core.Description#", sortable: true, dataIndex: 'description'},
		  {text: "#intranet-sencha-ticket-tracker.Creation_Date#", sortable: true, dataIndex: 'creation_date'},
		  {text: "#intranet-core.Size#", sortable: true, dataIndex: 'content_length'},
		  {text: "#intranet-sencha-ticket-tracker.MIME_Type#", sortable: true, dataIndex: 'mime_type', hidden: true}
	 ],
	columnLines: true,
	// selModel: fileStorageGridSelModel,

	// inline buttons
	dockedItems: [{
		id: 'uploadButtonToolbar',
		xtype:	'toolbar',
		items: [{
			id: 'uploadButton',
			text:'#file-storage.Upload_New_File#',
			tooltip:'#intranet-sencha-ticket-tracker.Upload_New_Attachment#',
			iconCls:'add',
			handler: function() {
				// Get the ticket_id
				var ticketForm = Ext.getCmp('ticketForm');
				var ticket_id_field = ticketForm.getForm().findField('ticket_id');
				var ticket_id = ticket_id_field.getValue();

				// Show the upload form
				showFileStorageNewForm(ticket_id);
			}
		}]
	}],

	// Load the files for the new ticket
	loadTicket: function(rec){

		// Reload the store containing the ticket's files
		var folder_id = rec.get('fs_folder_id');
		var folder_path = rec.get('fs_folder_path');
		var ticket_id = rec.get('ticket_id');
	
		// Replace empty string by "0", because an empty string means no restriction to the server.
		if ("" === folder_id) { folder_id = 0; }
	
		// Store the file_storage_path locally
		this.fs_folder_path = folder_path;
		this.fs_folder_id = folder_id;
	
		// Save the property in the proxy, which will pass it directly to the REST server
		fileStorageStore.proxy.extraParams['parent_id'] = folder_id;
		// fileStorageStore.proxy.extraParams['ticket_id'] = ticket_id;
	
		this.ticket_id = ticket_id;
		fileStorageStore.load();

		// Show this portlet (may be hidden before).
		this.show();
		
		//If ticket is closed, the button is disabled
		var ticket_status_id=rec.get('ticket_status_id');
		var buttonToolbar = this.getDockedComponent('uploadButtonToolbar');
		var loadButton = buttonToolbar.getComponent('uploadButton');
		
		if (ticket_status_id == '30001'){ //Closed
				loadButton.setDisabled(true);
		} else {
			loadButton.setDisabled(false);
		}				
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
	// We don't need to show this while the ticket hasn't yet been created...
	this.hide();
	}

});





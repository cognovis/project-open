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

function showFileStorageNewForm() {

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
		name: 'upload_file',
		xtype: 'filefield',
		id: 'file',
		emptyText: '#intranet-sencha-ticket-tracker.Select_a_file#',
		fieldLabel: '#intranet-core.Photo#',
		buttonText: '',
		buttonConfig: { iconCls: 'upload-icon' }
	    }],

	    buttons: [{
		text: 'Save',
		handler: function(){
		    var form = this.up('form').getForm();
		    if(form.isValid()){
			form.submit({
			    url: 'file-add',
			    method: 'POST',
			    params: {
				folder_id: 59616
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
	    height: 200,
	    minHeight: 100,
	    layout: 'fit',
	    resizable: true,
	    modal: true,
	    items: form
	});
    }
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

var fileStorageGrid = Ext.define('TicketBrowser.FileStorageGrid', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.fileStorageGrid',
    store: fileStorageStore,

    minWidth: 300,
    minHeight: 100,
    frame: true,
    iconCls: 'icon-grid',

    /* Allow to show detailed information about files?
    plugins: [{
	ptype: 'rowexpander',
	rowBodyTpl : [
		      '<p><b>Company:</b> {company}</p><br>',
		      '<p><b>Summary:</b> {desc}</p>'
		     ]
    }],
    collapsible: true,
    animCollapse: true,
    */

    columns: [
	      {
		  header: 'File',
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
	      {text: "Description", sortable: true, dataIndex: 'description'},
	      {text: "Creation Date", sortable: true, dataIndex: 'creation_date'},
	      {text: "Size", sortable: true, dataIndex: 'content_length'},
	      {text: "MIME Type", sortable: true, dataIndex: 'mime_type', hidden: true}
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
            text: 'Save'
        },{
            minWidth: 80,
            text: 'Cancel'
        }]
    }, {
        xtype: 'toolbar',
        items: [{
            text:'Add a file',
            tooltip:'Add a new row',
            iconCls:'add',
	    handler: showFileStorageNewForm
        }, '-', {
            text:'Options',
            tooltip:'Set options',
            iconCls:'option'
        },'-',{
            itemId: 'removeButton',
            text:'Remove Something',
            tooltip:'Remove the selected item',
            iconCls:'remove',
            disabled: false,
	    handler: function () {
		var selection = fileStorageGridSelModel.getSelection();
		msg('Selection', selection);
	    }
        }]
    }]
});





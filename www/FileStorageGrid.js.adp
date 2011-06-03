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

Ext.onReady(function(){

    var selModel = Ext.create('Ext.selection.CheckboxModel', {
        listeners: {
            selectionchange: function(sm, selections) {
                grid4.down('\#removeButton').setDisabled(selections.length == 0);
            }
        }
    });
    
    var grid4 = Ext.create('Ext.grid.Panel', {
        id:'button-grid',
        store: fileStorageStore,
        columns: [
	      {text: "Name", flex: 1, sortable: true, dataIndex: 'name'},
	      {text: "Description", sortable: true, dataIndex: 'description'},
	      {text: "Creation Date", sortable: true, dataIndex: 'creation_date'},
	      {text: "Size", sortable: true, dataIndex: 'content_length'},
	      {text: "MIME Type", sortable: true, dataIndex: 'mime_type', hidden: true}
	 ],
        columnLines: true,
        selModel: selModel,

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
                text:'Add Something',
                tooltip:'Add a new row',
                iconCls:'add'
            }, '-', {
                text:'Options',
                tooltip:'Set options',
                iconCls:'option'
            },'-',{
                itemId: 'removeButton',
                text:'Remove Something',
                tooltip:'Remove the selected item',
                iconCls:'remove',
                disabled: true
            }]
        }],

        width: 600,
        height: 300,
        frame: true,
        title: 'Support for standard Panel features such as framing, buttons and toolbars',
        iconCls: 'icon-grid',
        renderTo: Ext.getBody()
    });
});



/**
 * intranet-sencha-ticket-tracker/www/SlaList.js
 * Tree for displaying Service Level Agreements.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: ProjectSlaList.js.adp,v 1.2 2011/06/09 12:10:02 po34demo Exp $
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
var slaList = Ext.define('TicketBrowser.SlaList', {
    extend:	'Ext.tree.Panel',   
    alias:	'widget.slaList',
    id:		'slaList',
    title:	'Service Level Agreements',
    rootVisible: false,
    lines:	false,
    defaultSla: 53349,
    minWidth:	200,
    displayField: 'project_name',
    
    initComponent: function(){
        Ext.apply(this, {
            viewConfig: {
                getRowClass: function(record) {
                    if (!record.get('leaf')) {
                        return 'sla-parent';
                    }
                }
            },
            store: Ext.create('Ext.data.TreeStore', {
                model: 'TicketBrowser.Sla',
                proxy: {
                    type: 'rest',
                    url: '/intranet-sencha-ticket-tracker/sla-datasource',
		    appendId: true,
                    reader: {
                        type: 'json',
                        root: 'data'
                    }
                },
                root: {
		    text: 'All',
		    id: '',
		    project_id: '',
                    expanded: true
                },
                listeners: {
                    single: true,
                    scope: this,
                    load: this.onFirstLoad
                }
            })

        });
        this.callParent();
        this.getSelectionModel().on({
            scope: this,
            select: this.onSelect
        });
    },
    
    onFirstLoad: function(){
        var rec = this.store.getNodeById(this.defaultSla);
        this.getSelectionModel().select(rec);
    },
    
    onSelect: function(selModel, rec){
	if (rec.get('leaf')) { 		
            this.ownerCt.ownerCt.loadSla(rec);
	}
    }
});


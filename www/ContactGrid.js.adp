/**
 * intranet-sencha-ticket-tracker/www/CompanyGrid.js
 * Grid table for ]po[ companies
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: ContactGrid.js.adp,v 1.2 2011/06/08 17:54:22 po34demo Exp $
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


var companyGrid = Ext.define('TicketBrowser.ContactGrid', {
    extend: 'Ext.grid.Panel',    
    alias: 'widget.contactgrid',
    minHeight: 200,
    store: userStore,

    columns: [
        {
            header: 'user_id',
            dataIndex: 'user_id',
            flex: 1,
            minWidth: 150
        }, {
            header: 'nombre',
            dataIndex: 'first_names'
        }, {
            header: 'apellidos',
            dataIndex: 'last_name'
        }
    ],
    dockedItems: [{
        xtype: 'toolbar',
        cls: 'x-docked-noborder-top',
        items: [{
            text: 'Add a new contact',
            iconCls: 'icon-new-ticket',
            handler: function(){
                alert('Not implemented');
            }
        }] 
    }, {
        xtype: 'pagingtoolbar',
        store: userStore,
        dock: 'bottom',
        displayInfo: true
    }],
});

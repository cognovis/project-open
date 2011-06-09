/**
 * intranet-sencha-ticket-tracker/www/CompanyGrid.js
 * Grid table for ]po[ companies
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: ContactGrid.js.adp,v 1.6 2011/06/09 22:28:30 mcordova Exp $
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
    extend:	'Ext.grid.Panel',    
    alias:	'widget.contactGrid',
    id:		'contactGrid',
    minHeight:	200,
    store:	userStore,

    columns: [
        {
            header: 'user_id',
            dataIndex: 'user_id',
            flex: 1,
            minWidth: 150
        }, {
            header: '#intranet-core.First_names#',
            dataIndex: 'first_names'
        }, {
            header: '#intranet-core.Last_name#',
            dataIndex: 'last_name'
        }, {
            header: '#intranet-core.Contact_Mail#',
            dataIndex: 'email'
        }, {
            header: '#intranet-core.Telephone#',
            dataIndex: 'contact_telephone'
        }, {
            header: '#intranet-core.Language#',
            dataIndex: 'language_preference'
        }, {
            header: '#acs-subsite.Information_Updated#',
            dataIndex: 'last_modified'
        }
    ],
    dockedItems: [{
        xtype: 'toolbar',
        cls: 'x-docked-noborder-top',
        items: [{
            text: '#intranet-sencha-ticket-tracker.New_Contact#',
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

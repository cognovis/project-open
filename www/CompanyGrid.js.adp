/**
 * intranet-sencha-ticket-tracker/www/CompanyGrid.js
 * Grid table for ]po[ companies
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


var companyGrid = Ext.define('TicketBrowser.CompanyGrid', {
    extend: 'Ext.grid.Panel',    
    alias: 'widget.companygrid',
    minHeight: 200,
    store: companyStore,

    columns: [
	      {
		  header: 'Company',
		  dataIndex: 'company_name',
		  flex: 1,
		  minWidth: 150
	      }, {
		  header: 'VAT ID',
		  dataIndex: 'vat_number'
	      }, {
		  header: 'Primary Contact',
		  dataIndex: 'primary_contact_id',
		  renderer: function(value, o, record) {
		      return employeeStore.name_from_id(record.get('primary_contact_id'));
		  }
	      }
    ],
    dockedItems: [{
        xtype: 'pagingtoolbar',
        store: companyStore,
        dock: 'bottom',
        displayInfo: true
    }],
});

/**
 * intranet-sencha-company-tracker/www/CompanyContainer.js
 * Container for both CompanyGrid and CompanyForm.
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


Ext.define('TicketBrowser.ContactContainer', {
    extend: 'Ext.container.Container',
    alias: 'widget.contactcontainer',
    title: 'Loading...',

    layout: 'border',

    items: [{
	itemId: 'grid',
        xtype:  'fieldset',
	region: 'center',
	items :[
        {
            fieldLabel: '#intranet-core.First_names#',
            name:       'ticket_first_contact_name',
            allowBlank: false
        },
        {
            fieldLabel: '#intranet-core.Last_name#',
            name:       'ticket_first_contact_last_name'
        },
        {
            xtype:  'radiofield',
            name:   'ticket_sex',
            value:  '1',
            fieldLabel: 'Genero',
            boxLabel:   'hombre'
        },
        {
            xtype:          'radiofield',
            name:           'ticket_sex',
            value:          '0',
            fieldLabel:     '',
            labelSeparator: '',
            hideEmptyLabel: false,
            boxLabel:       'mujer'
        }]
    }]
});
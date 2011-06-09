/**
 * intranet-sencha-company-tracker/www/CompanyContainer.js
 * Container for both CompanyGrid and CompanyForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: ContactContainer.js.adp,v 1.4 2011/06/09 22:28:30 mcordova Exp $
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
    alias: 'widget.contactContainer',
    title: '#intranet-sencha-ticket-tracker.Loading___#',

    layout: 'border',

    items: [{
        itemId: 'grid',
        xtype: 'contactGrid',
        region: 'center'
    }]
});
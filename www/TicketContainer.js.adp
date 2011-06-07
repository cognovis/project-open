/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
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


Ext.define('TicketBrowser.TicketContainer', {
    extend: 'Ext.container.Container',
    alias: 'widget.ticketcontainer',
    title: 'Loading...',

    layout: 'border',

    items: [{
	itemId: 'grid',
	xtype: 'ticketgrid',
	region: 'center'
    }, {
	itemId: 'preview',
	xtype: 'ticketTabPanel',
	region: 'south'
    }],
    
    initComponent: function(){
        this.callParent();
    },

    afterLayout: function() {
        this.callParent();
        // IE6 likes to make the content disappear, hack around it...
        if (Ext.isIE6) { this.el.repaint(); }
    },
    
    loadSla: function(rec) {
        this.tab.setText(rec.get('project_name'));
        this.child('#grid').loadSla(rec.getId());
    },
    
    filterTickets: function(filterValues) {
        this.tab.setText('Filtered Tickets');
        this.child('#grid').filterTickets(filterValues);
    },
    
    onSelect: function(rec) {
        this.child('#preview').update({
            title: rec.get('project_name')
        });
        this.child('#preview').loadTicket(rec);
    },
    
    togglePreview: function(show){
        var preview = this.child('#preview');
        if (show) {
            preview.show();
        } else {
            preview.hide();
        }
    },

    toggleGrid: function(show){
        var grid = this.child('#grid');
        if (show) {
            grid.show();
        } else {
            grid.hide();
        }
    }
});
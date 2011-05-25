/**
 * intranet-sencha-ticket-tracker/www/PreviewPlugin.js
 * GUI component to show the preview of a single ticket
 * as part of a TicketGrid.
 *
 * @author somebody@sencha.com
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

/**
 * Shows the ticket_description in the ticket grid
 * if the "Summary" button is selected.
 */
Ext.define('TicketBrowser.PreviewPlugin', {
    extend: 'Ext.AbstractPlugin',
    alias: 'plugin.preview',
    requires: ['Ext.grid.feature.RowBody', 'Ext.grid.feature.RowWrap'],
    
    // private, css class to use to hide the body
    hideBodyCls: 'x-grid-row-body-hidden',
    
    /**
     * @cfg {String} bodyField
     * Field to display in the preview. Must me a field within the Model definition
     * that the store is using.
     */
    bodyField: '',
    
    /**
     * @cfg {Boolean} previewExpanded
     */
    previewExpanded: true,
    
    constructor: function(config) {
        this.callParent(arguments);
        var bodyField   = this.bodyField,
            hideBodyCls = this.hideBodyCls,
            section     = this.getCmp();
        
        section.previewExpanded = this.previewExpanded;
        section.features = [{
            ftype: 'rowbody',
            getAdditionalData: function(data, idx, record, orig, view) {
                var o = Ext.grid.feature.RowBody.prototype.getAdditionalData.apply(this, arguments);
                Ext.apply(o, {
                    rowBody: data[bodyField],
                    rowBodyCls: section.previewExpanded ? '' : hideBodyCls
                });
                return o;
            }
        },{
            ftype: 'rowwrap'
        }];
    },
    
    /**
     * Toggle between the preview being expanded/hidden
     * @param {Boolean} expanded Pass true to expand the record and false to not show the preview.
     */
    toggleExpanded: function(expanded) {
        var view = this.getCmp();
        this.previewExpanded = view.previewExpanded = expanded;
        view.refresh();
    }
});
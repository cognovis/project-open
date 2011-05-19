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
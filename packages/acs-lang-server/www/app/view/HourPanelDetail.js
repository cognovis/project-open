/*
 * HourPanelDetail.js
 * (c) 2013 ]project-open[
 * Please see www.hour-open.org/en/project_open_license for details
 *
 */
Ext.define('PO.view.HourPanelDetail', {
    extend: 'Ext.form.Panel',
    xtype: 'hourPanelDetail',
    config: {
        title: 'Hour Detail',
        layout: 'vbox',
        items: [
	    {
		xtype: 'fieldset',
		title: 'Information',
		items: [
		    {
			xtype: 'textfield',
			name: 'hour_name',
			label: 'Hour'
		    }, {
			xtype: 'hiddenfield',
			name: 'id'
		    }, {
			xtype: 'hiddenfield',
			name: 'object_id',
			label: 'Object ID',
			value: 0		// Magic value: 0 is the ID of the "guest" object
		    }
		]
            }
        ]
    }
});


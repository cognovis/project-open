/*
 * For documentation please see:
 * http://www.sencha.com/blog/dive-into-dataview-with-sencha-touch-2-beta-2/
 * For an example please see:
 * https://github.com/senchalabs/component-dataview-example/blob/master/app/view/KittensListItem.js
 */

Ext.define('PO.view.ProjectTimesheetDataViewItem', {
    extend: 'Ext.dataview.component.DataItem',
    xtype : 'projectTimesheetDataViewItem',
    requires: [
	'Ext.Button'
    ],

    config: {
        logButton: {
	    text: 'Log',
	    handler: function() {
		console.log('Log-handler');
	    }
	},

        nameButton: {
	    ui: 'plain',
	    style: 'background-color:white;',
	    iconCls: 'nameButton',
	    handler: function() {
		console.log('Project-handler');
	    }
        },

        dataMap: {
            getLogButton: { },
            getNameButton: { setText: 'project_name_indented' }
        },

        layout: {
            type: 'hbox',
            align: 'center'
        }
    },

    applyLogButton: function(config) {
	return Ext.factory(config, Ext.Button, this.getLogButton());
    },

    applyNameButton: function(config) {
        return Ext.factory(config, Ext.Button, this.getNameButton());
    },
/*
    applyNameButton: function(config) {
        return Ext.factory(config, Ext.Component, this.getNameButton());
    },
*/

    // Stupid update functions.
    updateLogButton: function(newLogButton, oldLogButton) {
        if (oldLogButton) { this.remove(oldLogButton); }
        if (newLogButton) { this.add(newLogButton); }
    },
    updateNameButton: function(newNameButton, oldNameButton) {
        if (newNameButton) { this.add(newNameButton); }
        if (oldNameButton) { this.remove(oldNameButton); }
    }

});






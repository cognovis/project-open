
Ext.define('PO.view.ProjectTimesheetDataViewItem', {
    extend: 'Ext.dataview.component.DataItem',
    xtype : 'projectTimesheetDataViewItem',
    requires: [
	'Ext.Button'
    ],

    config: {
        nameButton: true,
        dataMap: {
            getNameButton: {
                setText: 'project_name'
            }
        }
    },

    applyNameButton: function(config) {
        return Ext.factory(config, Ext.Button, this.getNameButton());
    },

    updateNameButton: function(newNameButton, oldNameButton) {
        if (oldNameButton) {
            this.remove(oldNameButton);
        }

        if (newNameButton) {
            this.add(newNameButton);
        }
    }
});






Ext.define('PO.store.FilteredStore', {
    extend: 'Ext.data.Store',
    requires: ['Ext.data.Model'],

    ///////////////////////////////////////////////////////////////////////////
    // Configuration

    config: {
        model: 'Ext.data.Model',
        sourceStore: undefined,
        filter: undefined
    },

    ///////////////////////////////////////////////////////////////////////////
    // Fields
    sourceStore: undefined,

    ///////////////////////////////////////////////////////////////////////////
    // Configuration methods

    updateSourceStore: function (newValue, oldValue) {
        // See if we've received a valid source store
        if (!newValue)
            return;

        // Resolve the source store
        this.sourceStore = Ext.data.StoreManager.lookup(newValue);
        if (!this.sourceStore || !Ext.isObject(this.sourceStore) || !this.sourceStore.isStore)
            Ext.Error.raise({ msg: 'An invalid source store (' + newValue + ') was provided for ' + this.self.getName() });

        // Listen to source store events and copy model
        this.setModel(this.sourceStore.getModel());
        this.sourceStore.on({
            addrecords: 'sourceStoreAdded',
            removerecords: 'sourceStoreRemoved',
            refresh: 'sourceStoreChanged',
            scope: this
        });

        // Load the current data
        this.sourceStoreChanged();
    },
    updateFilter: function () {
        // Load the current data
        this.sourceStoreChanged();
    },

    ///////////////////////////////////////////////////////////////////////////
    // Store overrides

    fireEvent: function (eventName, me, record) {
        // Intercept update events, remove rather than update if record is no longer valid
        var filter = this.getFilter();
        if (filter && eventName === 'updaterecord' && !filter(record))
            this.remove(record);
        else
            this.callParent(arguments);
    },

    ///////////////////////////////////////////////////////////////////////////
    // Event handlers

    sourceStoreAdded: function (sourceStore, records) {
        var filter = this.getFilter();
        if (!filter)
            return;

        // Determine which records belong in this store
        var i = 0, len = records.length, record, newRecords = [];
        for (; i < len; i++) {
            record = records[i];

            // Don't add records already in the store
            if (this.indexOf(record) != -1)
                continue;

            if (filter(record))
                newRecords.push(record);
        }

        // Add the new records
        if (newRecords.length)
            this.add(newRecords);
    },
    sourceStoreRemoved: function (sourceStore, records) {
        this.remove(records);
    },
    sourceStoreChanged: function () {
        // Clear the store
        this.removeAll();

        var records = [],
        i, all, record,
        filter = this.getFilter();

        // No filter? No data
        if (!filter)
            return;

        // Collect and filter the current records
        all = this.sourceStore.getAll();
        for (i = 0; i < all.length; i++) {
            record = all[i];
            if (filter(record))
                records.push(record);
        }

        // Add the records to the store
        this.add(records);
    }
});



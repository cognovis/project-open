Ext.define('PO.store.Notes', {
        extend: 'Ext.data.Store',
	requires: 'Ext.DateExtras',
	config: {
	    model: 'PO.model.Note',
	    sorters: [
			  {
			      property: 'note_type_id',
				  direction: 'ASC'
				  },
			  {
			      property: 'object_name',
				  direction: 'ASC'
			  }
        	]
	}
});


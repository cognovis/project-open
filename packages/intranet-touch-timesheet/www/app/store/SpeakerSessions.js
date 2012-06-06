Ext.define('ProjectOpen.store.SpeakerSessions', {
	extend: 'Ext.data.Store',

    config: {
        model: 'ProjectOpen.model.Session',

        sorters: [
        	{
            	property: 'time',
            	direction: 'ASC'
            }
        ]
    }
})

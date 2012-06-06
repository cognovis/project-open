Ext.define('ProjectOpen.store.SpeakerProjects', {
	extend: 'Ext.data.Store',
	config: {
		model: 'ProjectOpen.model.Project',
		sorters: [
			{
				property: 'time',
				direction: 'ASC'
			}
		]
	}
});

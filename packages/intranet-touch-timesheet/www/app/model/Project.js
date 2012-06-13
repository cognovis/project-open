Ext.define('ProjectOpen.model.Project', {
	extend: 'Ext.data.Model',
	config: {
		fields: [
			'id',
			'project_id',
			'parent_id',
			'level',
			'company_id',
			'company_name',
			'project_name',
			'project_nr',
			'project_type_id',
			'project_type',
			'project_status_id',
			'project_status',
			'hours',
			'note',
			'material_id',
			'material_name'
		]
	}
});


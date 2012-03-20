Ext.define('ProjectOpen.view.project.List', {
	extend: 'Ext.List',
	requires: 'Ext.SegmentedButton',
	xtype: 'projects',
	config: {
		items: [
			{
			docked: 'top',
			xtype: 'toolbar',
			ui: 'gray',
			items: [
				{
					xtype: 'datepickerfield',
					value: new Date(),
					picker: { yearFrom: 2010 }
				}
			]
			}
		],
		itemTpl: [
			'<div class="project"><div class="title">{project_name}</div><div class="room">{company_id}</div></div>'
		]
	}
});

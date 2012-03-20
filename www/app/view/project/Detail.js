Ext.define('ProjectOpen.view.project.Detail', {
	extend: 'Ext.Container',
	xtype: 'project',
	config: {
		layout: 'vbox',
		scrollable: true,
		title: '',
		items: [
			{
				xtype: 'projectInfo'
			},
			{
				xtype: 'speakers',
				store: 'ProjectSpeakers',
				scrollable: false,
				items: [
					{
						xtype: 'listitemheader',
						cls: 'dark',
						html: 'Speakers'
					}
				]
			}
		]
	}
});

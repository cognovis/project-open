Ext.define('ProjectOpen.view.speaker.Detail', {
	extend: 'Ext.Container',
	xtype: 'speaker',
	config: {
		layout: 'vbox',
		scrollable: 'vertical',
		items: [
			{
				xtype: 'speakerInfo'
			},
			{
				xtype: 'list',
				store: 'SpeakerProjects',

				scrollable: false,

				items: [
					{
						xtype: 'listitemheader',
						cls: 'dark',
						html: 'Projects'
					}
				],

				itemTpl: [
					'{title}'
				]
			}
		]
	}
});

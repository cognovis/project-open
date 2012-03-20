Ext.define('ProjectOpen.view.Main', {
	extend: 'Ext.tab.Panel',
	xtype: 'main',
	config: {
		tabBarPosition: 'bottom',
		tabBar: {
			ui: 'gray'
		},
		items: [
			{ xclass: 'ProjectOpen.view.project.Card' },
			{ xclass: 'ProjectOpen.view.speaker.Card' },
			{ xclass: 'ProjectOpen.view.Tweets' },
			{ xclass: 'ProjectOpen.view.about.Card' }
		]
	}
});

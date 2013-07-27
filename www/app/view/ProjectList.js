Ext.define('PO.view.ProjectList', {
	extend: 'Ext.List',
	xtype: 'projectList',
	requires: ['PO.store.ProjectTimesheetStore'],

	config: {
		title: 'Project List',
		iconCls: 'star',
//		itemTpl: '<div class="contact2">{project_name_indented}</div>',
		itemTpl: '<div style="font-size: medium">{project_name_indented}</div>',
		disclosure: true,
		grouped: true,
		indexBar: true,
		store: 'ProjectTimesheetStore',
		onItemDisclosure: true
	}
});


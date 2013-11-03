Ext.define('PO.view.ProjectTaskList', {
	extend: 'Ext.List',
	xtype: 'projectTaskList',
	requires: ['PO.store.ProjectTaskStore'],

	config: {
	    title: 'Task Projects',
	    store: 'ProjectTaskStore',
	    iconCls: 'star',	    
	    itemTpl: '<div class="myContent">Project Name: <b>{project_name}</b></div>',
	    disclosure: true,
	    grouped: false,
	    indexBar: true
//	    onItemDisclosure: true
	}
});


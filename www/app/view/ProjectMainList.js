Ext.define('PO.view.ProjectMainList', {
	extend: 'Ext.List',
	xtype: 'projectMainList',
	requires: ['PO.store.ProjectMainStore'],

	config: {
	    title: 'Main Projects',
	    store: 'ProjectMainStore',
	    iconCls: 'star',

//	    itemTpl: '<div class="contact2">{project_name_indented}</div>',
//	    itemTpl: '<div style="font-size: medium">{project_name_indented}</div>',
	    
	    itemTpl: '<div class="myButton">' +
		'<input type="button" name="{project_id}" value="Hours" ' +
		'style="padding:3px;">' +
		'</div><div class="myContent">'+
		'<div>Project Name: <b>{project_name}</b></div>' +
		'<div>Description: <b>{description}</b> {project_status_id} {project_type_id}</b></div>' +
		'</div>',

	    disclosure: true,
	    grouped: false,
	    indexBar: true
	    onItemDisclosure: true
	}
});


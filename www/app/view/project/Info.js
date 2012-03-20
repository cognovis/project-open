Ext.define('ProjectOpen.view.project.Info', {
	extend: 'Ext.Component',
	xtype: 'projectInfo',
	config: {
		cls: 'projectInfo',
		tpl: Ext.create('Ext.XTemplate',
			'<h3>{project_name} <small>{company_id}</small></h3>',
			'<h4>{project_nr} at {start_date}</h4>',
			'<p>{description}</p>',
			{
				formatTime: function(time) {
					return ''; //Ext.Date.format(time, 'g:ia, m/d/Y')
				}
			}
		)
	}
});

Ext.define('ProjectOpen.store.Projects', {
	extend: 'Ext.data.Store',
	requires: 'Ext.DateExtras',
	config: {
		model: 'ProjectOpen.model.Project',
		grouper: {
			sortProperty: 'time',
			groupFn: function(record) {
				return Ext.Date.format(record.get('time'), 'g:ia');
			}
		},
		sorters: [
			{
				property: 'time',
				direction: 'ASC'
			},
			{
				property: 'title',
				direction: 'ASC'
			}
		],
		proxy: {
			type:				'rest',
			url:				'/intranet-reporting/view',
			appendId:			true,
			extraParams: {
				format:			'json',
				report_code:		'rest_my_timesheet_projects_hours',
				date:			'2010-06-09'
				// user_id:		624		// defaults to the current user
			},
			reader: {
				type:			'json',
				rootProperty:		'data',
				totalProperty:		'total',
				messageProperty:	'message'
			}
		},
		autLoad:	true
	}
});

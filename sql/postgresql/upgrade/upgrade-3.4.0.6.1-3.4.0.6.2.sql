-- upgrade-3.4.0.6.1-3.4.0.6.2.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.6.1-3.4.0.6.2.sql','');


update im_component_plugins set
	title_tcl = null
where
	plugin_name in (
		'Home Big Brother Component',
		'Project Configuration Items',
		'User Configuration Items',
		'Conf Item Members',
		'Task Members',
		'User Notifications',
		'Expense Bundle Confirmation Workflow',
		'Discussions',
		'Project Survey Component',
		'Company Survey Component',
		'User Survey Component',
		'Absence Journal',
		'Absence Workflow',
		'Expense Bundle Confirmation Journal',
		'Timesheet Confirmation Workflow',
		'Timesheet Confirmation Journal',
		'Company Translation Prices',
		'Project Translation Error Component',
		'Company Trados Matrix',
		'Project Freelance Tasks',
		'Project Translation Task Status',
		'Project Translation Details',
		'Project Workflow Journal',
		'Home Workflow Component',
		'Project Workflow Graph',
		'Home Workflow Inbox'
	)
;



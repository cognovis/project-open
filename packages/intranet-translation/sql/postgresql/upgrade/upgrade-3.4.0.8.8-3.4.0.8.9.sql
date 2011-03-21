--  upgrade-3.4.0.8.8-3.4.0.8.9.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.8.8-3.4.0.8.9.sql','');

update im_biz_object_urls
set url = '/intranet-translation/trans-tasks/new?form_mode=display&task_id='
where	object_type = 'im_trans_task' and 
	url_type = 'view';

update im_biz_object_urls
set url = '/intranet-translation/trans-tasks/new?form_mode=edit&task_id='
where	object_type = 'im_trans_task' and 
	url_type = 'edit';


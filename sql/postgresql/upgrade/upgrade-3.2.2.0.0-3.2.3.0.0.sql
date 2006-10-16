--------------------------------------------------------
-- 
--------------------------------------------------------

-- Fix Biz-Obj URLs

delete from im_biz_object_urls
where object_type = 'im_timesheet_task';

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_task','view','/intranet-timesheet2-tasks/new?task_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_task','edit','/intranet-timesheet2-tasks/new?form_mode=edit&task_id=');


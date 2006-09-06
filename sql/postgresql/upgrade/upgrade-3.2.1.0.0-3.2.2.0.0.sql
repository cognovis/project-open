
-- Add URLs for object type "Timesheet Task"

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_task','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_task','edit','/intranet/projects/new?project_id=');


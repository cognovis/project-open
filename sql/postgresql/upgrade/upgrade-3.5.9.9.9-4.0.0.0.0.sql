-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');


insert into im_biz_object_urls (object_type, url_type, url) values (
'im_indicator','view','/intranet-reporting-indicators/view?indicator_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_indicator','edit','/intranet-reporting-indicators/new?indicator_id=');


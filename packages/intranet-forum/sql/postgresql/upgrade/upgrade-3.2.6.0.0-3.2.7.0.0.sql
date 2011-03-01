-- upgrade-3.2.3.0.0-3.2.4.0.0.sql

SELECT acs_log__debug('/packages/intranet-forum/sql/postgresql/upgrade/upgrade-3.2.6.0.0-3.2.7.0.0.sql','');


-----------------------------------------------------------
-- Business Object View URLs

delete from im_biz_object_urls
where object_type = 'im_forum_topic';


insert into im_biz_object_urls (object_type, url_type, url) values (
'im_forum_topic','view','/intranet-forum/view?topic_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_forum_topic','edit','/intranet-forum/new?topic_id=');



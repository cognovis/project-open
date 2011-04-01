-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');

delete from im_biz_object_urls where object_type = 'im_indicator' and url_type = 'view';
delete from im_biz_object_urls where object_type = 'im_indicator' and url_type = 'edit';

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_indicator','view','/intranet-reporting-indicators/view?indicator_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_indicator','edit','/intranet-reporting-indicators/new?indicator_id=');







-- Indicator component for the Finance Home Page
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Financial Indicators Timeline',	-- plugin_name - shown in menu
	'intranet-cost',			-- package_name
	'right',				-- location
	'/intranet-cost/index',			-- page_url
	null,					-- view_name
	30,					-- sort_order
	'im_indicator_timeline_component -indicator_section_id [im_indicator_section_finance]',
	'lang::message::lookup "" intranet-cost.Financial_Indicators_Timeline "Financial Indicators Timeline"'
);





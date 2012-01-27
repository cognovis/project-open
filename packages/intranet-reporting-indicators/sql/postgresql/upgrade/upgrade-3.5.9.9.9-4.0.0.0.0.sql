-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from im_biz_object_urls where
              object_type = ''im_indicator''
              and url_type = ''view''
              and url = ''/intranet-reporting-indicators/view?indicator_id='';

        IF v_count > 0 THEN return 1; END IF;

        insert into im_biz_object_urls (object_type, url_type, url) values (
        ''im_indicator'',''view'',''/intranet-reporting-indicators/view?indicator_id='');

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from im_biz_object_urls where
              object_type = ''im_indicator''
              and url_type = ''edit''
              and url = ''/intranet-reporting-indicators/new?indicator_id='';

        IF v_count > 0 THEN return 1; END IF;

        insert into im_biz_object_urls (object_type, url_type, url) values (
        ''im_indicator'',''edit'',''/intranet-reporting-indicators/new?indicator_id='');

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


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





-- upgrade-3.4.0.8.6-3.4.0.8.7.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.8.6-3.4.0.8.7.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''acs_object_types'' and lower(column_name) = ''icon_path'';
        IF v_count > 0 THEN return 1; END IF;

	alter table acs_object_types add column icon_path character varying(100);
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

update acs_object_types set icon_path = '/intranet/images/navbar_default/cog.png' where object_type = 'im_conf_item';
update acs_object_types set icon_path = '/intranet/images/navbar_default/building.png' where object_type = 'im_company';
update acs_object_types set icon_path = '/intranet/images/navbar_default/calculator.png' where object_type = 'im_cost_center';
update acs_object_types set icon_path = '/intranet/images/navbar_default/comments.png' where object_type = 'im_forum_topic';
update acs_object_types set icon_path = '/intranet/images/navbar_default/page_gear.png' where object_type = 'im_ticket';
update acs_object_types set icon_path = '/intranet/images/navbar_default/time_go.png' where object_type = 'im_timesheet_task';
update acs_object_types set icon_path = '/intranet/images/navbar_default/building.png' where object_type = 'company';
update acs_object_types set icon_path = '/intranet/images/navbar_default/money.png' where object_type = 'im_expense';
update acs_object_types set icon_path = '/intranet/images/navbar_default/money_add.png' where object_type = 'im_expense_bundle';
update acs_object_types set icon_path = '/intranet/images/navbar_default/folder_page.png' where object_type = 'im_fs_file';
update acs_object_types set icon_path = '/intranet/images/navbar_default/page_red.png' where object_type = 'im_invoice';
update acs_object_types set icon_path = '/intranet/images/navbar_default/palette.png' where object_type = 'im_material';
update acs_object_types set icon_path = '/intranet/images/navbar_default/cup.png' where object_type = 'im_user_absence';
update acs_object_types set icon_path = '/intranet/images/navbar_default/status_offline.png' where object_type = 'user';
update acs_object_types set icon_path = '/intranet/images/navbar_default/status_online.png' where object_type = 'person';
update acs_object_types set icon_path = '/intranet/images/navbar_default/page_green.png' where object_type = 'im_trans_invoice';
update acs_object_types set icon_path = '/intranet/images/navbar_default/tag_green.png' where object_type = 'im_trans_task';
update acs_object_types set icon_path = '/intranet/images/navbar_default/page_orange.png' where object_type = 'im_timesheet_invoice';
update acs_object_types set icon_path = '/intranet/images/navbar_default/star.png' where object_type = 'party';
update acs_object_types set icon_path = '/intranet/images/navbar_default/timeline_marker.png' where object_type = 'im_ticket_queue';
update acs_object_types set icon_path = '/intranet/images/navbar_default/sitemap.png' where object_type = 'im_project';
update acs_object_types set icon_path = '/intranet/images/navbar_default/asterisk_yellow.png' where object_type = 'im_profile';
update acs_object_types set icon_path = '/intranet/images/navbar_default/attach.png' where object_type = 'im_office';







-- upgrade-3.4.0.2.0-3.4.0.3.0.sql

-- Add a localized short status to absences
update lang_messages set message = 'Absent (%absence_status_3letter_l10n%):' where package_key = 'intranet-timesheet2' and message_key = 'Absent_1' and locale like 'en_%';



-- add material_id to im_hours

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
	where table_name = ''IM_HOURS'' and column_name = ''MATERIAL_ID'';
        if v_count > 0 then return 0; end if;

	alter table im_hours 
	add material_id integer
	constraint im_hours_material_fk
	references im_materials;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Who should be able to modify other users hours?
select acs_privilege__create_privilege('log_hours_for_others','Log hours for others','Log hours for others');
select acs_privilege__add_child('admin', 'log_hours_for_others');

select im_priv_create('log_hours_for_others', 'Accounting');
select im_priv_create('log_hours_for_others', 'P/O Admins');
select im_priv_create('log_hours_for_others', 'Senior Managers');

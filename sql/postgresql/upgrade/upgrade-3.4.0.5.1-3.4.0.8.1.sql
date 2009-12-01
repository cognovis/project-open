--  upgrade-3.4.0.5.1-3.4.0.8.1.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.5.1-3.4.0.8.1.sql','');

-- Create a  material for translation tasks

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select  count(*) into v_count from im_materials where material_name = ''Translation Task'';
        if v_count = 0 then

	perform im_material__new (
        	 acs_object_id_seq.nextval::integer, ''im_material'', now(), null, ''0.0.0.0'', null,
	        ''Translation Task'', ''tr_task'', 9000, 9100, 320, ''Translation Task''
	);
        end if;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

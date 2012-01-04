-- upgrade-4.0.2.0.8-4.0.2.0.9.sql
SELECT acs_log__debug('/packages/intranet-sla-management/sql/postgresql/upgrade/upgrade-4.0.2.0.8-4.0.2.0.9.sql','');

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS INTEGER AS '
 
declare
        v_count                 integer;
	v_type_category_type	varchar;
begin

	select type_category_type into v_type_category_type from acs_object_types where object_type = ''im_sla_parameter'';

        IF      v_type_category_type IS NULL or length(v_type_category_type) = 0
        THEN
		update acs_object_types set type_category_type = ''Intranet SLA Parameter Type'' where object_type = ''im_sla_parameter'';
        END IF;
 
        return 1;
 
end;' LANGUAGE 'plpgsql';
 
SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- fix wrong value for status_type_table
update acs_object_types set status_type_table = 'im_sla_parameters' where object_type = 'im_sla_parameter';


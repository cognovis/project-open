-- upgrade-3.2.7.0.0-3.2.8.0.0.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.2.7.0.0-3.2.8.0.0.sql','');


-- Remove the "im_employees e" extra select from employees view
update im_view_columns set
	extra_from = ''
where	extra_from = 'im_employees e'
	and column_id = 5500;


create or replace function inline_0 ()
returns integer as '
DECLARE
    row			RECORD;
BEGIN
    FOR row IN
	select	cost_id
	from	im_costs c
	where	c.cost_type_id = 3714
		and cause_object_id in (
			select  cause_object_id
			from	im_repeating_costs r,
				im_costs c
			where
				r.rep_cost_id = c.cost_id
				and c.cost_type_id = 3714
			group by
				cause_object_id
			having
				count(*) > 1
		)
    LOOP

	RAISE NOTICE ''delete rep_costs: %'', row.cost_id;
	delete from im_repeating_costs where rep_cost_id = row.cost_id;
	PERFORM im_cost__delete(row.cost_id);

    END LOOP;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0();


update im_component_plugins
set component_tcl = 'im_employee_info_component $user_id_from_search $return_url [im_opt_val employee_view_name]'
where plugin_name = 'User Employee Component';

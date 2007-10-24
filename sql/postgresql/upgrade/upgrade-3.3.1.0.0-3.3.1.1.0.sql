-- upgrade-3.3.1.0.0-3.3.1.1.0.sql


-- Set permissions on all Plugin Components for Employees, Freelancers and Customers.
create or replace function inline_0 ()
returns varchar as '
DECLARE
	v_count		integer;
	v_plugin_id	integer;
        row		RECORD;
BEGIN
	-- Check if permissions were already configured
	-- Stop if there is just a single configured plugin.
	select	count(*) into v_count
	from	acs_permissions p,
		im_component_plugins pl
	where	p.object_id = pl.plugin_id;
	IF v_count > 0 THEN return 0; END IF;

	-- Add read permissions to all plugins
        FOR row IN
		select	plugin_id
		from	im_component_plugins pl
        LOOP
		PERFORM im_grant_permission(row.plugin_id, 463, ''read'');
		PERFORM im_grant_permission(row.plugin_id, 465, ''read'');
		PERFORM im_grant_permission(row.plugin_id, 461, ''read'');
        END LOOP;

        return 0;
END;' language 'plpgsql';
select inline_0();
drop function inline_0();



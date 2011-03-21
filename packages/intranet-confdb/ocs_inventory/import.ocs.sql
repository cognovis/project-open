---------------------------------------------------------------------------------
-- import.ocs.sql
--
-- Convert data from the OCS Inventory database to the ]po[ confdb format
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- Convert "Hardware" into Conf Item

create or replace function inline_0 ()
returns integer as '
DECLARE
	row			RECORD;
	v_count			integer;
	v_oid			integer;
	v_computer_type_id	integer;
	v_active_status_id	integer;
BEGIN

    v_active_status_id = 11700;
    v_computer_type_id = 11850;

    for row in
	select	*
	from	ocs_hardware h
    loop

	select conf_item_id into v_oid
	from im_conf_items
	where conf_item_nr = row.deviceid;

	IF v_oid is null THEN
	    v_oid := im_conf_item__new (
		null,			-- p_conf_item_id
		''im_conf_item'',	-- p_object_type
		now(),			-- p_creation_date
		0,			-- p_creation_user
		row.ipaddr,		-- p_creation_ip
		null,			-- p_context_id
	
		row.name,		-- p_conf_item_name
		row.deviceid,		-- p_conf_item_nr
		null,			-- p_conf_item_parent_id
		v_computer_type_id,	-- p_conf_item_type_id
		v_active_status_id	-- p_conf_item_status_id
	    );
	END IF;

	update im_conf_items set
		conf_item_code = null,
		conf_item_cost_center_id = null,
		conf_item_owner_id = null,
		note = null,

		description = row.description,
		ip_address = row.ipaddr,

		ocs_id = row.id,
		ocs_deviceid = row.deviceid,
		ocs_username = row.userdomain,
		ocs_last_update = row.lastdate,

		os_name = row.osname,
		os_version = row.osversion,
		os_comments = row.oscomments,

		win_workgroup = row.workgroup,
		win_userdomain = row.userdomain,
		win_company = row.wincompany,
		win_owner = row.winowner,
		win_product_id = row.winprodid,
		win_product_key = row.winprodkey,

		processor_text = row.processort,
		processor_speed = row.processors,
		processor_num = row.processorn,

		sys_memory = row.memory,
		sys_swap = row.swap
	where conf_item_id = v_oid;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


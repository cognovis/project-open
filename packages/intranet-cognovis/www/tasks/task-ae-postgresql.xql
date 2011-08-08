<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="task_insert">
    <querytext>
	SELECT im_timesheet_task__new (
		:task_id,		-- p_task_id
		'im_timesheet_task',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
	        :project_nr,   		-- project_nr,
		:project_name,		-- project_name,
		:parent_id,		-- parent_id,
		:material_id,		-- material_id,
		null,			-- cost_center_id,
		:uom_id,		-- uom_id,
		:task_type_id,
		:task_status_id,
		null			-- note
	);

    </querytext>
</fullquery>


<fullquery name="task_delete">
    <querytext>
    BEGIN
	PERFORM im_task__delete (:task_id);
	return 0;
    END;
    </querytext>
</fullquery>

</queryset>

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
		:task_nr,
		:task_name,
		:project_id,
		:material_id,
		null,
		:uom_id,
		:task_type_id,
		:task_status_id,
		null
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


<fullquery name="project_update">
    <querytext>
	update im_projects set
		project_name	= :task_name,
                parent_id       = :project_id,
		project_nr	= :task_nr
	where
		project_id = :task_id;
    </querytext>
</fullquery>


</queryset>

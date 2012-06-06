<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="cost_center_insert">
	<querytext>

    BEGIN
	PERFORM im_cost_center__new (
		null,			-- cost_center_id
		'im_cost_center',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id

		:cost_center_name,
		:cost_center_label,
		:cost_center_code,
		:cost_center_type_id,
		:cost_center_status_id,
		:parent_id,
		:manager_id,
		:department_p,
		:description,
		:note
	);
	return 0;
    END;

	</querytext>
</fullquery>

</queryset>

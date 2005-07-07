<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="report_insert">
	<querytext>

    BEGIN
	PERFORM im_report__new (
		:report_id,		-- p_report_id
		'im_report',		-- object_type
		now(),			-- creation_date
		:user_id,		-- creation_user
		:user_ip,		-- creation_ip
		null,			-- context_id
		:report_name,     	-- report_name
		:view_id,         	-- view_id
		:report_status_id, 	-- report_status_id
		:report_type_id,   	-- report_type_id
	        :description  	 	-- description
	);
	return 0;
    END;

	</querytext>
</fullquery>

</queryset>

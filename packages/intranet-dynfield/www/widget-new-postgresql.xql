<?xml version="1.0"?>

<queryset>
   <rdbms>
	<type>postgresql</type>
	<version>7.2</version>
  </rdbms>

<fullquery name="create_widget">
  <querytext>

	SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',   -- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		:widget_name,		-- widget_name
		:pretty_name,		-- pretty_name
		:pretty_plural,		-- pretty_plural
		:storage_type_id,	-- storage_type_id
		:acs_datatype,		-- acs_datatype
		:widget,		-- widget
		:sql_datatype,		-- sql_datatype
		:parameters		-- parameters
	);

  </querytext>
</fullquery>

</queryset>

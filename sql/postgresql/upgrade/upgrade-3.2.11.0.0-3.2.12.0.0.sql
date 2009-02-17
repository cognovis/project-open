-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

SELECT acs_log__debug('/packages/intranet-freelance-rfqs/sql/postgresql/upgrade/upgrade-3.2.11.0.0-3.2.12.0.0.sql','');


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'general_rfq_accept',	-- widget_name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty_name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'radio',		-- widget
	'integer',		-- sql_datatype
	'{options { {"#intranet-freelance-rfqs.Yes_I_can_do#" 1} {"#intranet-freelance-rfqs.No_I_decline#" 0} }}'
);



alter table im_freelance_rfqs add general_outcome varchar;

select im_dynfield_attribute__new (
	null,			-- widget_id
	'im_dynfield_attribute', -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id

	'im_freelance_rfq',	-- attribute_object_type
	'general_outcome',	-- attribute name
	1,
	1,
	null,
	'string',
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty plural
	'general_rfq_accept',
	't',
	't'
);


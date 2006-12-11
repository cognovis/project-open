-- upgrade-3.2.5.0.0-3.2.6.0.0.sql


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id

	'currencies',		-- widget_name
	'#intranet-core.Currency#',	-- pretty_name
	'#intranet-core.Currencies#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'generic_sql',		-- widget
	'char(3)',		-- sql_datatype
	'{custom {sql {select iso, iso from currency_codes where supported_p = 't' }}}'
);

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
	'{custom {sql {select iso, iso from currency_codes where supported_p = ''t'' }}}'
);


create table im_dynfield_type_attribute_map (
        attribute_id            integer
                                constraint im_dynfield_type_attr_map_attr_fk
                                references acs_objects,
        object_type_id          integer
                                constraint im_dynfield_type_attr_map_otype_nn
                                not null
                                constraint im_dynfield_type_attr_map_otype_fk
                                references im_categories,
        display_mode            varchar(10)
                                constraint im_dynfield_type_attr_map_dmode_nn
                                not null
                                constraint im_dynfield_type_attr_map_dmode_ck
                                check (display_mode in ('edit', 'display', 'none')),
        unique (attribute_id, object_type_id)
);


comment on table im_dynfield_type_attribute_map is '
This map allows us to specify whether a DynField attribute should
appear in a Edit/NewPage of an object, and whether it should appear
in edit or display mode.
The table maps the objects type_id (such as project_type_id, company_type_id
etc.) to the "display_mode" for the DynField attribute.
The display mode is "edit" if there is no entry in this map table.
';


